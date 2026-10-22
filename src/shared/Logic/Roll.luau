--!strict
-- RNG for new brainrots: rarity -> species -> mutation. The RNG is injected for seeded tests.

local Config = require("../Config")
local Income = require("./Income")
local Types = require("../Types")
local WeightedRandom = require("../Util/WeightedRandom")

export type Rng = WeightedRandom.Rng

local Roll = {}

-- `luck` multiplies the weight of Rare and above (1 = no boost).
function Roll.rarity(weights: { [string]: number }, rng: Rng, luck: number?): Types.RarityId?
	local boosted: { [string]: number } = {}
	local mult = luck or 1
	for id, w in weights do
		local def = Config.Rarities.byId[id]
		boosted[id] = if def and def.order >= 3 then w * mult else w
	end
	return WeightedRandom.pickKey(boosted, rng) :: Types.RarityId?
end

function Roll.species(rarity: string, rng: Rng): string?
	local pool: { string } = {}
	for _, s in Config.Species.list do
		if s.rarity == rarity then
			table.insert(pool, s.id)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[math.clamp(math.floor(rng() * #pool) + 1, 1, #pool)]
end

function Roll.mutation(rng: Rng): Types.MutationId
	local picked = WeightedRandom.pickItem(Config.Mutations.list, function(m)
		return m.weight
	end, rng)
	return (if picked then picked.id else "None") :: Types.MutationId
end

-- Builds a fresh, unstolen brainrot record.
function Roll.newBrainrot(
	id: string,
	speciesId: string,
	mutation: Types.MutationId,
	ownerUserId: number,
	now: number
): Types.Brainrot
	local species = Config.Species.byId[speciesId]
	return {
		id = id,
		speciesId = speciesId,
		rarity = species.rarity,
		mutation = mutation,
		incomePerSec = Income.perSec(speciesId, mutation),
		ownerUserId = ownerUserId,
		originalOwnerUserId = nil,
		loyalty = 0,
		oldLoyalty = nil,
		acquiredAt = now,
		lastInteractedAt = now,
		isStolen = false,
		loyaltyTimeToday = 0,
		loyaltyDay = now // 86400,
		lowLoyaltySince = nil,
		bondCollared = false,
	}
end

return Roll
