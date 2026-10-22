--!strict
-- Rarity chip; Secret is a black chip with a rainbow rim (approved).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

local function RarityChip(scope: Scope, rarity: string, textSize: number, position: UDim2?): Instance
	local rainbow = Theme.isRainbowRim(rarity)
	local strokeChildren: { Instance } = {}
	if rainbow then
		table.insert(
			strokeChildren,
			scope:New("UIGradient")({
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.pink),
					ColorSequenceKeypoint.new(0.33, Theme.yellow),
					ColorSequenceKeypoint.new(0.66, Theme.green),
					ColorSequenceKeypoint.new(1, Theme.blue),
				}),
			})
		)
	end
	return scope:New("Frame")({
		BackgroundColor3 = Theme.rarity(rarity),
		Position = position or UDim2.new(),
		Size = UDim2.fromOffset(0, textSize + 14),
		AutomaticSize = Enum.AutomaticSize.X,
		[Fusion.Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			scope:New("UIPadding")({ PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
			scope:New("UIStroke")({
				Color = if rainbow then Theme.white else Theme.ink,
				Thickness = if rainbow then 4 else 3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				[Fusion.Children] = strokeChildren,
			}),
			Text(scope, {
				text = string.upper(rarity),
				size = textSize,
				position = UDim2.fromScale(0, 0.5),
				anchor = Vector2.new(0, 0.5),
			}),
		},
	})
end

return RarityChip
