--!strict
-- Income maths (D10): BASE_INCOME_PER_SEC x species.incomeFactor x rarity.incomeMult x mutation.incomeMult.
-- Only brainrots standing on a pedestal earn.

local Config = require("../Config")
local Types = require("../Types")

local Income = {}

function Income.perSec(speciesId: string, mutation: string): number
	local species = Config.Species.byId[speciesId]
	if not species then
		return 0
	end
	local rarity = Config.Rarities.byId[species.rarity]
	local mut = Config.Mutations.byId[mutation] or Config.Mutations.byId.None
	return Config.Game.BASE_INCOME_PER_SEC * species.incomeFactor * rarity.incomeMult * mut.incomeMult
end

-- Recomputes the cached incomePerSec on every brainrot (after balance changes). Returns true if any changed.
function Income.refresh(data: Types.PlayerData): boolean
	local changed = false
	for _, b in data.brainrots do
		local value = Income.perSec(b.speciesId, b.mutation)
		if b.incomePerSec ~= value then
			b.incomePerSec = value
			changed = true
		end
	end
	return changed
end

-- Base income per second from brainrots on pedestals, before pass multipliers.
function Income.basePerSec(data: Types.PlayerData): number
	local total = 0
	for _, id in data.pedestals do
		local b = data.brainrots[id]
		if b then
			total += b.incomePerSec
		end
	end
	return total
end

-- Offline earnings: OFFLINE_RATE of base income for up to OFFLINE_CAP_HOURS (doubled by Auto-Collect).
function Income.offline(perSec: number, secondsAway: number, hasAutoCollect: boolean): number
	if perSec <= 0 or secondsAway <= 0 then
		return 0
	end
	local capHours = Config.Game.OFFLINE_CAP_HOURS
	if hasAutoCollect then
		capHours *= Config.Products.AUTO_COLLECT_OFFLINE_CAP_MULT
	end
	local seconds = math.min(secondsAway, capHours * 3600)
	return math.floor(perSec * Config.Game.OFFLINE_RATE * seconds)
end

return Income
