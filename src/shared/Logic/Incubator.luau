--!strict
-- Egg incubation timing.

local Types = require("../Types")

local Incubator = {}

function Incubator.timeLeft(egg: Types.PendingEgg, now: number): number
	return math.max(0, egg.startedAt + egg.hatchSeconds - now)
end

function Incubator.isReady(egg: Types.PendingEgg, now: number): boolean
	return Incubator.timeLeft(egg, now) <= 0
end

function Incubator.find(eggs: { Types.PendingEgg }, id: string): (Types.PendingEgg?, number?)
	for i, egg in eggs do
		if egg.id == id then
			return egg, i
		end
	end
	return nil, nil
end

return Incubator
