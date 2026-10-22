--!strict
-- Conveyor belt shop in each base (§4.1). Stock rotates on a timer; prices come from Rarities.shopPrice.

local Shop = {
	-- Red carpet conveyor: a brainrot steps out of the base's spawn portal every CARPET_SPAWN_SECONDS and walks
	-- to the far end over CARPET_WALK_SECONDS. Buy it on the way (ProximityPrompt or the Shop panel).
	CARPET_SPAWN_SECONDS = 4,
	CARPET_WALK_SECONDS = 28,
	CARPET_MAX_ITEMS = 8,
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
	OPEN_AT_NIGHT = false, -- belt closes for Night and the dawn vote; defences are sold from the Defend menu
	-- Server-wide plaza drop: every few minutes of Day a Rare+ appears on the plaza belt. First to buy wins.
	PLAZA_DROP_INTERVAL = 180,
	PLAZA_DROP_DURATION = 60,
	PLAZA_DROP_BUY_RADIUS = 14, -- studs from the plaza belt
	PLAZA_DROP_PRICE_MULT = 1.0,
	PLAZA_DROP_RARITY_WEIGHTS = table.freeze({
		Common = 0,
		Uncommon = 0,
		Rare = 70,
		Epic = 22,
		Legendary = 7,
		Mythic = 1,
		Secret = 0,
	}),
}

return table.freeze(Shop)
