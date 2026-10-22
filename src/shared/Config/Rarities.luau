--!strict
-- Rarity tiers. `weight` is the relative roll weight for a generic roll (eggs/shop may override).
-- `incomeMult` scales income; `carrySpeedMult` is the rarity part of the carry penalty (§4.3).
-- `shopPrice` is the conveyor-belt base price.

export type RarityId = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

export type RarityDef = {
	id: RarityId,
	order: number,
	weight: number,
	incomeMult: number,
	carrySpeedMult: number,
	shopPrice: number,
	color: string, -- hex; UI converts with Color3.fromHex
}

local list: { RarityDef } = {
	{
		id = "Common",
		order = 1,
		weight = 60,
		incomeMult = 1,
		carrySpeedMult = 1.0,
		shopPrice = 50,
		color = "#C8C8C8",
	},
	{
		id = "Uncommon",
		order = 2,
		weight = 25,
		incomeMult = 2.5,
		carrySpeedMult = 0.95,
		shopPrice = 200,
		color = "#5AC85A",
	},
	{
		id = "Rare",
		order = 3,
		weight = 10,
		incomeMult = 6,
		carrySpeedMult = 0.9,
		shopPrice = 1_000,
		color = "#468CFF",
	},
	{
		id = "Epic",
		order = 4,
		weight = 3.5,
		incomeMult = 15,
		carrySpeedMult = 0.85,
		shopPrice = 5_000,
		color = "#AA50FF",
	},
	{
		id = "Legendary",
		order = 5,
		weight = 1.2,
		incomeMult = 40,
		carrySpeedMult = 0.8,
		shopPrice = 25_000,
		color = "#FFB428",
	},
	{
		id = "Mythic",
		order = 6,
		weight = 0.25,
		incomeMult = 120,
		carrySpeedMult = 0.75,
		shopPrice = 150_000,
		color = "#FF466E",
	},
	{
		id = "Secret",
		order = 7,
		weight = 0.05,
		incomeMult = 400,
		carrySpeedMult = 0.7,
		shopPrice = 1_000_000,
		color = "#141414",
	},
}

local byId: { [string]: RarityDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
})
