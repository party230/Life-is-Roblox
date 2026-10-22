--!strict
-- Brainrot records and their in-world models. All creation goes through `give`, which places the new
-- brainrot on a free pedestal (or into storage) and keeps the models in sync with the save.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- Makes the plot's models match the save: one model per pedestal brainrot, at the right slot.
function BrainrotService.sync(player: Player)
	local data = DataService.get(player)
	local refs = BaseService.refsFor(player)
	if not data or not refs then
		return
	end
	local owned: { [string]: Model } = models[player] or {}
	models[player] = owned

	local wanted: { [string]: number } = {}
	for key, id in data.pedestals do
		wanted[id] = tonumber(key) :: number
	end
	for id, model in owned do
		if wanted[id] == nil or model:GetAttribute("Slot") ~= wanted[id] then
			model:Destroy()
			owned[id] = nil
		end
	end
	for id, slot in wanted do
		if not owned[id] then
			local b = data.brainrots[id]
			local model = Brainrot.create(b.speciesId, b.rarity, b.variant)
			model:SetAttribute("BrainrotId", id)
			model:SetAttribute("Slot", slot)
			model:SetAttribute("OwnerUserId", player.UserId)
			model:PivotTo(Builder.pedestalTop(refs, slot))
			model.Parent = refs.brainrots
			owned[id] = model
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
	local placed: ("pedestal" | "storage")? = Slots.add(data, brainrot, BrainrotService.tiers(player)) :: any
	if placed then
		BrainrotService.sync(player)
		DataService.sendSnapshot(player)
	end
	return placed
end

function BrainrotService.toPublic(data: Types.PlayerData, b: Types.Brainrot): Types.PublicBrainrot
	return {
		id = b.id,
		speciesId = b.speciesId,
		rarity = b.rarity,
		variant = b.variant,
		incomePerSec = b.incomePerSec,
		loyalty = b.loyalty,
		isStolen = b.isStolen,
		slot = Slots.slotOf(data, b.id),
	}
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
