--!strict
-- Save migrations. `steps[n]` upgrades a save from version n to n + 1, in place.
-- Never edit a shipped step; append a new one and bump Template.CURRENT_VERSION.

export type Step = (data: { [string]: any }) -> ()

local Migrations = {}

-- Variant rename for the old Phase 0/1 mutations (D22).
local MUTATION_TO_VARIANT: { [string]: string } = {
	None = "Normal",
	Golden = "Gold",
	Glitched = "Normal",
	Rainbow = "Rainbow",
	Tiny = "Normal",
	Mega = "Normal",
}

-- Values frozen at the time of the step (never read live Config inside a migration).
local LOYALTY_START_V4 = 50
local TIMER_MIN_DAYS_V4 = 2
local ADULT_GROWTH_V4 = 140

local VARIANT_RENAMES_V3: { [string]: string } = {
	Gold = "Normal",
	Diamond = "Normal",
	Dark = "Evil",
}

Migrations.steps = {
	-- 1 -> 2: brainrot.mutation -> brainrot.variant. Old original-species ids are kept as-is: they resolve to
	-- their rarity's placeholder at runtime (same path as a disabled character), so nothing is lost.
	function(data: { [string]: any })
		for _, b in data.brainrots or {} do
			if b.variant == nil then
				b.variant = MUTATION_TO_VARIANT[b.mutation or "None"] or "Normal"
			end
			b.mutation = nil
		end
	end,
	-- 2 -> 3 (D36): Gold and Diamond were removed, so their owners get a Normal one; Dark is now Evil.
	function(data: { [string]: any })
		for _, b in data.brainrots or {} do
			b.variant = VARIANT_RENAMES_V3[b.variant] or b.variant or "Normal"
		end
	end,
	-- 3 -> 4 (D39): runaway timer, growth and the nursery; food replaces treats.
	-- Existing brainrots are Adults with the minimum timer, and at least the starting loyalty (the old default
	-- was 0, which would now halve their income).
	function(data: { [string]: any })
		for _, b in data.brainrots or {} do
			b.loyalty = math.max(tonumber(b.loyalty) or 0, LOYALTY_START_V4)
			b.timerDays = TIMER_MIN_DAYS_V4
			b.timerFullDays = TIMER_MIN_DAYS_V4
			b.leaving = false
			b.sinceFedDays = 0
			b.growth = ADULT_GROWTH_V4
			b.inNursery = false
			b.loyaltyTimeToday = nil
			b.loyaltyDay = nil
		end
		data.food = data.food or {}
		local treats = tonumber(data.treats) or 0
		if treats > 0 then
			data.food.slice = (data.food.slice or 0) + treats -- treat packs became food: 1 treat = 1 Pizza Slice
		end
		data.treats = nil
		data.nurseryUnlocked = data.nurseryUnlocked == true
		data.stats = data.stats or {}
		data.stats.peakIncome = data.stats.peakIncome or 0
	end,
} :: { Step }

-- Runs every step from data.version up to target. Returns false (and leaves the save untouched by later
-- steps) if the save is from a newer build than this server knows about.
function Migrations.run(data: { [string]: any }, target: number, steps: { Step }?): (boolean, string?)
	local list = steps or Migrations.steps
	local version = if type(data.version) == "number" then data.version else 1
	if version > target then
		return false, `save version {version} is newer than server version {target}`
	end
	while version < target do
		local step = list[version]
		if not step then
			return false, `missing migration step {version} -> {version + 1}`
		end
		step(data)
		version += 1
		data.version = version
	end
	return true, nil
end

return Migrations
