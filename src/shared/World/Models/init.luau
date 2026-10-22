--!strict
-- Model library: Config/Species `model` key -> a Model that satisfies the rig contract (docs/MODEL_CONTRACT.md).
--   "<id>"          part-based builder in Characters/<id>.luau (current)
--   "mesh:<name>"   imported Model at ReplicatedStorage.Assets.Brainrots.<name> (MeshParts), adopted into the rig
-- Swapping a character from part-built to mesh is a one-line change in Config/Species.luau; nothing else changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.Logic.Catalog)
local Kit = require(script.Kit)
local Placeholder = require(script.Placeholder)

local Characters = script.Characters

local builders: { [string]: () -> Model } = {}
for _, module in Characters:GetChildren() do
	if module:IsA("ModuleScript") then
		builders[module.Name] = require(module) :: any
	end
end

local Models = {}

local MESH_PREFIX = "mesh:"

local function meshTemplate(modelKey: string): Model?
	if string.sub(modelKey, 1, #MESH_PREFIX) ~= MESH_PREFIX then
		return nil
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Brainrots")
	local template = folder and folder:FindFirstChild(string.sub(modelKey, #MESH_PREFIX + 1))
	return if template and template:IsA("Model") then template else nil
end

function Models.has(modelKey: string?): boolean
	return modelKey ~= nil and (builders[modelKey] ~= nil or meshTemplate(modelKey) ~= nil)
end

-- Builds the base (Normal) model for a stored brainrot. Disabled, removed or unbuilt characters
-- become their rarity's mystery crate.
function Models.build(speciesId: string, rarity: string): Model
	local def = Catalog.resolve(speciesId, rarity)
	local builder = if def.model then builders[def.model] else nil
	local template = if def.model then meshTemplate(def.model) else nil
	local model
	local real = not Catalog.isPlaceholder(def)
	if real and builder then
		model = builder()
	elseif real and template then
		model = Kit.adopt(template:Clone())
	else
		model = Placeholder(Config.Rarities.byId[def.rarity].color)
	end
	model.Name = def.displayName
	model:SetAttribute("SpeciesId", def.id)
	model:SetAttribute("Rarity", def.rarity)
	return model
end

return Models
