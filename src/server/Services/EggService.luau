--!strict
-- Eggs: buy with cash at the hub Egg Shop -> incubate in your nursery (3 incubators + passes, D39) -> hatch into a
-- Baby (random character + variant roll) that lives in the nursery pen and grows by feeding and over time.
-- Needs an unlocked nursery. Buying closes at night; incubators keep running and can still hatch (approved Q1).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Incubator = require(ReplicatedStorage.Shared.Logic.Incubator)
local Nursery = require(ReplicatedStorage.Shared.Logic.Nursery)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Roll = require(ReplicatedStorage.Shared.Logic.Roll)

local Entitlements = require(script.Parent.Parent.Entitlements)
local BrainrotService = require(script.Parent.BrainrotService)
local CycleService = require(script.Parent.CycleService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local NurseryService = require(script.Parent.NurseryService)

local EggService = {}

local random = Random.new()
local function rng(): number
	return random:NextNumber()
end

function EggService.buy(player: Player, eggId: string): boolean
	local data = DataService.get(player)
	local def = Config.Eggs.byId[eggId]
	if not data or not def or not def.cashPrice then
		return false
	end
	if not data.nurseryUnlocked then
		Remotes.Notify:fireClient(player, "warn", "Unlock your nursery first: eggs hatch there.")
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
	if #data.eggs >= NurseryService.incubators(player) then
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
	NurseryService.refresh(player)
	Remotes.Notify:fireClient(
		player,
		"good",
		`{def.displayName} is in your nursery. Ready in {Format.duration(def.hatchSeconds)}.`
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
	if Nursery.penCount(data) >= Config.Nursery.PEN_CAPACITY then
		Remotes.Notify:fireClient(player, "warn", "The nursery pen is full! Move a baby to a pedestal first.")
		return false
	end
	-- a Baby in the pen, with the 2-day minimum timer and starting loyalty
	local brainrot =
		Roll.newBrainrot(BrainrotService.newId(), speciesId, Roll.variant(rng), player.UserId, os.time())
	brainrot.growth = 0
	brainrot.inNursery = true
	data.brainrots[brainrot.id] = brainrot
	table.remove(data.eggs, index)
	BrainrotService.sync(player)
	NurseryService.refresh(player)
	DataService.sendSnapshot(player)
	Remotes.HatchResult:fireClient(
		player,
		{ brainrot = BrainrotService.toPublic(data, brainrot), placed = "nursery" }
	)
	local species = Config.Species.byId[speciesId]
	local variant = if brainrot.variant ~= "Normal" then `{brainrot.variant} ` else ""
	Remotes.Notify:fireClient(
		player,
		"good",
		`Hatched a baby {variant}{species.displayName} ({brainrot.rarity})!`
	)
	if brainrot.rarity == "Mythic" or brainrot.rarity == "Secret" then
		Remotes.Notify:fireAll(
			"drop",
			`{player.DisplayName} hatched a {brainrot.rarity} {species.displayName}!`
		)
	end
	return true
end

function EggService.init() end

function EggService.start()
	Remotes.BuyEgg:connect(function(player, eggId)
		EggService.buy(player, eggId)
	end)
	Remotes.HatchEgg:connect(function(player, id)
		EggService.hatch(player, id)
	end)
end

return EggService
