--!strict
-- Starter species. PLACEHOLDER names/looks: final designs come from the Phase 1 concept sheet.
-- All species must be original (see DECISIONS.md, IP rule).
-- `incomeFactor` gives small per-species variation on top of rarity and mutation multipliers.

local Rarities = require("./Rarities")

export type SpeciesDef = {
	id: string,
	displayName: string,
	rarity: Rarities.RarityId,
	incomeFactor: number,
	blurb: string,
}

local list: { SpeciesDef } = {
	{
		id = "toastronaut",
		displayName = "Toastronaut",
		rarity = "Common",
		incomeFactor = 1.0,
		blurb = "A slice of toast in a fishbowl helmet. Afraid of butter.",
	},
	{
		id = "sockgoblin",
		displayName = "Sock Goblin",
		rarity = "Common",
		incomeFactor = 0.9,
		blurb = "Lives in the dryer. Steals exactly one sock per load.",
	},
	{
		id = "puddlepup",
		displayName = "Puddle Pup",
		rarity = "Common",
		incomeFactor = 1.1,
		blurb = "A dog made of rainwater. Shakes itself dry and vanishes briefly.",
	},
	{
		id = "fridgeasaurus",
		displayName = "Fridgeasaurus",
		rarity = "Uncommon",
		incomeFactor = 1.0,
		blurb = "Dinosaur with a fridge for a belly. The light stays on.",
	},
	{
		id = "noodlenaut",
		displayName = "Noodle Knight",
		rarity = "Uncommon",
		incomeFactor = 1.05,
		blurb = "Armour of dry pasta. Goes soft in the rain.",
	},
	{
		id = "cactuscoach",
		displayName = "Coach Cactus",
		rarity = "Rare",
		incomeFactor = 1.0,
		blurb = "Blows a whistle at everything. Hugs are not recommended.",
	},
	{
		id = "wobbleduck",
		displayName = "Wobble Duck",
		rarity = "Rare",
		incomeFactor = 1.1,
		blurb = "A jelly duck that wobbles when it quacks.",
	},
	{
		id = "lampshark",
		displayName = "Lamp Shark",
		rarity = "Epic",
		incomeFactor = 1.0,
		blurb = "Wears a lampshade fin. Brightens every room it bites.",
	},
	{
		id = "drumbonbon",
		displayName = "Drum Bonbon",
		rarity = "Epic",
		incomeFactor = 1.05,
		blurb = "A wrapped sweet that keeps a beat. Nobody knows who taught it.",
	},
	{
		id = "pianopotamus",
		displayName = "Pianopotamus",
		rarity = "Legendary",
		incomeFactor = 1.0,
		blurb = "A hippo whose teeth are piano keys. Only knows one song.",
	},
	{
		id = "cloudcroissant",
		displayName = "Cloud Croissant",
		rarity = "Mythic",
		incomeFactor = 1.0,
		blurb = "A flaky pastry that floats. Rains crumbs when sad.",
	},
	{
		id = "voidmuffin",
		displayName = "The Void Muffin",
		rarity = "Secret",
		incomeFactor = 1.0,
		blurb = "Looks like a muffin. Is not a muffin. Do not stare.",
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
