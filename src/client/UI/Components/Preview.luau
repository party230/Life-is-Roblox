--!strict
-- 3D preview of a brainrot in a ViewportFrame (shop cards, inspect panel, hatch reveal).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Models = require(ReplicatedStorage.Shared.World.Models)
local Variants = require(ReplicatedStorage.Shared.World.Variants)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

type Scope = Fusion.Scope<typeof(Fusion)>

local function Preview(
	scope: Scope,
	speciesId: string,
	rarity: string,
	variant: string,
	size: Vector2,
	sleepy: boolean?
): Instance
	local model = Models.build(speciesId, rarity)
	Variants.apply(model, variant)
	model:PivotTo(CFrame.Angles(0, math.rad(200), 0))
	-- frame the model from its bounding box
	local _, extents = model:GetBoundingBox()
	local h = math.max(extents.Y, extents.X * 0.7, extents.Z * 0.5)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(0, h * 0.62, -h * 2.6), Vector3.new(0, h * 0.48, 0))
	table.insert(scope, model)
	table.insert(scope, camera)
	local viewport = scope:New("ViewportFrame")({
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size.X, size.Y),
		Ambient = if sleepy then Color3.fromRGB(90, 95, 140) else Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -2, 1),
		CurrentCamera = camera,
	})
	model.Parent = viewport
	camera.Parent = viewport
	return viewport
end

return Preview
