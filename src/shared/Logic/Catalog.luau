--!strict
-- Resolves character ids to their config rows. Game logic goes through here, never through names (D21).
-- A disabled or removed character resolves to its rarity's placeholder, so saves never break.

local Config = require("../Config")

export type SpeciesDef = typeof(Config.Species.list[1])

local Catalog = {}

-- The def to show/earn with for an owned brainrot. `rarity` is the rarity stored on the record.
function Catalog.resolve(speciesId: string, rarity: string): SpeciesDef
	local def = Config.Species.byId[speciesId]
	if def and not def.disabled then
		return def
	end
	return Config.Species.placeholders[rarity] or Config.Species.placeholders.Common
end

function Catalog.isPlaceholder(def: SpeciesDef): boolean
	return def.model == "placeholder"
end

-- Can this character appear on carpets, in eggs or in drops?
function Catalog.isSpawnable(def: SpeciesDef): boolean
	if def.disabled then
		return false
	end
	if Config.Game.REQUIRE_BUILT_MODELS and def.model == nil then
		return false
	end
	return true
end

function Catalog.spawnable(rarity: string?): { SpeciesDef }
	local out: { SpeciesDef } = {}
	for _, def in Config.Species.list do
		if Catalog.isSpawnable(def) and (rarity == nil or def.rarity == rarity) then
			table.insert(out, def)
		end
	end
	return out
end

-- Rarity weights with unspawnable rarities removed (so rolls never land on an empty rarity).
function Catalog.filterWeights(weights: { [string]: number }): { [string]: number }
	local out: { [string]: number } = {}
	for rarity, w in weights do
		if w > 0 and #Catalog.spawnable(rarity) > 0 then
			out[rarity] = w
		end
	end
	return out
end

return Catalog
