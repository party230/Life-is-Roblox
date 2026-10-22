--!strict
-- Applies a variant's look on top of a character's base design (D22). The base design never changes:
-- variants only recolour/re-material and add effects. Animated parts of variants (rainbow hue cycling,
-- the trail while walking, the Dark idle) are driven client-side by BrainrotAnimator via model tags.
--
-- Rogue (loyalty state, Phase 4) must never look like Dark: Rogue = shaking + angry nameplate icon + red
-- outline, with NO colour change (D23).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function gold(vfx: Attachment)
	emitter(vfx, {
		Name = "GoldSparkle",
		Color = ColorSequence.new(Color3.fromRGB(255, 230, 120)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.6, 1.1),
		Rate = 6,
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
	})
end

local function diamond(vfx: Attachment)
	emitter(vfx, {
		Name = "DiamondGlint",
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		LightEmission = 1,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Lifetime = NumberRange.new(0.3, 0.5),
		Rate = 2.5,
		Speed = NumberRange.new(0, 0),
		SpreadAngle = Vector2.new(180, 180),
	})
end

local function rainbow(model: Model, root: BasePart)
	-- the client cycles hues; the trail shows while walking
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

local function dark(model: Model, vfx: Attachment)
	local smoke = Instance.new("Smoke")
	smoke.Name = "DarkSmoke"
	smoke.Color = Color3.fromRGB(60, 20, 90)
	smoke.Opacity = 0.12
	smoke.RiseVelocity = 1.5
	smoke.Size = 1.5
	smoke.Parent = model:FindFirstChild("Body") or vfx.Parent
	local glowLight = Instance.new("PointLight")
	glowLight.Color = Color3.fromRGB(255, 40, 40)
	glowLight.Brightness = 0.6
	glowLight.Range = 5
	glowLight.Parent = vfx
	CollectionService:AddTag(model, "DarkVariant")
end

function Variants.apply(model: Model, variant: string)
	model:SetAttribute("Variant", variant)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local vfx = root:FindFirstChild("Vfx") :: Attachment
	if variant ~= "Rainbow" then
		VariantLook.apply(model, variant) -- rainbow colours are animated client-side from the base colours
	end
	if variant == "Gold" then
		gold(vfx)
	elseif variant == "Diamond" then
		diamond(vfx)
	elseif variant == "Rainbow" then
		rainbow(model, root)
	elseif variant == "Dark" then
		dark(model, vfx)
	end
	-- remember the applied colours for client-side effects (rainbow cycles from these)
	for _, p in visualParts(model) do
		p:SetAttribute("BaseColor", p.Color)
	end
end

return Variants
