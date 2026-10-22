--!strict
-- Robux products (§6). IDs are PLACEHOLDERS (0): create the real ones in the Creator Dashboard and paste here.
-- `robux` is the intended price, for reference/validation only (the Dashboard price is authoritative).

export type GamePassDef = {
	key: string,
	id: number,
	robux: number,
}

export type DevProductDef = {
	key: string,
	id: number,
	robux: number,
	isRandomItem: boolean, -- true => show odds + check PolicyService.ArePaidRandomItemsRestricted
}

local gamePasses: { GamePassDef } = {
	{ key = "DoubleIncome", id = 0, robux = 249 },
	{ key = "ExtraSlots1", id = 0, robux = 149 },
	{ key = "ExtraSlots2", id = 0, robux = 149 },
	{ key = "ExtraSlots3", id = 0, robux = 149 },
	{ key = "AutoCollect", id = 0, robux = 249 },
	{ key = "VIP", id = 0, robux = 99 },
	{ key = "BondCollar", id = 0, robux = 199 }, -- pauses the runaway timer on up to 2 brainrots (D39)
	-- Extra nursery incubators (D39): 3 tiers, +1 incubator each
	{ key = "ExtraIncubator1", id = 0, robux = 99 },
	{ key = "ExtraIncubator2", id = 0, robux = 149 },
	{ key = "ExtraIncubator3", id = 0, robux = 199 },
}

local devProducts: { DevProductDef } = {
	{ key = "Shield5", id = 0, robux = 25, isRandomItem = false },
	{ key = "Shield15", id = 0, robux = 59, isRandomItem = false },
	{ key = "Shield30", id = 0, robux = 99, isRandomItem = false },
	{ key = "InstantHatch", id = 0, robux = 15, isRandomItem = false },
	{ key = "GrowSkip", id = 0, robux = 49, isRandomItem = false },
	{ key = "LuckyBoostSmall", id = 0, robux = 39, isRandomItem = false },
	{ key = "LuckyBoostLarge", id = 0, robux = 99, isRandomItem = false },
	{ key = "ServerLuck1", id = 0, robux = 99, isRandomItem = false },
	{ key = "ServerLuck2", id = 0, robux = 249, isRandomItem = false },
	{ key = "ServerLuck3", id = 0, robux = 499, isRandomItem = false },
	{ key = "NurseryUnlock", id = 0, robux = 99, isRandomItem = false }, -- skip the nursery's cash unlock (D39)
	{ key = "NightRevive", id = 0, robux = 20, isRandomItem = false },
	-- Dev product, not a game pass: passes are permanent but the Rot Pass is bought per 30-day season.
	{ key = "RotPassPremium", id = 0, robux = 399, isRandomItem = false },
}

-- Robux foods (D39): one dev product per food and bundle size; x5 bundles are 10% off (Config/Food).
local Food = require("./Food")
for _, food in Food.list do
	local robux = food.robux
	if robux then
		for _, bundle in Food.ROBUX_QUANTITIES do
			table.insert(devProducts, {
				key = `Food_{food.id}_{bundle}`,
				id = 0,
				robux = if bundle <= 1
					then robux
					else math.floor(robux * bundle * (1 - Food.ROBUX_BUNDLE_DISCOUNT)),
				isRandomItem = false,
			})
		end
	end
end

local passByKey: { [string]: GamePassDef } = {}
for _, def in gamePasses do
	passByKey[def.key] = table.freeze(def)
end
local productByKey: { [string]: DevProductDef } = {}
for _, def in devProducts do
	productByKey[def.key] = table.freeze(def)
end

return table.freeze({
	gamePasses = table.freeze(gamePasses),
	devProducts = table.freeze(devProducts),
	passByKey = table.freeze(passByKey),
	productByKey = table.freeze(productByKey),

	-- Effects
	DOUBLE_INCOME_MULT = 2,
	EXTRA_SLOTS_PER_TIER = 2,
	AUTO_COLLECT_OFFLINE_CAP_MULT = 2,
	BOND_COLLAR_MAX_BRAINROTS = 2,
	SHIELD_MINUTES = table.freeze({ Shield5 = 5, Shield15 = 15, Shield30 = 30 }),
	LUCK_BOOST_MINUTES = 15,
	LUCK_BOOST_MULT = table.freeze({ LuckyBoostSmall = 1.5, LuckyBoostLarge = 2 }),
	SERVER_LUCK_MULT = table.freeze({ ServerLuck1 = 1.5, ServerLuck2 = 2, ServerLuck3 = 3 }),
	INCUBATOR_PASSES = table.freeze({ "ExtraIncubator1", "ExtraIncubator2", "ExtraIncubator3" }),
	PRIVATE_SERVER_ROBUX = 100, -- configured in Creator Dashboard, listed for reference
	ROT_PASS_SEASON_DAYS = 30,
})
