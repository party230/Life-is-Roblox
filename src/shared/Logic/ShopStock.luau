--!strict
-- Conveyor belt stock. Belt items carry no mutation (mutations come from eggs) so prices stay predictable.

local Config = require("../Config")
local Income = require("./Income")
local Roll = require("./Roll")

export type Listing = {
	id: string,
	speciesId: string,
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

function ShopStock.priceFor(rarity: string, rng: Roll.Rng, mult: number?): number
	local base = Config.Rarities.byId[rarity].shopPrice * (mult or 1)
	local jitter = (rng() * 2 - 1) * Config.Shop.PRICE_JITTER
	return ShopStock.nicePrice(base * (1 + jitter))
end

-- `idPrefix` keeps listing ids unique across rotations (e.g. the rotation number).
function ShopStock.generate(rng: Roll.Rng, idPrefix: string, luck: number?): { Listing }
	local out: { Listing } = {}
	for i = 1, Config.Shop.STOCK_SIZE do
		local rarity: string = Roll.rarity(Config.Shop.RARITY_WEIGHTS, rng, luck) or "Common"
		local speciesId = Roll.species(rarity, rng)
		if speciesId then
			table.insert(out, {
				id = `{idPrefix}-{i}`,
				speciesId = speciesId,
				rarity = rarity,
				price = ShopStock.priceFor(rarity, rng),
				incomePerSec = Income.perSec(speciesId, "None"),
				sold = false,
			})
		end
	end
	return out
end

function ShopStock.plazaDrop(rng: Roll.Rng, id: string): Listing?
	local rolled = Roll.rarity(Config.Shop.PLAZA_DROP_RARITY_WEIGHTS, rng)
	if not rolled then
		return nil
	end
	local rarity: string = rolled
	local speciesId = Roll.species(rarity, rng)
	if not speciesId then
		return nil
	end
	return {
		id = id,
		speciesId = speciesId,
		rarity = rarity,
		price = ShopStock.priceFor(rarity, rng, Config.Shop.PLAZA_DROP_PRICE_MULT),
		incomePerSec = Income.perSec(speciesId, "None"),
		sold = false,
	}
end

return ShopStock
