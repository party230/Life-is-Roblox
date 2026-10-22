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

local Config = require("../../src/shared/Config")
local EvilBolts = require("../../src/shared/World/EvilBolts")
local VariantLook = require("../../src/shared/World/VariantLook")
local VARIANTS = { "Normal", "Rainbow", "Evil" }

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
		if variant == "Evil" then
			-- one frozen strike of the client-side lightning
			local seed = #name * 7919
			local function rng()
				seed = (seed * 48271) % 2147483647
				return seed / 2147483647
			end
			local root = model.PrimaryPart
			for _, seg in EvilBolts.strike(rng, root.Size, Config.Variants.EVIL_BOLTS) do
				local p = Instance.new("Part")
				p.Name = "Bolt"
				p.Size = Vector3.new(0.09, 0.09, seg.length + 0.09)
				p.CFrame = root.CFrame * seg.cframe
				p.Color = Color3.fromHex(Config.Variants.EVIL_BOLT_COLOR)
				p.Parent = model
			end
		end
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
