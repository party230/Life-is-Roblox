--!strict
-- Variants (replace the Phase 0 mutations). Any character can roll one. The base design never changes;
-- variants only add to it. Visual parameters are read by shared/World/Variants.

export type VariantId = "Normal" | "Rainbow" | "Evil"

export type VariantDef = {
	id: VariantId,
	displayName: string, -- shown above the name on nameplates ("" = hidden)
	weight: number, -- roll weight
	incomeMult: number,
	priceMult: number, -- carpet price multiplier
	nameColor: string, -- nameplate colour for the variant line
}

-- D36: Gold and Diamond were removed (their odds went to Normal) and Dark became Evil.
local list: { VariantDef } = {
	{ id = "Normal", displayName = "", weight = 98, incomeMult = 1, priceMult = 1, nameColor = "#FFFFFF" },
	{
		id = "Rainbow",
		displayName = "Rainbow",
		weight = 1.6,
		incomeMult = 4,
		priceMult = 4,
		nameColor = "#FF8FE5",
	},
	{ id = "Evil", displayName = "Evil", weight = 0.4, incomeMult = 6, priceMult = 6, nameColor = "#FF3B3B" },
}

local byId: { [string]: VariantDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	-- Rainbow: parts are split top-to-bottom into these bands, which scroll upward in game.
	RAINBOW_BANDS = table.freeze({
		"#FF3B3B",
		"#FF9A1F",
		"#FFE23D",
		"#3EE05A",
		"#2FA8FF",
		"#8B5CFF",
		"#FF5CD6",
	}),
	RAINBOW_CYCLE_SECONDS = 2.8, -- one full trip of a colour through all bands
	-- Evil: black body, glowing red eyes, red lightning crackling around it.
	EVIL_PALETTE = table.freeze({ "#050507", "#0E0E12", "#18181E" }),
	EVIL_EYE_COLOR = "#FF1E1E",
	EVIL_PUPIL_COLOR = "#FFC4C4",
	EVIL_BOLT_COLOR = "#FF2A2A",
	EVIL_BOLTS = 3, -- bolts visible at once
	EVIL_BOLT_INTERVAL = table.freeze({ 0.08, 0.22 }), -- seconds between re-strikes (random in range)
	-- Slice only: boosted variant odds on the carpet so every variant shows up while playtesting.
	SLICE_WEIGHTS = table.freeze({ Normal = 60, Rainbow = 20, Evil = 20 }),
})
