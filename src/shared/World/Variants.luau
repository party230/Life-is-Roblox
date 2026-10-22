--!strict
-- Applies a variant's look on top of a character's base design (D22, D36). The base design never changes:
-- variants only recolour and add effects. Animated parts (rainbow band scrolling, the trail while walking,
-- the Evil lightning and idle) are driven client-side by BrainrotAnimator via model tags.
--
-- Rogue (loyalty state) must never look like Evil: Rogue = shaking + angry nameplate icon + red outline,
-- with NO colour change (D23).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local VariantLook = require(ReplicatedStorage.Shared.World.VariantLook)

local Variants = {}

local function visualParts(model: Model): { BasePart }
	local out: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			table.insert(out, d)
		end
	end
	return out
end

local function rainbow(model: Model, root: BasePart)
	-- the client scrolls the colour bands; the trail shows while walking
	local a0 = root:FindFirstChild("TrailA") :: Attachment?
	local a1 = root:FindFirstChild("TrailB") :: Attachment?
	if a0 and a1 then
		local trail = Instance.new("Trail")
		trail.Name = "RainbowTrail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.6
		trail.LightEmission = 0.6
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 230, 90)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 160, 255)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 90, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200)),
		})
		trail.Enabled = false
		trail.Parent = root
	end
	CollectionService:AddTag(model, "RainbowVariant")
end

local function evil(model: Model, vfx: Attachment)
	-- the lightning itself is client-side (BrainrotAnimator + EvilBolts); this is the steady red glow
	local glowLight = Instance.new("PointLight")
	glowLight.Name = "EvilGlow"
	glowLight.Color = Color3.fromHex(Config.Variants.EVIL_BOLT_COLOR)
	glowLight.Brightness = 1.2
	glowLight.Range = 9
	glowLight.Parent = vfx
	CollectionService:AddTag(model, "EvilVariant")
end

function Variants.apply(model: Model, variant: string)
	model:SetAttribute("Variant", variant)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local vfx = root:FindFirstChild("Vfx") :: Attachment
	VariantLook.apply(model, variant)
	if variant == "Rainbow" then
		rainbow(model, root)
	elseif variant == "Evil" then
		evil(model, vfx)
	end
	-- remember the applied colours (Rogue and other client effects restore from these)
	for _, p in visualParts(model) do
		p:SetAttribute("BaseColor", p.Color)
	end
end

return Variants
