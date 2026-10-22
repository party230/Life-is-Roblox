--!strict
-- Day/night clock. The server starts the clock once; everything else derives the phase from elapsed time.

local Config = require("../Config")
local Types = require("../Types")

export type PhaseInfo = {
	phase: Types.CyclePhase,
	remaining: number, -- seconds left in this phase
	cycle: number, -- 0-based cycle (day) number
	phaseStart: number, -- elapsed time the phase began
}

local Cycle = {}

local function phases(): { { name: Types.CyclePhase, length: number } }
	local g = Config.Game
	return {
		{ name = "Day", length = g.DAY_LENGTH },
		{ name = "Dusk", length = g.DUSK },
		{ name = "Night", length = g.NIGHT_LENGTH },
		{ name = "DawnVote", length = g.DAWN_VOTE },
	}
end

function Cycle.length(): number
	local total = 0
	for _, p in phases() do
		total += p.length
	end
	return total
end

function Cycle.at(elapsed: number): PhaseInfo
	local total = Cycle.length()
	local t = math.max(0, elapsed)
	local cycle = t // total
	local into = t - cycle * total
	local start = 0
	for _, p in phases() do
		if into < start + p.length then
			return {
				phase = p.name,
				remaining = start + p.length - into,
				cycle = cycle,
				phaseStart = cycle * total + start,
			}
		end
		start += p.length
	end
	-- float edge: exactly at the end of the cycle
	return {
		phase = "Day",
		remaining = Config.Game.DAY_LENGTH,
		cycle = cycle + 1,
		phaseStart = (cycle + 1) * total,
	}
end

-- Belt and egg shop are open in Day and Dusk; closed for Night and the dawn vote (approved Q1).
function Cycle.shopOpen(phase: Types.CyclePhase): boolean
	return phase == "Day" or phase == "Dusk"
end

return Cycle
