--!strict
-- The 12 starter species (approved in Phase 1). Each is an everyday object + an animal + a face.
-- All names and designs are original. A trademark/store-name check is on the Phase 10 checklist.
-- `incomeFactor` gives small per-species variation on top of rarity and mutation multipliers.
-- `color` / `accent` drive the placeholder in-world models until final art lands.

local Rarities = require("./Rarities")

export type SpeciesDef = {
	id: string,
	displayName: string,
	rarity: Rarities.RarityId,
	incomeFactor: number,
	blurb: string,
	color: string, -- hex, main body
	accent: string, -- hex, secondary
}

local list: { SpeciesDef } = {
	{
		id = "mugpup",
		displayName = "Mugpup",
		rarity = "Common",
		incomeFactor = 1.0,
		blurb = "Wags its handle so hard it spills. Every single time.",
		color = "#FFF4E0",
		accent = "#B5763C",
	},
	{
		id = "toasturtle",
		displayName = "Toasturtle",
		rarity = "Common",
		incomeFactor = 0.9,
		blurb = "Pops out toast when startled. Is startled constantly.",
		color = "#CFD8E3",
		accent = "#7BD957",
	},
	{
		id = "sockodile",
		displayName = "Sockodile",
		rarity = "Common",
		incomeFactor = 1.1,
		blurb = "Escaped the dryer. Still holds a grudge against laundry day.",
		color = "#F7F4EE",
		accent = "#FF4D4D",
	},
	{
		id = "lampingo",
		displayName = "Lampingo",
		rarity = "Uncommon",
		incomeFactor = 1.0,
		blurb = "Balances on one leg and lights up whenever it has an idea.",
		color = "#FF8FB1",
		accent = "#FFD23F",
	},
	{
		id = "brollybun",
		displayName = "Brollybun",
		rarity = "Uncommon",
		incomeFactor = 1.05,
		blurb = "Opens its ears when it rains. Refuses to go anywhere when it doesn't.",
		color = "#FFFFFF",
		accent = "#4DA3FF",
	},
	{
		id = "fridgehog",
		displayName = "Fridgehog",
		rarity = "Rare",
		incomeFactor = 1.0,
		blurb = "Collects fridge magnets as spikes. Gives very cold hugs.",
		color = "#C9F2E3",
		accent = "#FF4D4D",
	},
	{
		id = "kettlephant",
		displayName = "Kettlephant",
		rarity = "Rare",
		incomeFactor = 1.1,
		blurb = "Whistles when it's happy. Steams when it's ignored.",
		color = "#5FC3C8",
		accent = "#FFD23F",
	},
	{
		id = "cartshark",
		displayName = "Cartshark",
		rarity = "Epic",
		incomeFactor = 1.0,
		blurb = "Circles the aisles. Always picks the trolley with the wonky wheel.",
		color = "#B9C3D6",
		accent = "#6E8CB3",
	},
	{
		id = "owlarm",
		displayName = "Owlarm",
		rarity = "Epic",
		incomeFactor = 1.05,
		blurb = "Hoots at 6:00 sharp. Every day. Nobody asked.",
		color = "#FF8A3D",
		accent = "#FFD23F",
	},
	{
		id = "pianoceros",
		displayName = "Pianoceros",
		rarity = "Legendary",
		incomeFactor = 1.0,
		blurb = "Charges at wrong notes. Will only play in C major.",
		color = "#2E2A3F",
		accent = "#FFF4E0",
	},
	{
		id = "spinwhale",
		displayName = "Spinwhale",
		rarity = "Mythic",
		incomeFactor = 1.0,
		blurb = "Sings during the spin cycle. Everything nearby smells of lavender.",
		color = "#4DA3FF",
		accent = "#E6EEF7",
	},
	{
		id = "tellama",
		displayName = "Tellama",
		rarity = "Secret",
		incomeFactor = 1.0,
		blurb = "Only shows reruns. Spits static if you change the channel.",
		color = "#F5E6C8",
		accent = "#3DDC84",
	},
}

local byId: { [string]: SpeciesDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
})
