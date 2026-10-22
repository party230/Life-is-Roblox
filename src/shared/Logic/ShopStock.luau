--!strict
-- What walks out onto the red carpet (and the plaza drop). One listing per brainrot on the carpet.

local Config = require("../Config")
local Income = require("./Income")
local Roll = require("./Roll")

export type Listing = {
	id: string,
	speciesId: string,
	variant: string, -- Types.VariantId
	rarity: string, -- Types.RarityId
	price: number,
	incomePerSec: number,
	sold: boolean,
}

local ShopStock = {}

-- Rounds a price to 2 significant figures in steps of 5 or 50: 1043 -> 1050, 26180 -> 26000.
function ShopStock.nicePrice(n: number): number
	if n <= 0 then
		return 0
	end
	local magnitude = 10 ^ math.max(0, math.floor(math.log10(n)) - 1)
	local step = magnitude * 0.5
	if n < 100 then
		step = 5
	end
	return math.max(step, math.floor(n / step + 0.5) * step)
end

function ShopStock.priceFor(rarity: string, variant: string, rng: Roll.Rng, mult: number?): number
	local base = Config.Rarities.byId[rarity].shopPrice * (mult or 1)
	local v = Config.Variants.byId[variant] or Config.Variants.byId.Normal
	local jitter = (rng() * 2 - 1) * Config.Shop.PRICE_JITTER
	return ShopStock.nicePrice(base * v.priceMult * (1 + jitter))
end

-- A listing for a given character and variant (also used for runaways rejoining the carpet).
function ShopStock.listingFor(
	id: string,
	speciesId: string,
	variant: string,
	rng: Roll.Rng,
	mult: number?
): Listing
	local rarity = Config.Species.byId[speciesId].rarity
	return {
		id = id,
		speciesId = speciesId,
		variant = variant,
		rarity = rarity,
		price = ShopStock.priceFor(rarity, variant, rng, mult),
		incomePerSec = Income.perSec(speciesId, variant, rarity),
		sold = false,
	}
end

-- Next brainrot for a carpet. In the vertical slice every modelled character is equally likely and
-- variants use boosted showcase odds.
function ShopStock.carpetListing(rng: Roll.Rng, id: string, luck: number?): Listing?
	local speciesId: string?
	local variant
	if Config.Game.VERTICAL_SLICE then
		speciesId = Roll.anySpecies(rng)
		variant = Roll.variant(rng, Config.Variants.SLICE_WEIGHTS)
	else
		local rarity = Roll.rarity(Config.Shop.RARITY_WEIGHTS, rng, luck)
		speciesId = rarity and Roll.species(rarity, rng)
		variant = Roll.variant(rng)
	end
	if not speciesId then
		return nil
	end
	return ShopStock.listingFor(id, speciesId, variant, rng)
end

-- Featured spawn: a guaranteed Rare+ (the old plaza drop, now on the shared carpet).
function ShopStock.featured(rng: Roll.Rng, id: string): Listing?
	local rarity = Roll.rarity(Config.Shop.FEATURED_RARITY_WEIGHTS, rng)
	local speciesId = rarity and Roll.species(rarity, rng)
	if not speciesId then
		return nil
	end
	return ShopStock.listingFor(id, speciesId, Roll.variant(rng), rng, Config.Shop.FEATURED_PRICE_MULT)
end

return ShopStock
