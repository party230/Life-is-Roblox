--!strict
-- 3D preview of a brainrot in a ViewportFrame (shop cards, inspect panel, hatch reveal).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotModel = require(ReplicatedStorage.Shared.World.BrainrotModel)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

type Scope = Fusion.Scope<typeof(Fusion)>

local function Preview(
	scope: Scope,
	speciesId: string,
	mutation: string,
	size: Vector2,
	sleepy: boolean?
): Instance
	local model = BrainrotModel.build(speciesId, mutation, { showIncome = false })
	local label = model:FindFirstChild("Label", true)
	if label then
		label:Destroy()
	end
	model:PivotTo(CFrame.Angles(0, math.rad(200), 0))
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 2.6, -11), Vector3.new(0, 1.6, 0))
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
