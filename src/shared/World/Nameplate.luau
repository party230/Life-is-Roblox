--!strict
-- Floating nameplate over every brainrot: variant (if any), name, rarity (in rarity colour) and income $X/s.
-- Carpet brainrots also show their price. Built on the model's Nameplate attachment, world-scaled (studs).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Logic.Catalog)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Income = require(ReplicatedStorage.Shared.Logic.Income)

local Nameplate = {}

local STROKE = Color3.new(0, 0, 0)
local WIDTH_STUDS = Config.Layout.NAMEPLATE_WIDTH
local LINE_STUDS = Config.Layout.NAMEPLATE_LINE -- height of a weight-1 line, in studs (world-scaled)
local INCOME_COLOR = Color3.fromHex("#FFE34D")
local PRICE_COLOR = Color3.fromHex("#5CFF6B")
local STAGE_COLOR = Color3.fromHex("#9FE8FF")

export type Options = {
	price: number?, -- carpet only
	stage: string?, -- "Baby" / "Teen" add a stage line (public: anyone can see a baby is a baby)
}

type Line = { text: string, color: Color3, weight: number, gradient: boolean? }

local function addLine(parent: Instance, order: number, line: Line, totalWeight: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = `Line{order}`
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, line.weight / totalWeight)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = line.color
	label.Text = line.text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3.5
	stroke.Color = STROKE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	if line.gradient then
		label.TextColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#FF5C8A")),
			ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFD23F")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#4DA3FF")),
		})
		g.Parent = label
	end
	label.Parent = parent
	return label
end

-- Stacked nameplate: variant (if any) / name / rarity / $ per sec / price (carpet only).
-- White text with a thick black stroke; variant, rarity and money lines are colour-coded.
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

	local lines: { Line } = {}
	if o.stage and o.stage ~= "Adult" then
		table.insert(lines, { text = o.stage, color = STAGE_COLOR, weight = 0.8 })
	end
	if variantDef.displayName ~= "" then
		table.insert(
			lines,
			{ text = variantDef.displayName, color = Color3.fromHex(variantDef.nameColor), weight = 0.85 }
		)
	end
	table.insert(lines, { text = def.displayName, color = Color3.new(1, 1, 1), weight = 1.1 })
	table.insert(lines, {
		text = rarityDef.id :: string,
		color = Color3.fromHex(rarityDef.color),
		weight = 0.85,
		gradient = rarityDef.style == "rainbowRim",
	})
	table.insert(lines, {
		text = Format.perSec(Income.perSec(speciesId, variant, rarity)),
		color = INCOME_COLOR,
		weight = 0.9,
	})
	if o.price then
		table.insert(lines, { text = Format.price(o.price), color = PRICE_COLOR, weight = 1 })
	end
	local total = 0
	for _, l in lines do
		total += l.weight
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromScale(WIDTH_STUDS, total * LINE_STUDS)
	gui.SizeOffset = Vector2.new(0, 0.5) -- grow upward from the attachment
	gui.LightInfluence = 0
	gui.MaxDistance = Config.Layout.NAMEPLATE_MAX_DISTANCE -- the owner's client raises this for their own
	gui.AlwaysOnTop = false
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	for i, l in lines do
		addLine(gui, i, l, total)
	end
	gui.Adornee = anchor
	gui.Parent = anchor
	return gui
end

return Nameplate
