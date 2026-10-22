--!strict
-- The free Bonk bat everyone carries (style reference). Phase 3 adds the actual bonk (drop a carried brainrot);
-- for now it equips and swings using the default Animate script's "Slash" tool animation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Bat = {}

local WOOD = Color3.fromHex("#B07A45")
local WOOD_DARK = Color3.fromHex("#7A4E26")

local function cylinder(
	name: string,
	length: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, diameter, diameter)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90)) -- stand along Y
	p.Color = color
	p.Material = Enum.Material.Wood
	p.CanCollide = false
	p.Massless = true
	p.Parent = parent
	return p
end

function Bat.build(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Bonk Bat"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Bonk!"
	-- held near the bottom of the handle, bat pointing up
	tool.Grip = CFrame.new(0, -1.5, 0)

	local handle = cylinder("Handle", 2.2, 0.32, CFrame.new(0, 0, 0), WOOD_DARK, tool)
	local barrel = cylinder("Barrel", 2.6, 0.7, CFrame.new(0, 2.3, 0), WOOD, tool)
	local knob = cylinder("Knob", 0.18, 0.5, CFrame.new(0, -1.15, 0), WOOD_DARK, tool)
	for _, part in { barrel, knob } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
	end

	local cooldown = Config.Defences.BONK_COOLDOWN
	local last = 0
	tool.Activated:Connect(function()
		local now = os.clock()
		if now - last < cooldown then
			return
		end
		last = now
		-- the default R15 Animate script plays its slash animation when it sees this value
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
	end)
	return tool
end

return Bat
