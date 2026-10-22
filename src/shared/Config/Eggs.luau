--!strict
-- Eggs are RNG hatches. Odds below are shown in the UI (required for paid random items, §6).
-- `robuxProductKey` links an egg to a dev product in Products.luau when it can be bought with Robux.

local Rarities = require("./Rarities")

export type EggDef = {
	id: string,
	displayName: string,
	cashPrice: number?, -- nil = not sold for cash
	robuxProductKey: string?,
	hatchSeconds: number,
	rarityWeights: { [Rarities.RarityId]: number },
}

local list: { EggDef } = {
	{
		id = "basic",
		displayName = "Basic Egg",
		cashPrice = 500,
		hatchSeconds = 30,
		rarityWeights = {
			Common = 60,
			Uncommon = 28,
			Rare = 9,
			Epic = 2.5,
			Legendary = 0.45,
			Mythic = 0.05,
			Secret = 0,
		},
	},
	{
		id = "fancy",
		displayName = "Fancy Egg",
		cashPrice = 10_000,
		hatchSeconds = 120,
		rarityWeights = {
			Common = 0,
			Uncommon = 50,
			Rare = 32,
			Epic = 13,
			Legendary = 4,
			Mythic = 0.9,
			Secret = 0.1,
		},
	},
	{
		id = "streak",
		displayName = "Streak Egg",
		hatchSeconds = 10,
		rarityWeights = {
			Common = 50,
			Uncommon = 30,
			Rare = 14,
			Epic = 5,
			Legendary = 1,
			Mythic = 0,
			Secret = 0,
		},
	},
	{
		id = "streak7",
		displayName = "Golden Streak Egg",
		hatchSeconds = 10,
		rarityWeights = {
			Common = 0,
			Uncommon = 40,
			Rare = 35,
			Epic = 18,
			Legendary = 6,
			Mythic = 1,
			Secret = 0,
		},
	},
}

local byId: { [string]: EggDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	DAILY_STREAK_EGG = "streak",
	DAILY_STREAK_BONUS_EGG = "streak7",
	DAILY_STREAK_BONUS_DAY = 7,
	-- incubators live in the nursery now: Config.Nursery.BASE_INCUBATORS + Extra Incubator passes
	OPEN_AT_NIGHT = false, -- buying closes at night; incubators keep running and can still hatch
})
