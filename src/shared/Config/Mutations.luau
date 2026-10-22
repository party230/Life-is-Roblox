--!strict
-- Mutations roll once on hatch. "None" carries the leftover weight.
-- `scale` is the visual model scale; `carrySpeedMult` stacks with rarity (Tiny is easier to carry, Mega harder).

export type MutationId = "None" | "Golden" | "Glitched" | "Rainbow" | "Tiny" | "Mega"

export type MutationDef = {
	id: MutationId,
	weight: number,
	incomeMult: number,
	carrySpeedMult: number,
	scale: number,
}

local list: { MutationDef } = {
	{ id = "None", weight = 85, incomeMult = 1, carrySpeedMult = 1, scale = 1 },
	{ id = "Tiny", weight = 4, incomeMult = 0.8, carrySpeedMult = 1.1, scale = 0.6 },
	{ id = "Golden", weight = 5, incomeMult = 2, carrySpeedMult = 1, scale = 1 },
	{ id = "Mega", weight = 3, incomeMult = 1.5, carrySpeedMult = 0.85, scale = 1.6 },
	{ id = "Glitched", weight = 2, incomeMult = 3, carrySpeedMult = 1, scale = 1 },
	{ id = "Rainbow", weight = 1, incomeMult = 5, carrySpeedMult = 1, scale = 1 },
}

local byId: { [string]: MutationDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
})
