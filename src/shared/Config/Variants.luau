--!strict
-- Variants (replace the Phase 0 mutations). Any character can roll one. The base design never changes;
-- variants only add to it. Visual parameters are read by shared/World/Variants.

export type VariantId = "Normal" | "Gold" | "Diamond" | "Rainbow" | "Dark"

export type VariantDef = {
	id: VariantId,
	displayName: string, -- shown above the name on nameplates ("" = hidden)
	weight: number, -- roll weight
	incomeMult: number,
	priceMult: number, -- carpet price multiplier
	nameColor: string, -- nameplate colour for the variant line
}

local list: { VariantDef } = {
	{ id = "Normal", displayName = "", weight = 82, incomeMult = 1, priceMult = 1, nameColor = "#FFFFFF" },
	{
		id = "Gold",
		displayName = "Gold",
		weight = 11,
		incomeMult = 1.5,
		priceMult = 1.5,
		nameColor = "#FFD23F",
	},
	{
		id = "Diamond",
		displayName = "Diamond",
		weight = 5,
		incomeMult = 2,
		priceMult = 2,
		nameColor = "#8FE3FF",
	},
	{
		id = "Rainbow",
		displayName = "Rainbow",
		weight = 1.6,
		incomeMult = 4,
		priceMult = 4,
		nameColor = "#FF8FE5",
	},
	{ id = "Dark", displayName = "Dark", weight = 0.4, incomeMult = 6, priceMult = 6, nameColor = "#B15CFF" },
}

local byId: { [string]: VariantDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	-- Visual tuning
	GOLD_COLOR = "#E8B530",
	DIAMOND_COLOR = "#9EE6FF",
	DARK_PALETTE = { "#14101F", "#2A1740", "#3B1F5C" },
	DARK_EYE_COLOR = "#FF2A2A",
	RAINBOW_CYCLE_SECONDS = 3,
	-- Slice only: boosted variant odds on the carpet so every variant shows up while playtesting.
	SLICE_WEIGHTS = table.freeze({ Normal = 40, Gold = 15, Diamond = 15, Rainbow = 15, Dark = 15 }),
})
