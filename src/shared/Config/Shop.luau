--!strict
-- Conveyor belt shop in each base (§4.1). Stock rotates on a timer; prices come from Rarities.shopPrice.

local Shop = {
	ROTATION_SECONDS = 60, -- new stock every minute
	STOCK_SIZE = 5,
	PRICE_JITTER = 0.15, -- +/- fraction applied to rarity base price per listing
	-- Conveyor rolls its own rarity weights (cheaper/commoner than eggs).
	RARITY_WEIGHTS = table.freeze({
		Common = 70,
		Uncommon = 22,
		Rare = 6,
		Epic = 1.6,
		Legendary = 0.35,
		Mythic = 0.05,
		Secret = 0,
	}),
}

return table.freeze(Shop)
