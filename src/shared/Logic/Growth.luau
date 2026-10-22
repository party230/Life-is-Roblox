--!strict
-- Growth stages (D39): Baby -> Teen -> Adult by growth points (food + a passive trickle). Each stage sets the
-- model scale and an income multiplier (Config/Nursery).

local Config = require("../Config")
local Types = require("../Types")

local Growth = {}

local N = Config.Nursery

function Growth.stageFor(points: number): Config.StageDef
	local current = N.stages[1]
	for _, s in N.stages do
		if points >= s.minGrowth then
			current = s
		end
	end
	return current
end

function Growth.stage(b: Types.Brainrot): Config.StageDef
	return Growth.stageFor(b.growth)
end

-- Points still needed for the next stage (nil when Adult).
function Growth.toNext(points: number): (Config.StageDef?, number)
	for _, s in N.stages do
		if points < s.minGrowth then
			return s, s.minGrowth - points
		end
	end
	return nil, 0
end

-- Passive growth while the owner is online. Returns true if the stage changed.
function Growth.tick(b: Types.Brainrot, days: number): boolean
	if b.growth >= N.ADULT_GROWTH then
		return false
	end
	local before = Growth.stage(b).id
	b.growth = math.min(N.ADULT_GROWTH, b.growth + N.GROWTH_PER_HOUR * 24 * days)
	return Growth.stage(b).id ~= before
end

return Growth
