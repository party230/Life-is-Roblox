--!strict
-- Brainrot records and their in-world models. All creation goes through `give`, which places the new
-- brainrot on a free pedestal (or into storage) and keeps the models in sync with the save.
-- Models: one per pedestal brainrot, and one per nursery-pen brainrot (babies/teens, D39). Models are scaled to
-- their growth stage, show a public "Baby"/"Teen" nameplate line, and carry Leaving = true while their runaway
-- timer has run out (the client makes them fidget).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Growth = require(ReplicatedStorage.Shared.Logic.Growth)
local Nursery = require(ReplicatedStorage.Shared.Logic.Nursery)
local Public = require(ReplicatedStorage.Shared.Data.Public)
local Slots = require(ReplicatedStorage.Shared.Logic.Slots)
local Types = require(ReplicatedStorage.Shared.Types)

local Brainrot = require(ReplicatedStorage.Shared.World.Brainrot)
local Config = require(ReplicatedStorage.Shared.Config)
local Builder = require(script.Parent.Parent.World.Builder)
local Entitlements = require(script.Parent.Parent.Entitlements)
local BaseService = require(script.Parent.BaseService)
local DataService = require(script.Parent.DataService)

local BrainrotService = {}

-- player -> brainrot id -> model
local models: { [Player]: { [string]: Model } } = {}
-- brainrots that are out of their base right now (running away / home); no model is kept for them here
local away: { [string]: boolean } = {}

function BrainrotService.newId(): string
	return HttpService:GenerateGUID(false)
end

local function clear(player: Player)
	local owned = models[player]
	if owned then
		for _, model in owned do
			model:Destroy()
		end
	end
	models[player] = nil
end

-- Where a brainrot should stand: "slot:<n>" on a pedestal, "pen:<k>" in the nursery, or nil (storage / away).
local function placements(data: Types.PlayerData): { [string]: string }
	local wanted: { [string]: string } = {}
	for key, id in data.pedestals do
		if not away[id] then
			wanted[id] = `slot:{key}`
		end
	end
	local pen = 0
	for _, b in Nursery.penList(data) do
		if not away[b.id] then
			pen += 1
			wanted[b.id] = `pen:{pen}`
		end
	end
	return wanted
end

local function build(player: Player, refs: Builder.PlotRefs, b: Types.Brainrot, where: string): Model
	local stage = Growth.stage(b)
	local opts: Brainrot.Options = { stage = stage.id }
	local model = Brainrot.create(b.speciesId, b.rarity, b.variant, opts)
	if stage.scale ~= 1 then
		model:ScaleTo(stage.scale)
	end
	model:SetAttribute("BrainrotId", b.id)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Where", where)
	model:SetAttribute("Stage", stage.id)
	model:SetAttribute("Leaving", b.leaving)
	local kind, index = string.match(where, "^(%a+):(%d+)$")
	local n = tonumber(index) :: number
	local hover = ((model:GetAttribute("Hover") :: number?) or 0) * stage.scale
	if kind == "slot" then
		model:SetAttribute("Slot", n)
		model:PivotTo(Builder.pedestalTop(refs, n) * CFrame.new(0, hover, 0))
	else
		model:PivotTo(
			Builder.penSpot(refs, n)
				* CFrame.new(0, hover, 0)
				* CFrame.Angles(0, math.rad((n * 47) % 60 - 30), 0)
		)
	end
	model.Parent = refs.brainrots
	return model
end

-- Makes the base's models match the save (pedestals and nursery pen).
function BrainrotService.sync(player: Player)
	local data = DataService.get(player)
	local refs = BaseService.refsFor(player)
	if not data or not refs then
		return
	end
	local owned: { [string]: Model } = models[player] or {}
	models[player] = owned

	local wanted = placements(data)
	for id, model in owned do
		local b = data.brainrots[id]
		if
			wanted[id] == nil
			or b == nil
			or model:GetAttribute("Where") ~= wanted[id]
			or model:GetAttribute("Stage") ~= Growth.stage(b).id
		then
			model:Destroy()
			owned[id] = nil
		else
			model:SetAttribute("Leaving", b.leaving)
		end
	end
	for id, where in wanted do
		if not owned[id] then
			owned[id] = build(player, refs, data.brainrots[id], where)
		end
	end
	-- rims glow in the occupant's rarity colour
	for slot = 1, #Config.Layout.SLOTS do
		local rim = Builder.rim(refs, slot)
		if rim and Config.Layout.SLOTS[slot].tier <= BrainrotService.tiers(player) then
			local id = data.pedestals[tostring(slot)]
			local b = id and data.brainrots[id]
			rim.Color = if b
				then Color3.fromHex(Config.Rarities.byId[b.rarity].color)
				else Color3.fromHex("#2F8CFF")
		end
	end
end

-- The model standing in the base for this brainrot (nil if in storage or away).
function BrainrotService.modelOf(player: Player, id: string): Model?
	local owned = models[player]
	return owned and owned[id]
end

-- Marks a brainrot as away from its base (running) so sync doesn't rebuild its model; `false` brings it back.
function BrainrotService.setAway(id: string, isAway: boolean)
	if isAway then
		away[id] = true
	else
		away[id] = nil
	end
end

-- Takes the model out of the base without destroying it (a runaway keeps its model while it runs).
function BrainrotService.detachModel(player: Player, id: string): Model?
	local owned = models[player]
	local model = owned and owned[id]
	if owned and model then
		owned[id] = nil
	end
	return model
end

function BrainrotService.tiers(player: Player): number
	return Entitlements.extraSlotTiers(player)
end

-- Room on a pedestal or in storage.
function BrainrotService.hasRoom(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil
		and (
			Slots.firstFree(data, BrainrotService.tiers(player)) ~= nil
			or Slots.storageCount(data) < Config.Game.STORAGE_SLOTS
		)
end

function BrainrotService.hasFreePedestal(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and Slots.firstFree(data, BrainrotService.tiers(player)) ~= nil
end

-- Adds a brainrot to the player's save and world. Returns where it went, or nil if there was no room.
function BrainrotService.give(player: Player, brainrot: Types.Brainrot): ("pedestal" | "storage")?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	brainrot.inNursery = false
	local placed: ("pedestal" | "storage")? = Slots.add(data, brainrot, BrainrotService.tiers(player)) :: any
	if placed then
		BrainrotService.sync(player)
		DataService.sendSnapshot(player)
	end
	return placed
end

-- Removes a brainrot from the player's save entirely (it ran off to the carpet, or ran home). Returns the record.
function BrainrotService.take(player: Player, id: string): Types.Brainrot?
	local data = DataService.get(player)
	local b = data and data.brainrots[id]
	if not data or not b then
		return nil
	end
	data.brainrots[id] = nil
	for key, pid in data.pedestals do
		if pid == id then
			data.pedestals[key] = nil
		end
	end
	away[id] = nil
	BrainrotService.sync(player)
	DataService.sendSnapshot(player)
	return b
end

-- Owner-only view (includes loyalty and the runaway timer): only ever send to the owner.
function BrainrotService.toPublic(data: Types.PlayerData, b: Types.Brainrot): Types.PublicBrainrot
	return Public.brainrot(b, Slots.slotOf(data, b.id))
end

function BrainrotService.init() end

function BrainrotService.start()
	BaseService.assigned:connect(function(player)
		BrainrotService.sync(player)
	end)
	BaseService.released:connect(function(player)
		clear(player)
	end)
	Players.PlayerRemoving:Connect(clear)
end

return BrainrotService
