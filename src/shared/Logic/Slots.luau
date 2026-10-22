--!strict
-- Pedestal slots. Slot keys are strings "1".."14" in saves (DataStore JSON can't hold sparse arrays).
-- Brainrots not on a pedestal are in storage (no income).

local Config = require("../Config")
local Types = require("../Types")

local Slots = {}

function Slots.count(): number
	return #Config.Layout.SLOTS
end

-- Number of Extra Slots tiers owned (0..3) -> is this slot usable?
function Slots.isUnlocked(slot: number, tiersOwned: number): boolean
	local def = Config.Layout.SLOTS[slot]
	return def ~= nil and def.tier <= tiersOwned
end

function Slots.unlockedCount(tiersOwned: number): number
	local n = 0
	for i = 1, Slots.count() do
		if Slots.isUnlocked(i, tiersOwned) then
			n += 1
		end
	end
	return n
end

function Slots.firstFree(data: Types.PlayerData, tiersOwned: number): number?
	for i = 1, Slots.count() do
		if Slots.isUnlocked(i, tiersOwned) and data.pedestals[tostring(i)] == nil then
			return i
		end
	end
	return nil
end

function Slots.slotOf(data: Types.PlayerData, brainrotId: string): number?
	for key, id in data.pedestals do
		if id == brainrotId then
			return tonumber(key)
		end
	end
	return nil
end

function Slots.placedCount(data: Types.PlayerData): number
	local n = 0
	for _ in data.pedestals do
		n += 1
	end
	return n
end

-- Brainrots in storage: not on a pedestal and not living in the nursery pen.
function Slots.storageCount(data: Types.PlayerData): number
	local onPedestal: { [string]: boolean } = {}
	for _, id in data.pedestals do
		onPedestal[id] = true
	end
	local total = 0
	for id, b in data.brainrots do
		if not onPedestal[id] and not b.inNursery then
			total += 1
		end
	end
	return total
end

-- Adds a brainrot to the save: onto the first free pedestal, else into storage if there's room.
-- Returns "pedestal" | "storage" | nil (no room; nothing changed).
function Slots.add(
	data: Types.PlayerData,
	brainrot: Types.Brainrot,
	tiersOwned: number
): ("pedestal" | "storage")?
	local slot = Slots.firstFree(data, tiersOwned)
	if slot then
		data.brainrots[brainrot.id] = brainrot
		data.pedestals[tostring(slot)] = brainrot.id
		return "pedestal"
	end
	if Slots.storageCount(data) < Config.Game.STORAGE_SLOTS then
		data.brainrots[brainrot.id] = brainrot
		return "storage"
	end
	return nil
end

-- Drops pedestal entries that point at missing brainrots or locked slots (e.g. a pass was refunded),
-- moving those brainrots to storage. Returns true if anything changed.
function Slots.sanitize(data: Types.PlayerData, tiersOwned: number): boolean
	local changed = false
	for key, id in data.pedestals do
		local slot = tonumber(key)
		if data.brainrots[id] == nil or slot == nil or not Slots.isUnlocked(slot, tiersOwned) then
			data.pedestals[key] = nil
			changed = true
		end
	end
	return changed
end

return Slots
