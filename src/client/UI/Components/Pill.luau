--!strict
-- Rounded outlined container (cash pill, chips, toasts).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>
-- Fusion's state types don't unify with plain values under strict mode; Fusion checks props at runtime.
type UsedAs<T> = any

export type Props = {
	size: UsedAs<UDim2>,
	position: UsedAs<UDim2>?,
	anchor: Vector2?,
	color: UsedAs<Color3>?,
	stroke: UsedAs<Color3>?,
	strokeThickness: number?,
	radius: number?, -- default fully rounded
	automaticSize: Enum.AutomaticSize?,
	visible: UsedAs<boolean>?,
	zIndex: number?,
	children: { any }?,
}

local function Pill(scope: Scope, props: Props): Instance
	local children: { any } = {
		scope:New("UICorner")({
			CornerRadius = if props.radius then UDim.new(0, props.radius) else UDim.new(1, 0),
		}),
		scope:New("UIStroke")({
			Color = props.stroke or Theme.ink,
			Thickness = props.strokeThickness or 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}
	local extra: { any } = props.children or {}
	for _, c in extra do
		table.insert(children, c)
	end
	return scope:New("Frame")({
		BackgroundColor3 = props.color or Theme.white,
		AnchorPoint = props.anchor or Vector2.zero,
		Position = props.position or UDim2.new(),
		Size = props.size,
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.None,
		Visible = if props.visible == nil then true else props.visible,
		ZIndex = props.zIndex or 1,
		[Fusion.Children] = children,
	})
end

return Pill
