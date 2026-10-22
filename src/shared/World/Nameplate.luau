--!strict
-- Floating nameplate over every brainrot: variant (if any), name, rarity (in rarity colour) and income $X/s.
-- Carpet brainrots also show their price. Built on the model's Nameplate attachment.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Logic.Catalog)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Income = require(ReplicatedStorage.Shared.Logic.Income)

local Nameplate = {}

local INK = Color3.fromHex("#1B1530")

export type Options = {
	price: number?, -- carpet only
}

local function line(parent: Instance, order: number, text: string, color: Color3, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = `Line{order}`
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, size)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = size
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = INK
	stroke.Parent = label
	label.Parent = parent
	return label
end

function Nameplate.attach(
	model: Model,
	speciesId: string,
	rarity: string,
	variant: string,
	opts: Options?
): BillboardGui?
	local root = model.PrimaryPart
	local anchor = root and root:FindFirstChild("Nameplate")
	if not anchor then
		return nil
	end
	local o: Options = opts or {}
	local def = Catalog.resolve(speciesId, rarity)
	local rarityDef = Config.Rarities.byId[def.rarity]
	local variantDef = Config.Variants.byId[variant] or Config.Variants.byId.Normal

	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromOffset(220, 110)
	gui.SizeOffset = Vector2.new(0, 0.5)
	gui.LightInfluence = 0
	gui.MaxDistance = 110
	gui.AlwaysOnTop = false
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui

	if variantDef.displayName ~= "" then
		line(gui, 1, variantDef.displayName, Color3.fromHex(variantDef.nameColor), 17)
	end
	line(gui, 2, def.displayName, Color3.new(1, 1, 1), 20)
	local rarityLine = line(gui, 3, rarityDef.id, Color3.fromHex(rarityDef.color), 17)
	if rarityDef.style == "rainbowRim" then
		rarityLine.TextColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#FF5C8A")),
			ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFD23F")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#4DA3FF")),
		})
		g.Parent = rarityLine
	end
	line(gui, 4, Format.perSec(Income.perSec(speciesId, variant, rarity)), Color3.fromHex("#7CFF9B"), 17)
	if o.price then
		line(gui, 5, Format.price(o.price), Color3.fromHex("#FFD23F"), 20)
	end
	gui.Adornee = anchor
	gui.Parent = anchor
	return gui
end

return Nameplate
