--!strict
-- Single entry point for all tunables. Usage: `local Config = require(ReplicatedStorage.Shared.Config)`.

return table.freeze({
	Game = require("@self/Game"),
	Rarities = require("@self/Rarities"),
	Mutations = require("@self/Mutations"),
	Species = require("@self/Species"),
	Shop = require("@self/Shop"),
	Eggs = require("@self/Eggs"),
	Defences = require("@self/Defences"),
	Waves = require("@self/Waves"),
	Rotter = require("@self/Rotter"),
	Products = require("@self/Products"),
	Network = require("@self/Network"),
})
