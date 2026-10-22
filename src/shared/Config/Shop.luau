--!strict
-- The shared red-carpet conveyor in the hub (D38): one central portal, one carpet loop for everyone, first to
-- buy wins. Prices come from Rarities.shopPrice x variant.

local Shop = {
	CARPET_SPAWN_SECONDS = 3, -- a brainrot steps out of the portal this often (Day and Dusk)
	CARPET_WALK_SPEED = 5, -- studs per second along the carpet (portal -> loop -> exit vortex, ~44 s)
	CARPET_MAX_ITEMS = 16,
	CARPET_UPDATE_HZ = 30, -- server position updates for walking brainrots
	BUY_RADIUS = 16, -- studs: buying from the Shop panel still needs you at the carpet
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
	OPEN_AT_NIGHT = false, -- the carpet closes for Night and the dawn vote (runaways still walk it)
	-- Rare+ spawns get a server-wide banner over the portal (the old plaza drop now lives on the carpet).
	ANNOUNCE_MIN_RARITY_ORDER = 3, -- Rare
	ANNOUNCE_SECONDS = 6,
	-- Featured spawn: every few minutes of Day a guaranteed Rare+ steps onto the carpet.
	FEATURED_INTERVAL = 180,
	FEATURED_PRICE_MULT = 1.0,
	FEATURED_RARITY_WEIGHTS = table.freeze({
		Common = 0,
		Uncommon = 0,
		Rare = 70,
		Epic = 22,
		Legendary = 7,
		Mythic = 1,
		Secret = 0,
	}),
	RUNAWAY_PRICE_MULT = 1.0, -- a runaway on the carpet costs what a fresh one would
}

return table.freeze(Shop)
