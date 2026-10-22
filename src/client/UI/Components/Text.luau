--!strict
-- Chunky game text: Fredoka with an ink outline (UIStroke), or plain body text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>
-- Fusion's state types don't unify with plain values under strict mode; Fusion checks props at runtime.
type UsedAs<T> = any

export type Props = {
	text: UsedAs<string>,
	size: number, -- text size in design px
	color: UsedAs<Color3>?,
	position: UsedAs<UDim2>?,
	anchor: Vector2?,
	width: number?, -- box width in design px (defaults to auto-size)
	align: Enum.TextXAlignment?,
	outline: boolean?, -- ink outline (default true for display text)
	body: boolean?, -- Nunito instead of Fredoka
	zIndex: number?,
	visible: UsedAs<boolean>?,
}

local function Text(scope: Scope, props: Props): Instance
	local outline = if props.outline == nil then not props.body else props.outline
	return scope:New("TextLabel")({
		BackgroundTransparency = 1,
		AnchorPoint = props.anchor or Vector2.zero,
		Position = props.position or UDim2.new(),
		Size = if props.width
			then UDim2.fromOffset(props.width, props.size + 6)
			else UDim2.fromOffset(0, props.size + 6),
		AutomaticSize = if props.width then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		FontFace = if props.body then Theme.body else Theme.display,
		TextSize = props.size,
		Text = props.text,
		TextColor3 = props.color or Theme.white,
		TextXAlignment = props.align or Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = props.zIndex or 1,
		Visible = if props.visible == nil then true else props.visible,
		[Fusion.Children] = if outline
			then {
				scope:New("UIStroke")({
					Color = Theme.ink,
					Thickness = math.max(1.5, props.size / 10),
					LineJoinMode = Enum.LineJoinMode.Round,
				}),
			}
			else {},
	})
end

return Text
