--!strict
-- RNG for new brainrots: rarity -> character -> variant. The RNG is injected for seeded tests.
-- Only spawnable characters can roll (not disabled, and modelled while REQUIRE_BUILT_MODELS is on).

local Config = require("../Config")
local Catalog = require("./Catalog")
local Income = require("./Income")
local Types = require("../Types")
local WeightedRandom = require("../Util/WeightedRandom")

export type Rng = WeightedRandom.Rng

local Roll = {}

-- `luck` multiplies the weight of Rare and above (1 = no boost). Rarities with nothing spawnable are skipped.
function Roll.rarity(weights: { [string]: number }, rng: Rng, luck: number?): string?
	local boosted: { [string]: number } = {}
	local mult = luck or 1
	for id, w in Catalog.filterWeights(weights) do
		local def = Config.Rarities.byId[id]
		boosted[id] = if def and def.order >= 3 then w * mult else w
	end
	return WeightedRandom.pickKey(boosted, rng)
end

local function pick<T>(list: { T }, rng: Rng): T?
	if #list == 0 then
		return nil
	end
	return list[math.clamp(math.floor(rng() * #list) + 1, 1, #list)]
end

function Roll.species(rarity: string, rng: Rng): string?
	local def = pick(Catalog.spawnable(rarity), rng)
	return if def then def.id else nil
end

-- Any spawnable character, uniformly (vertical slice carpet).
function Roll.anySpecies(rng: Rng): string?
	local def = pick(Catalog.spawnable(), rng)
	return if def then def.id else nil
end

function Roll.variant(rng: Rng, weights: { [string]: number }?): Types.VariantId
	local w: { [string]: number } = {}
	if weights then
		w = weights
	else
		for _, v in Config.Variants.list do
			w[v.id] = v.weight
		end
	end
	return (WeightedRandom.pickKey(w, rng) or "Normal") :: Types.VariantId
end

-- Builds a fresh, unstolen brainrot record (an Adult with the minimum runaway timer and starting loyalty).
function Roll.newBrainrot(
	id: string,
	speciesId: string,
	variant: Types.VariantId,
	ownerUserId: number,
	now: number
): Types.Brainrot
	local species = Config.Species.byId[speciesId]
	return {
		id = id,
		speciesId = speciesId,
		rarity = species.rarity,
		variant = variant,
		incomePerSec = Income.perSec(speciesId, variant, species.rarity),
		ownerUserId = ownerUserId,
		originalOwnerUserId = nil,
		loyalty = Config.Loyalty.START,
		oldLoyalty = nil,
		acquiredAt = now,
		lastInteractedAt = now,
		isStolen = false,
		lowLoyaltySince = nil,
		bondCollared = false,
		timerDays = Config.Loyalty.TIMER_MIN_DAYS,
		timerFullDays = Config.Loyalty.TIMER_MIN_DAYS,
		leaving = false,
		sinceFedDays = 0,
		growth = Config.Nursery.ADULT_GROWTH, -- bought brainrots are Adults; hatching sets 0 (Baby)
		inNursery = false,
	}
end

return Roll
