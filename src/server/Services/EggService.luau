--!strict
-- Eggs: buy with cash -> incubate (up to INCUBATORS at once) -> hatch into a random brainrot with a mutation roll.
-- Buying closes at night; incubators keep running and can still hatch (approved Q1).
-- Until the Eggs screen is approved, each base's egg stand offers in-world ProximityPrompts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Incubator = require(ReplicatedStorage.Shared.Logic.Incubator)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Roll = require(ReplicatedStorage.Shared.Logic.Roll)

local Entitlements = require(script.Parent.Parent.Entitlements)
local Parts = require(script.Parent.Parent.World.Parts)
local BaseService = require(script.Parent.BaseService)
local BrainrotService = require(script.Parent.BrainrotService)
local CycleService = require(script.Parent.CycleService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local EggService = {}

local random = Random.new()
local function rng(): number
	return random:NextNumber()
end

type StandUi = { prompts: { [string]: ProximityPrompt }, hatch: ProximityPrompt, label: TextLabel }
local stands: { [Player]: StandUi } = {}

function EggService.buy(player: Player, eggId: string): boolean
	local data = DataService.get(player)
	local def = Config.Eggs.byId[eggId]
	if not data or not def or not def.cashPrice then
		return false
	end
	if not CycleService.shopOpen() then
		Remotes.Notify:fireClient(
			player,
			"warn",
			"The egg shop is closed for the night. Your incubators keep going!"
		)
		return false
	end
	if #data.eggs >= Config.Eggs.INCUBATORS then
		Remotes.Notify:fireClient(player, "warn", "All incubators are busy. Hatch an egg first!")
		return false
	end
	if not EconomyService.spend(player, def.cashPrice) then
		Remotes.Notify:fireClient(player, "warn", "Not enough cash yet.")
		return false
	end
	table.insert(data.eggs, {
		id = BrainrotService.newId(),
		eggId = def.id,
		startedAt = os.time(),
		hatchSeconds = def.hatchSeconds,
	})
	DataService.sendSnapshot(player)
	Remotes.Notify:fireClient(
		player,
		"good",
		`{def.displayName} is incubating. Ready in {Format.duration(def.hatchSeconds)}.`
	)
	return true
end

function EggService.hatch(player: Player, eggInstanceId: string): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	local egg, index = Incubator.find(data.eggs, eggInstanceId)
	if not egg or not index or not Incubator.isReady(egg, os.time()) then
		return false
	end
	local def = Config.Eggs.byId[egg.eggId]
	local rarity = Roll.rarity(def.rarityWeights :: any, rng, Entitlements.luck(player))
	local speciesId = rarity and Roll.species(rarity, rng)
	if not speciesId then
		return false
	end
	local brainrot =
		Roll.newBrainrot(BrainrotService.newId(), speciesId, Roll.mutation(rng), player.UserId, os.time())
	local placed = BrainrotService.give(player, brainrot)
	if not placed then
		Remotes.Notify:fireClient(player, "warn", "No room! Free a pedestal or storage slot, then hatch.")
		return false
	end
	table.remove(data.eggs, index)
	DataService.sendSnapshot(player)
	Remotes.HatchResult:fireClient(
		player,
		{ brainrot = BrainrotService.toPublic(data, brainrot), placed = placed :: any }
	)
	local species = Config.Species.byId[speciesId]
	local mutation = if brainrot.mutation ~= "None" then `{brainrot.mutation} ` else ""
	Remotes.Notify:fireClient(
		player,
		"good",
		`Hatched a {mutation}{species.displayName} ({brainrot.rarity})!`
	)
	if brainrot.rarity == "Mythic" or brainrot.rarity == "Secret" then
		Remotes.Notify:fireAll(
			"drop",
			`{player.DisplayName} hatched a {brainrot.rarity} {species.displayName}!`
		)
	end
	return true
end

local function firstReady(player: Player): string?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local now = os.time()
	for _, egg in data.eggs do
		if Incubator.isReady(egg, now) then
			return egg.id
		end
	end
	return nil
end

-- Temporary in-world UI -----------------------------------------------------------------------------------

local function buildStand(player: Player)
	local refs = BaseService.refsFor(player)
	if not refs then
		return
	end
	local stand = refs.eggStand
	stand:ClearAllChildren()
	local prompts: { [string]: ProximityPrompt } = {}
	for i, def in Config.Eggs.list do
		if def.cashPrice then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = `Buy {Format.price(def.cashPrice)}`
			prompt.ObjectText = def.displayName
			prompt.KeyboardKeyCode = if i == 1 then Enum.KeyCode.E else Enum.KeyCode.R
			prompt.HoldDuration = 0.3
			prompt.RequiresLineOfSight = false
			prompt.UIOffset = Vector2.new(0, (i - 1) * 70)
			prompt.Parent = stand
			local eggId = def.id
			prompt.Triggered:Connect(function(who)
				if who == player then
					EggService.buy(player, eggId)
				end
			end)
			prompts[def.id] = prompt
		end
	end
	local hatch = Instance.new("ProximityPrompt")
	hatch.ActionText = "Hatch!"
	hatch.ObjectText = "Ready egg"
	hatch.KeyboardKeyCode = Enum.KeyCode.F
	hatch.RequiresLineOfSight = false
	hatch.UIOffset = Vector2.new(0, -70)
	hatch.Enabled = false
	hatch.Parent = stand
	hatch.Triggered:Connect(function(who)
		local id = if who == player then firstReady(player) else nil
		if id then
			EggService.hatch(player, id)
		end
	end)
	local _, labels = Parts.billboard(stand, 4.5, { "EGGS", "" }, Vector2.new(7, 2.6))
	stands[player] = { prompts = prompts, hatch = hatch, label = labels[2] }
end

local function refreshStand(player: Player)
	local ui = stands[player]
	local data = DataService.get(player)
	if not ui or not data then
		return
	end
	local open = CycleService.shopOpen()
	for _, prompt in ui.prompts do
		prompt.Enabled = open and #data.eggs < Config.Eggs.INCUBATORS
	end
	local now = os.time()
	local parts: { string } = {}
	for _, egg in data.eggs do
		local left = Incubator.timeLeft(egg, now)
		local name = Config.Eggs.byId[egg.eggId].displayName
		table.insert(parts, if left <= 0 then `{name}: READY` else `{name}: {Format.clock(left)}`)
	end
	ui.label.Text = if #parts == 0
		then `0/{Config.Eggs.INCUBATORS} incubating`
		else table.concat(parts, " · ")
	ui.hatch.Enabled = firstReady(player) ~= nil
end

function EggService.init() end

function EggService.start()
	Remotes.BuyEgg:connect(function(player, eggId)
		EggService.buy(player, eggId)
	end)
	Remotes.HatchEgg:connect(function(player, id)
		EggService.hatch(player, id)
	end)
	BaseService.assigned:connect(function(player)
		buildStand(player)
		refreshStand(player)
	end)
	BaseService.released:connect(function(player, refs)
		stands[player] = nil
		refs.eggStand:ClearAllChildren()
	end)
	Players.PlayerRemoving:Connect(function(player)
		stands[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for player in stands do
				refreshStand(player)
			end
		end
	end)
end

return EggService
