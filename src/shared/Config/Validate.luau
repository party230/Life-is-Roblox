--!strict
-- Sanity checks for Config. Returns (errors, warnings). Run by the unit tests and at server boot.
-- Takes the config as a parameter so tests can feed it broken copies.

export type Result = { errors: { string }, warnings: { string } }

local Validate = {}

local function sumWeights(weights: { [string]: number }): number
	local total = 0
	for _, w in weights do
		total += w
	end
	return total
end

function Validate.run(config: any): Result
	local errors: { string } = {}
	local warnings: { string } = {}
	local function err(msg: string)
		table.insert(errors, msg)
	end

	local g = config.Game
	if g.DAY_LENGTH <= 0 or g.DUSK <= 0 or g.NIGHT_LENGTH <= 0 or g.DAWN_VOTE <= 0 then
		err("cycle phase lengths must be positive")
	end
	if g.START_SLOTS > g.MAX_SLOTS then
		err("START_SLOTS exceeds MAX_SLOTS")
	end
	local passSlots = 3 * config.Products.EXTRA_SLOTS_PER_TIER
	if g.START_SLOTS + passSlots ~= g.MAX_SLOTS then
		err(`MAX_SLOTS should equal START_SLOTS + all Extra Slot passes ({g.START_SLOTS + passSlots})`)
	end
	if g.ESCAPE_BASE_SPEED > g.ESCAPE_SPEED_CAP then
		err("ESCAPE_BASE_SPEED exceeds ESCAPE_SPEED_CAP")
	end
	if g.CARRY_SPEED_FLOOR <= 0 or g.CARRY_SPEED_FLOOR > 1 then
		err("CARRY_SPEED_FLOOR must be in (0, 1]")
	end
	if g.LOYALTY_SPEED_DIVISOR < g.LOYALTY_MAX then
		err("LOYALTY_SPEED_DIVISOR below LOYALTY_MAX would allow a zero/negative carry speed")
	end
	if g.DEFECT_SCALAR * g.LOYALTY_MAX > 1 then
		err("DEFECT_SCALAR * LOYALTY_MAX exceeds 100% defect chance")
	end
	if g.OFFLINE_RATE < 0 or g.OFFLINE_RATE > 1 then
		err("OFFLINE_RATE must be in [0, 1]")
	end
	if g.ROTTER_CASH_PENALTY < 0 or g.ROTTER_CASH_PENALTY > 1 then
		err("ROTTER_CASH_PENALTY must be in [0, 1]")
	end
	if g.ROTTER_MIN_PLAYERS > g.MAX_PLAYERS then
		warnings[#warnings + 1] = "ROTTER_MIN_PLAYERS above MAX_PLAYERS: the Rotter can never spawn"
	end

	-- Rarities
	local rarityIds: { [string]: boolean } = {}
	local lastOrder = 0
	for _, r in config.Rarities.list do
		rarityIds[r.id] = true
		if r.order <= lastOrder then
			err(`rarity {r.id} is out of order`)
		end
		lastOrder = r.order
		if r.weight < 0 or r.incomeMult <= 0 or r.shopPrice <= 0 then
			err(`rarity {r.id} has invalid numbers`)
		end
		if r.carrySpeedMult <= 0 or r.carrySpeedMult > 1 then
			err(`rarity {r.id} carrySpeedMult must be in (0, 1]`)
		end
	end

	local function checkRarityWeights(where: string, weights: { [string]: number })
		for id, w in weights do
			if not rarityIds[id] then
				err(`{where}: unknown rarity {id}`)
			elseif w < 0 then
				err(`{where}: negative weight for {id}`)
			end
		end
		if sumWeights(weights) <= 0 then
			err(`{where}: weights sum to zero`)
		end
	end

	-- Variants
	local variantWeights: { [string]: number } = {}
	for _, v in config.Variants.list do
		variantWeights[v.id] = v.weight
		if v.incomeMult <= 0 or v.priceMult <= 0 or v.weight < 0 then
			err(`variant {v.id} has invalid numbers`)
		end
	end
	if not config.Variants.byId.Normal then
		err("variants must include Normal")
	end
	if sumWeights(variantWeights) <= 0 then
		err("variant weights sum to zero")
	end

	-- Species
	local speciesCount = 0
	local seenIds: { [string]: boolean } = {}
	local rarityHasSpecies: { [string]: boolean } = {}
	for _, s in config.Species.list do
		speciesCount += 1
		if seenIds[s.id] then
			err(`duplicate species id {s.id}`)
		end
		seenIds[s.id] = true
		if not rarityIds[s.rarity] then
			err(`species {s.id} has unknown rarity {s.rarity}`)
		end
		if not s.disabled then
			rarityHasSpecies[s.rarity] = true
		end
		if s.reference ~= `assets/reference/{s.id}.png` then
			err(`species {s.id} reference path should be assets/reference/{s.id}.png`)
		end
		if not string.match(s.id, "^[a-z0-9_]+$") then
			err(`species id {s.id} must be lowercase snake_case`)
		end
		if s.incomeFactor <= 0 then
			err(`species {s.id} incomeFactor must be positive`)
		end
	end
	if speciesCount < 1 then
		err("no species configured")
	end
	for _, r in config.Rarities.list do
		if not config.Species.placeholders[r.id] then
			err(`missing placeholder for rarity {r.id}`)
		end
	end

	-- Any rarity that can be rolled must have at least one species.
	local function checkRollable(where: string, weights: { [string]: number })
		for id, w in weights do
			if w > 0 and not rarityHasSpecies[id] then
				table.insert(
					warnings,
					`{where}: rarity {id} can roll but has no enabled species (placeholder used)`
				)
			end
		end
	end

	checkRarityWeights("Shop.FEATURED_RARITY_WEIGHTS", config.Shop.FEATURED_RARITY_WEIGHTS)
	checkRollable("Shop.FEATURED_RARITY_WEIGHTS", config.Shop.FEATURED_RARITY_WEIGHTS)
	if #config.Layout.SLOTS ~= g.MAX_SLOTS then
		err(`Layout.SLOTS has {#config.Layout.SLOTS} slots but MAX_SLOTS is {g.MAX_SLOTS}`)
	end
	local starting = 0
	for _, slot in config.Layout.SLOTS do
		if slot.tier == 0 then
			starting += 1
		end
	end
	if starting ~= g.START_SLOTS then
		err(`Layout.SLOTS has {starting} tier-0 slots but START_SLOTS is {g.START_SLOTS}`)
	end
	checkRarityWeights("Shop.RARITY_WEIGHTS", config.Shop.RARITY_WEIGHTS)
	checkRollable("Shop.RARITY_WEIGHTS", config.Shop.RARITY_WEIGHTS)
	for _, egg in config.Eggs.list do
		checkRarityWeights(`egg {egg.id}`, egg.rarityWeights)
		checkRollable(`egg {egg.id}`, egg.rarityWeights)
		if egg.robuxProductKey and not config.Products.productByKey[egg.robuxProductKey] then
			err(`egg {egg.id} references unknown product {egg.robuxProductKey}`)
		end
	end
	for _, key in { "DAILY_STREAK_EGG", "DAILY_STREAK_BONUS_EGG" } do
		if not config.Eggs.byId[config.Eggs[key]] then
			err(`Eggs.{key} references an unknown egg`)
		end
	end

	-- Waves
	local lastAt = -1
	for i, wave in config.Waves.waves do
		if wave.at <= lastAt or wave.at >= g.NIGHT_LENGTH then
			err(`wave {i} time {wave.at} must be increasing and inside the night`)
		end
		lastAt = wave.at
		for feralId, count in wave.ferals do
			if not config.Waves.ferals[feralId] then
				err(`wave {i} references unknown feral {feralId}`)
			elseif count <= 0 then
				err(`wave {i} has non-positive count for {feralId}`)
			end
		end
	end

	-- Products
	local seenProductIds: { [number]: string } = {}
	local placeholders = 0
	local function checkProduct(kind: string, def: { key: string, id: number, robux: number })
		if def.robux <= 0 then
			err(`{kind} {def.key} has no price`)
		end
		if def.id == 0 then
			placeholders += 1
		elseif seenProductIds[def.id] then
			err(`{kind} {def.key} reuses id {def.id} from {seenProductIds[def.id]}`)
		else
			seenProductIds[def.id] = def.key
		end
	end
	for _, def in config.Products.gamePasses do
		checkProduct("game pass", def)
	end
	for _, def in config.Products.devProducts do
		checkProduct("dev product", def)
	end
	if placeholders > 0 then
		table.insert(warnings, `{placeholders} product(s) still use placeholder id 0`)
	end

	return { errors = errors, warnings = warnings }
end

return Validate
