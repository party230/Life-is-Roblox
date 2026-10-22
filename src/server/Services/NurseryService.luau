--!strict
-- Nursery (D39): a walled area at the back of each base, locked by default. Unlock with cash (price scales with
-- the owner's best-ever income, owner answer 2) or the Robux skip (MonetizationService -> `grantUnlock`).
-- Eggs from the hub Egg Shop sit in its incubators (shown on the incubators with a countdown) and hatch into
-- Babies that live in the pen until moved to a pedestal (any stage). Growth itself is in Logic/Growth.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Incubator = require(ReplicatedStorage.Shared.Logic.Incubator)
local Nursery = require(ReplicatedStorage.Shared.Logic.Nursery)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Slots = require(ReplicatedStorage.Shared.Logic.Slots)

local Blocks = require(script.Parent.Parent.World.Blocks)
local Builder = require(script.Parent.Parent.World.Builder)
local Entitlements = require(script.Parent.Parent.Entitlements)
local BaseService = require(script.Parent.BaseService)
local BrainrotService = require(script.Parent.BrainrotService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local NurseryService = {}

local EGG_COLORS: { [string]: string } = {
	basic = "#FFF4E0",
	fancy = "#B98CFF",
	streak = "#FFD23F",
	streak7 = "#FFD23F",
}

-- player -> egg display parts (one per incubator in use)
local eggParts: { [Player]: { Part } } = {}

function NurseryService.incubators(player: Player): number
	return Nursery.incubators(Entitlements.incubatorTiers(player))
end

local function clearEggs(player: Player)
	local parts = eggParts[player]
	if parts then
		for _, p in parts do
			p:Destroy()
		end
	end
	eggParts[player] = nil
end

-- Locked/open look, pass labels, the price line, and an egg with a countdown on each busy incubator.
function NurseryService.refresh(player: Player)
	local data = DataService.get(player)
	local refs = BaseService.refsFor(player)
	if not data or not refs then
		return
	end
	local price = Nursery.unlockPrice(data.stats.peakIncome)
	local robux = Config.Products.productByKey[Config.Nursery.UNLOCK_ROBUX_PRODUCT]
	Builder.setNursery(
		refs,
		data.nurseryUnlocked,
		NurseryService.incubators(player),
		`Unlock: {Format.price(price)}  or  R$ {if robux then robux.robux else "?"}`
	)
	clearEggs(player)
	if not data.nurseryUnlocked then
		return
	end
	local parts: { Part } = {}
	local now = os.time()
	for i, egg in data.eggs do
		local top = refs.nursery.incubatorTops[i]
		if top then
			local ball = Blocks.ball(
				refs.model,
				"Egg",
				2.2,
				top * CFrame.new(0, 1.1, 0),
				EGG_COLORS[egg.eggId] or "#FFFFFF",
				{
					canCollide = false,
				}
			)
			local left = Incubator.timeLeft(egg, now)
			local _, labels = Blocks.floating(ball, {
				{
					text = if left > 0 then `Hatching {Format.clock(left)}` else "Ready to hatch!",
					color = if left > 0 then "#FFFFFF" else "#7CFF9B",
				},
			}, 4.6, 1, 3, 60)
			ball:SetAttribute("EggId", egg.id)
			labels[1]:SetAttribute("ReadyAt", egg.startedAt + egg.hatchSeconds)
			table.insert(parts, ball)
		end
	end
	eggParts[player] = parts
end

function NurseryService.unlock(player: Player): boolean
	local data = DataService.get(player)
	if not data or data.nurseryUnlocked then
		return false
	end
	local price = Nursery.unlockPrice(data.stats.peakIncome)
	if not EconomyService.spend(player, price) then
		Remotes.Notify:fireClient(player, "warn", `Unlocking the nursery costs {Format.price(price)}.`)
		return false
	end
	data.nurseryUnlocked = true
	NurseryService.refresh(player)
	DataService.sendSnapshot(player)
	Remotes.Notify:fireClient(player, "good", "Your nursery is open! Buy eggs at the hub Egg Shop.")
	return true
end

-- Robux skip (MonetizationService).
function NurseryService.grantUnlock(player: Player): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	data.nurseryUnlocked = true
	NurseryService.refresh(player)
	DataService.sendSnapshot(player)
	Remotes.Notify:fireClient(player, "good", "Your nursery is open! Buy eggs at the hub Egg Shop.")
	return true
end

-- Moves a nursery (or storage) brainrot onto the first free pedestal, at any growth stage.
function NurseryService.moveToPedestal(player: Player, id: string): boolean
	local data = DataService.get(player)
	local b = data and data.brainrots[id]
	if not data or not b or Slots.slotOf(data, id) then
		return false
	end
	local slot = Slots.firstFree(data, BrainrotService.tiers(player))
	if not slot then
		Remotes.Notify:fireClient(player, "warn", "No free pedestal. Free one up first!")
		return false
	end
	b.inNursery = false
	data.pedestals[tostring(slot)] = id
	BrainrotService.sync(player)
	DataService.sendSnapshot(player)
	return true
end

function NurseryService.init() end

function NurseryService.start()
	BaseService.assigned:connect(function(player)
		NurseryService.refresh(player)
	end)
	BaseService.released:connect(function(player, refs)
		clearEggs(player)
		Builder.setNursery(refs, false, Config.Nursery.BASE_INCUBATORS, "")
	end)
	DataService.sessionReady:connect(function(player)
		NurseryService.refresh(player)
	end)
	Remotes.UnlockNursery:connect(NurseryService.unlock)
	Remotes.MoveToPedestal:connect(NurseryService.moveToPedestal)
	Players.PlayerRemoving:Connect(clearEggs)

	-- the door prompt opens the nursery screen (the client ignores other players' doors)
	for i = 1, Config.Game.PLOT_COUNT do
		local refs = BaseService.refs(i)
		if refs then
			local prompt = Blocks.prompt(refs.nursery.door, "Nursery", "Your base", "Nursery", 10)
			prompt:SetAttribute("PlotIndex", i)
		end
	end

	-- egg countdown labels
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for _, parts in eggParts do
				for _, ball in parts do
					local gui = ball:FindFirstChild("FloatingLabel")
					local label = gui and gui:FindFirstChild("Line1") :: TextLabel?
					if label then
						local left = math.max(0, ((label:GetAttribute("ReadyAt") :: number?) or now) - now)
						label.Text = if left > 0 then `Hatching {Format.clock(left)}` else "Ready to hatch!"
						label.TextColor3 = Color3.fromHex(if left > 0 then "#FFFFFF" else "#7CFF9B")
					end
				end
			end
		end
	end)
end

return NurseryService
