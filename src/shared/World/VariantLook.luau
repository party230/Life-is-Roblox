--!strict
-- Pure recolouring for variants (no services), shared by Variants.apply in game and the headless preview tool.
-- The base design never changes: only colour/material/transparency of visual parts.

local Config = require("../Config")

local VariantLook = {}

local V = Config.Variants

local function luminance(c: Color3): number
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function role(p: BasePart): string
	return (p:GetAttribute("Role") :: string?) or "skin"
end

-- Recolours one visual part for `variant`. Rainbow is animated client-side, so here it only bumps saturation
-- (the preview shows a fixed hue spread).
function VariantLook.applyToPart(p: BasePart, variant: string, index: number?)
	local r = role(p)
	if variant == "Gold" then
		if r == "skin" or r == "detail" then
			local l = luminance(p.Color)
			local g = Color3.fromHex(V.GOLD_COLOR)
			p.Color = g:Lerp(Color3.new(1, 0.95, 0.7), math.clamp(l - 0.5, 0, 0.5))
				:Lerp(Color3.fromRGB(120, 80, 10), math.clamp(0.35 - l, 0, 0.35))
			p.Material = Enum.Material.Foil
			p.Reflectance = 0.25
		end
	elseif variant == "Diamond" then
		if r == "skin" or r == "detail" then
			p.Color = Color3.fromHex(V.DIAMOND_COLOR)
				:Lerp(Color3.new(1, 1, 1), math.clamp(luminance(p.Color) - 0.4, 0, 0.6))
			p.Material = Enum.Material.Glass
			p.Transparency = math.max(p.Transparency, 0.12)
			p.Reflectance = 0.35
		end
	elseif variant == "Dark" then
		if r == "pupil" then
			p.Color = Color3.fromHex(V.DARK_EYE_COLOR)
			p.Material = Enum.Material.Neon
		elseif r == "eye" then
			p.Color = Color3.fromRGB(10, 6, 14)
		elseif r == "skin" or r == "detail" then
			local palette = V.DARK_PALETTE
			local l = luminance(p.Color)
			local i = math.clamp(math.floor(l * #palette) + 1, 1, #palette)
			p.Color = Color3.fromHex(palette[i])
		end
	elseif variant == "Rainbow" then
		if r == "skin" or r == "detail" then
			local h, s, v = p.Color:ToHSV()
			p.Color = Color3.fromHSV((h + (index or 0) * 0.07) % 1, math.max(s, 0.6), math.max(v, 0.55))
		end
	end
end

function VariantLook.apply(model: Model, variant: string)
	local i = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			i += 1
			VariantLook.applyToPart(d, variant, i)
		end
	end
end

return VariantLook
