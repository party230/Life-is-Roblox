--!strict
-- Nursery rules (D39): progress-scaled unlock price, usable incubators, and who lives in the pen.

local Config = require("../Config")
local Types = require("../Types")

local Nursery = {}

local N = Config.Nursery

-- Cash price to unlock: UNLOCK_INCOME_SECONDS of the best-ever income/s, clamped to [UNLOCK_MIN, UNLOCK_MAX],
-- rounded to a nice number.
function Nursery.unlockPrice(peakIncomePerSec: number): number
	local raw = math.clamp(peakIncomePerSec * N.UNLOCK_INCOME_SECONDS, N.UNLOCK_MIN, N.UNLOCK_MAX)
	local magnitude = 10 ^ math.max(0, math.floor(math.log10(raw)) - 1)
	return math.ceil(raw / magnitude) * magnitude
end

function Nursery.incubators(passTiers: number): number
	return math.min(N.MAX_INCUBATORS, N.BASE_INCUBATORS + passTiers)
end

function Nursery.penCount(data: Types.PlayerData): number
	local n = 0
	for _, b in data.brainrots do
		if b.inNursery then
			n += 1
		end
	end
	return n
end

function Nursery.penList(data: Types.PlayerData): { Types.Brainrot }
	local list: { Types.Brainrot } = {}
	for _, b in data.brainrots do
		if b.inNursery then
			table.insert(list, b)
		end
	end
	table.sort(list, function(a, c)
		return a.acquiredAt < c.acquiredAt or (a.acquiredAt == c.acquiredAt and a.id < c.id)
	end)
	return list
end

return Nursery
