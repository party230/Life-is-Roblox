--!strict
-- Nursery + growth (D39). Each base has a nursery, locked by default. Unlocking costs cash that scales with progress
-- (owner answer 2) or a Robux skip. Eggs from the hub Egg Shop incubate here and hatch into Babies, which grow
-- Baby -> Teen -> Adult from food growth points plus a slow passive trickle (owner answer 3).

export type StageId = "Baby" | "Teen" | "Adult"
export type StageDef = { id: StageId, minGrowth: number, scale: number, incomeMult: number }

local stages: { StageDef } = {
	{ id = "Baby", minGrowth = 0, scale = 0.5, incomeMult = 0.4 },
	{ id = "Teen", minGrowth = 40, scale = 0.75, incomeMult = 0.7 },
	{ id = "Adult", minGrowth = 140, scale = 1, incomeMult = 1 },
}

local byId: { [string]: StageDef } = {}
for _, def in stages do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	-- Unlock price: UNLOCK_INCOME_SECONDS of the player's best-ever income/s, clamped. Uses the best ever
	-- (stats.peakIncome) so taking brainrots off pedestals can't make it cheaper.
	UNLOCK_INCOME_SECONDS = 300,
	UNLOCK_MIN = 25_000,
	UNLOCK_MAX = 5_000_000,
	UNLOCK_ROBUX_PRODUCT = "NurseryUnlock", -- Products key for the skip
	BASE_INCUBATORS = 3,
	MAX_INCUBATORS = 6, -- + one per Extra Incubator pass tier
	PEN_CAPACITY = 10, -- babies/teens living in the nursery

	stages = table.freeze(stages),
	stageById = table.freeze(byId),
	ADULT_GROWTH = 140,
	GROWTH_PER_HOUR = 1, -- passive growth per in-game hour while the owner is online
})
