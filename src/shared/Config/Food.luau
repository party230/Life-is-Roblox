--!strict
-- Food shop (D39, owner's table). Food is a deliberate cash sink: keep this price scale when balancing.
-- Each feed adds its timer days (stacking, capped at Loyalty.MAX_TIMER_DAYS), loyalty and growth points.
-- Foods 1-9 are cash only; 10-14 cash or Robux; 15-18 Robux only (dev products, x1 or x5 bundles).
-- Rename freely: logic and saves use the ids.

export type Tab = "Snacks" | "Meals" | "Feasts" | "Premium"

export type FoodDef = {
	id: string,
	displayName: string,
	tab: Tab,
	cash: number?, -- nil = not sold for cash
	robux: number?, -- nil = not sold for Robux (dev product per bundle, see Products)
	days: number, -- runaway timer added, in in-game days
	fillsTimer: boolean?, -- fills the timer to the cap instead
	loyalty: number, -- loyalty added
	maxLoyalty: boolean?, -- sets loyalty to the max instead
	growth: number, -- growth points added
	instantAdult: boolean?, -- grows straight to Adult instead
}

local function F(
	id: string,
	displayName: string,
	tab: Tab,
	cash: number?,
	robux: number?,
	days: number,
	loyalty: number,
	growth: number
): FoodDef
	return {
		id = id,
		displayName = displayName,
		tab = tab,
		cash = cash,
		robux = robux,
		days = days,
		loyalty = loyalty,
		growth = growth,
	}
end

local list: { FoodDef } = {
	F("breadstick", "Stale Breadstick", "Snacks", 50, nil, 0.25, 1, 1),
	F("olive", "Olive Snack", "Snacks", 150, nil, 0.5, 2, 2),
	F("crust", "Pizza Crust", "Snacks", 400, nil, 0.75, 3, 3),
	F("slice", "Pizza Slice", "Snacks", 1_000, nil, 1, 4, 4),
	F("knots", "Garlic Knots", "Meals", 2_500, nil, 1.5, 6, 6),
	F("spaghetti", "Spaghetti Bowl", "Meals", 6_000, nil, 2, 8, 8),
	F("sub", "Meatball Sub", "Meals", 12_000, nil, 2.5, 10, 10),
	F("lasagna", "Lasagna Brick", "Meals", 25_000, nil, 3, 12, 13),
	F("risotto", "Risotto Pot", "Meals", 50_000, nil, 4, 15, 16),
	F("gelato", "Gelato Tower", "Feasts", 100_000, 2, 5, 18, 20),
	F("tiramisu", "Tiramisu Slab", "Feasts", 200_000, 3, 7, 22, 25),
	F("cannolo", "Golden Cannolo", "Feasts", 450_000, 5, 10, 28, 32),
	F("truffle", "Truffle Pasta", "Feasts", 1_000_000, 7, 14, 35, 40),
	F("banquet", "Banquet Platter", "Feasts", 2_500_000, 10, 20, 45, 55),
	F("crate", "Snack Crate", "Premium", nil, 285, 5, 20, 20),
	F("royal", "Royal Feast", "Premium", nil, 735, 14, 40, 45),
	F("espresso", "Cosmic Espresso", "Premium", nil, 1_485, 30, 0, 80),
	F("nonna", "Nonna's Secret Recipe", "Premium", nil, 2_985, 0, 0, 0),
}
list[17].maxLoyalty = true -- Cosmic Espresso
list[18].fillsTimer = true -- Nonna's Secret Recipe: timer to the cap, max loyalty, instant Adult
list[18].maxLoyalty = true
list[18].instantAdult = true

local TABS: { Tab } = { "Snacks", "Meals", "Feasts", "Premium" }

local byId: { [string]: FoodDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	TABS = table.freeze(TABS),
	CASH_QUANTITIES = table.freeze({ 1, 5, 10 }),
	ROBUX_QUANTITIES = table.freeze({ 1, 5 }),
	ROBUX_BUNDLE_DISCOUNT = 0.1, -- the x5 Robux bundle costs 10% less than five singles (owner answer 1)
	FEED_MAX_QUANTITY = 50, -- per feed action
	INVENTORY_CAP = 9_999, -- per food
	-- "Best for you" badge (owner answer 5): the priciest cash food costing at most this many seconds of income.
	BEST_FOR_YOU_INCOME_SECONDS = 600,
})
