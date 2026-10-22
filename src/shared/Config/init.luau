--!strict
-- Single entry point for all tunables. Usage: `local Config = require(ReplicatedStorage.Shared.Config)`.

local Food = require("@self/Food")
local Nursery = require("@self/Nursery")

export type FoodDef = Food.FoodDef
export type StageDef = Nursery.StageDef
export type StageId = Nursery.StageId

return table.freeze({
	Game = require("@self/Game"),
	Rarities = require("@self/Rarities"),
	Variants = require("@self/Variants"),
	Species = require("@self/Species"),
	Shop = require("@self/Shop"),
	Eggs = require("@self/Eggs"),
	Food = Food,
	Loyalty = require("@self/Loyalty"),
	Nursery = Nursery,
	Defences = require("@self/Defences"),
	Waves = require("@self/Waves"),
	Rotter = require("@self/Rotter"),
	Products = require("@self/Products"),
	Network = require("@self/Network"),
	Layout = require("@self/Layout"),
})
