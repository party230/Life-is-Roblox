--!strict
-- Pure recolouring for variants (no services), shared by Variants.apply in game and the headless preview tool.
-- The base design never changes: only colour/material of visual parts (D36).
--   Rainbow: parts are split top-to-bottom into Config RAINBOW_BANDS (attribute "RainbowBand" = band index),
--            which the client scrolls upward.
--   Evil:    near-black body, glowing red eyes. Its lightning is drawn separately (EvilBolts).

local Config = require("../Config")

local VariantLook = {}

local V = Config.Variants

local function luminance(c: Color3): number
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function role(p: BasePart): string
	return (p:GetAttribute("Role") :: string?) or "skin"
end

-- Colour of band `band` (0 = top) after the colours have scrolled `shift` bands upward.
function VariantLook.rainbowColor(band: number, shift: number): Color3
	local bands = V.RAINBOW_BANDS
	return Color3.fromHex(bands[((band + shift) % #bands) + 1])
end

local function rainbow(parts: { BasePart })
	local coloured: { BasePart } = {}
	for _, p in parts do
		local r = role(p)
		-- eyes and very dark details (mouths, outlines) stay as they are so the face still reads
		if r == "eye" or r == "pupil" or (r == "detail" and luminance(p.Color) < 0.18) then
			continue
		end
		table.insert(coloured, p)
	end
	table.sort(coloured, function(a, b)
		local ya, yb = a.CFrame.Position.Y, b.CFrame.Position.Y
		if math.abs(ya - yb) > 1e-3 then
			return ya > yb
		end
		return a.CFrame.Position.X < b.CFrame.Position.X
	end)
	local n = #V.RAINBOW_BANDS
	for i, p in coloured do
		local band = math.min(math.floor((i - 1) * n / #coloured), n - 1)
		p:SetAttribute("RainbowBand", band)
		p.Color = VariantLook.rainbowColor(band, 0)
		p.Material = Enum.Material.SmoothPlastic
		p.Reflectance = 0.05
	end
end

local function evil(parts: { BasePart })
	local palette = V.EVIL_PALETTE
	for _, p in parts do
		local r = role(p)
		if r == "eye" then
			p.Color = Color3.fromHex(V.EVIL_EYE_COLOR)
			p.Material = Enum.Material.Neon
		elseif r == "pupil" then
			p.Color = Color3.fromHex(V.EVIL_PUPIL_COLOR)
			p.Material = Enum.Material.Neon
		else
			local i = math.clamp(math.floor(luminance(p.Color) * #palette) + 1, 1, #palette)
			p.Color = Color3.fromHex(palette[i])
			p.Material = Enum.Material.SmoothPlastic
		end
	end
end

function VariantLook.apply(model: Model, variant: string)
	local parts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			table.insert(parts, d)
		end
	end
	if variant == "Rainbow" then
		rainbow(parts)
	elseif variant == "Evil" then
		evil(parts)
	end
end

return VariantLook
