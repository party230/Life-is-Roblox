--!strict
-- Model library: Config/Species `model` key -> builder. Part-based builders today; mesh-based assets can be
-- slotted in here later without touching game logic (see docs/MESH_PIPELINE.md).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.Logic.Catalog)
local Placeholder = require(script.Placeholder)

local Characters = script.Characters

local builders: { [string]: () -> Model } = {}
for _, module in Characters:GetChildren() do
	if module:IsA("ModuleScript") then
		builders[module.Name] = require(module) :: any
	end
end

local Models = {}

function Models.has(modelKey: string?): boolean
	return modelKey ~= nil and builders[modelKey] ~= nil
end

-- Builds the base (Normal) model for a stored brainrot. Disabled, removed or unbuilt characters
-- become their rarity's mystery crate.
function Models.build(speciesId: string, rarity: string): Model
	local def = Catalog.resolve(speciesId, rarity)
	local builder = if def.model then builders[def.model] else nil
	local model
	if builder and not Catalog.isPlaceholder(def) then
		model = builder()
	else
		model = Placeholder(Config.Rarities.byId[def.rarity].color)
	end
	model.Name = def.displayName
	model:SetAttribute("SpeciesId", def.id)
	model:SetAttribute("Rarity", def.rarity)
	return model
end

return Models
