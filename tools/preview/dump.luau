--!nocheck
-- Builds every character model headless (Lune + @lune/roblox) and dumps part geometry as JSON for render.py.
-- Usage (repo root): lune run tools/preview/dump.luau > build/models.json

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

for _, k in
	{
		"Instance",
		"Vector3",
		"CFrame",
		"Color3",
		"Enum",
		"Vector2",
		"UDim2",
		"UDim",
		"ColorSequence",
		"ColorSequenceKeypoint",
		"NumberSequence",
		"NumberSequenceKeypoint",
		"NumberRange",
	}
do
	(getfenv(0) :: any)[k] = (roblox :: any)[k]
end

local out = {}
local dir = "src/shared/World/Models/Characters"
local names = {}
for _, file in fs.readDir(dir) do
	if string.match(file, "%.luau$") then
		table.insert(names, (string.gsub(file, "%.luau$", "")))
	end
end
table.sort(names)
table.insert(names, "placeholder")

local VariantLook = require("../../src/shared/World/VariantLook")
local VARIANTS = { "Normal", "Gold", "Diamond", "Rainbow", "Dark" }

for _, name in names do
	for _, variant in VARIANTS do
		if name == "placeholder" and variant ~= "Normal" then
			continue
		end
		local builder = if name == "placeholder"
			then require("../../src/shared/World/Models/Placeholder")
			else require(`../../src/shared/World/Models/Characters/{name}`)
		local model = if name == "placeholder" then builder("#AA50FF") else builder()
		VariantLook.apply(model, variant)
		local parts = {}
		local partCount = 0
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "Root" then
				partCount += 1
				local cf = d.CFrame
				local c = { cf:GetComponents() }
				local shape = "Block"
				if d.ClassName == "WedgePart" then
					shape = "Wedge"
				elseif d.ClassName == "CornerWedgePart" then
					shape = "CornerWedge"
				elseif d.Shape == Enum.PartType.Ball then
					shape = "Ball"
				elseif d.Shape == Enum.PartType.Cylinder then
					shape = "Cylinder"
				end
				if d:FindFirstChildOfClass("SpecialMesh") then
					shape = "Ellipsoid"
				end
				table.insert(parts, {
					name = d.Name,
					shape = shape,
					size = { d.Size.X, d.Size.Y, d.Size.Z },
					cf = c,
					color = { d.Color.R, d.Color.G, d.Color.B },
					transparency = d.Transparency,
					role = d:GetAttribute("Role"),
				})
			end
		end
		local root = model.PrimaryPart
		table.insert(out, {
			name = name,
			variant = variant,
			displayName = model.Name,
			parts = parts,
			partCount = partCount,
			rootHeight = root and root.Size.Y or 0,
			hover = model:GetAttribute("Hover"),
			hasMotor = root and root:FindFirstChild("Anim") ~= nil,
		})
	end
end

print(serde.encode("json", out))
