--!strict
-- Placeholder in-world brainrot: a chunky body in the species colours with a face, plus a name tag.
-- Replaced by real models once art lands; everything else only relies on Model + PrimaryPart.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Income = require(ReplicatedStorage.Shared.Logic.Income)
local Parts = require(script.Parent.Parts)

local BrainrotModel = {}

local MUTATION_LOOK: { [string]: { color: string?, material: Enum.Material? } } = {
	Golden = { color = "#F2B400", material = Enum.Material.Foil },
	Rainbow = { color = "#FF5C8A", material = Enum.Material.Neon },
	Glitched = { material = Enum.Material.ForceField },
}

export type Options = {
	showIncome: boolean?,
	tag: string?, -- extra line under the name (e.g. a price)
}

-- Builds the model with its feet at the origin, facing -Z. Call :PivotTo() to place it.
function BrainrotModel.build(speciesId: string, mutation: string, opts: Options?): Model
	local options: Options = opts or {}
	local species = Config.Species.byId[speciesId]
	local rarity = Config.Rarities.byId[species.rarity]
	local look = MUTATION_LOOK[mutation]

	local model = Instance.new("Model")
	model.Name = species.displayName

	local bodyColor = if look and look.color then look.color else species.color
	local body = Parts.part({
		name = "Body",
		size = Vector3.new(2.6, 2.6, 2.6),
		cframe = CFrame.new(0, 1.6, 0),
		color = bodyColor,
		material = if look then look.material else nil,
		parent = model,
	})
	Parts.part({
		name = "Band",
		size = Vector3.new(2.7, 0.6, 2.7),
		cframe = CFrame.new(0, 0.9, 0),
		color = species.accent,
		parent = model,
	})
	for _, side in { -1, 1 } do
		Parts.part({
			name = "Eye",
			size = Vector3.new(0.8, 0.8, 0.8),
			cframe = CFrame.new(side * 0.55, 2.0, -1.25),
			color = "#FFFFFF",
			shape = Enum.PartType.Ball,
			canCollide = false,
			parent = model,
		})
		Parts.part({
			name = "Pupil",
			size = Vector3.new(0.4, 0.4, 0.4),
			cframe = CFrame.new(side * 0.55, 2.0, -1.6),
			color = "#1B1530",
			shape = Enum.PartType.Ball,
			canCollide = false,
			parent = model,
		})
	end
	Parts.part({
		name = "FootL",
		size = Vector3.new(0.9, 0.3, 1.1),
		cframe = CFrame.new(-0.7, 0.15, -0.2),
		color = species.accent,
		parent = model,
	})
	Parts.part({
		name = "FootR",
		size = Vector3.new(0.9, 0.3, 1.1),
		cframe = CFrame.new(0.7, 0.15, -0.2),
		color = species.accent,
		parent = model,
	})

	model.PrimaryPart = body
	model.WorldPivot = CFrame.new(0, 0, 0)

	local lines = { species.displayName }
	if options.showIncome ~= false then
		table.insert(lines, Format.perSec(Income.perSec(speciesId, mutation)))
	end
	if options.tag then
		table.insert(lines, options.tag)
	end
	local _, labels = Parts.billboard(body, 2.8, lines, Vector2.new(6, 1.2 * #lines))
	labels[1].TextColor3 = Color3.fromHex(if rarity.style == "rainbowRim" then "#B98CFF" else rarity.color)
	if labels[2] and options.showIncome ~= false then
		labels[2].TextColor3 = Color3.fromHex("#7CFF9B")
	end

	if mutation == "Tiny" then
		model:ScaleTo(0.65)
	elseif mutation == "Mega" then
		model:ScaleTo(1.4)
	end
	return model
end

return BrainrotModel
