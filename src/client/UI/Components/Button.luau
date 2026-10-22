--!strict
-- Chunky game button: coloured face on a darker ledge, ink outline, squashes down when pressed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>
-- Fusion's state types don't unify with plain values under strict mode; Fusion checks props at runtime.
type UsedAs<T> = any

export type Props = {
	size: Vector2, -- design px (including the ledge)
	position: UsedAs<UDim2>?,
	anchor: Vector2?,
	color: UsedAs<Color3>,
	text: UsedAs<string>?,
	textSize: number?,
	icon: string?, -- placeholder glyph until icon art is uploaded
	iconSize: number?,
	caption: string?, -- label under the button (HUD buttons)
	onClick: () -> (),
	enabled: UsedAs<boolean>?,
	visible: UsedAs<boolean>?,
	zIndex: number?,
	children: { any }?,
}

local LEDGE = 7

local function Button(scope: Scope, props: Props): Instance
	local pressed = scope:Value(false)
	local offset = scope:Spring(
		scope:Computed(function(use)
			return if use(pressed) then LEDGE - 2 else 0
		end),
		40,
		0.7
	)
	local enabled = props.enabled
	local isEnabled = scope:Computed(function(use)
		return if enabled == nil then true else use(enabled)
	end)
	local color = props.color
	local face = scope:Computed(function(use)
		return if use(isEnabled) then use(color) else Theme.grey
	end)
	local radius = math.min(22, props.size.Y / 2.6)
	local z = props.zIndex or 1

	local faceChildren: { Instance } = {
		scope:New("UICorner")({ CornerRadius = UDim.new(0, radius) }),
		scope:New("UIStroke")({
			Color = Theme.ink,
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		-- top shine
		scope:New("Frame")({
			BackgroundColor3 = Theme.white,
			BackgroundTransparency = 0.65,
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.new(1, -16, 0, math.max(4, (props.size.Y - LEDGE) * 0.2)),
			ZIndex = z + 1,
			[Fusion.Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(0, radius / 2) }) },
		}),
	}
	if props.icon then
		table.insert(
			faceChildren,
			Text(scope, {
				text = props.icon,
				size = props.iconSize or math.floor(props.size.Y * 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				anchor = Vector2.new(0.5, 0.5),
				outline = false,
				zIndex = z + 2,
			})
		)
	end
	if props.text then
		table.insert(
			faceChildren,
			Text(scope, {
				text = props.text,
				size = props.textSize or 26,
				position = UDim2.fromScale(0.5, 0.5),
				anchor = Vector2.new(0.5, 0.5),
				zIndex = z + 2,
			})
		)
	end
	local extra: { any } = props.children or {}
	for _, child in extra do
		table.insert(faceChildren, child)
	end

	local rootChildren: { Instance } = {
		-- ledge
		scope:New("Frame")({
			BackgroundColor3 = scope:Computed(function(use)
				return Theme.darken(use(face), 0.3)
			end),
			Position = UDim2.fromOffset(0, LEDGE),
			Size = UDim2.new(1, 0, 1, -LEDGE),
			ZIndex = z,
			[Fusion.Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0, radius) }),
				scope:New("UIStroke")({ Color = Theme.ink, Thickness = 4 }),
			},
		}),
		scope:New("TextButton")({
			Name = "Face",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = face,
			Position = scope:Computed(function(use)
				return UDim2.fromOffset(0, use(offset))
			end),
			Size = UDim2.new(1, 0, 1, -LEDGE),
			ZIndex = z + 1,
			[Fusion.OnEvent("MouseButton1Down")] = function()
				pressed:set(true)
			end,
			[Fusion.OnEvent("MouseButton1Up")] = function()
				pressed:set(false)
			end,
			[Fusion.OnEvent("MouseLeave")] = function()
				pressed:set(false)
			end,
			[Fusion.OnEvent("Activated")] = function()
				if Fusion.peek(isEnabled) then
					props.onClick()
				end
			end,
			[Fusion.Children] = faceChildren,
		}),
	}
	if props.caption then
		table.insert(
			rootChildren,
			Text(scope, {
				text = props.caption,
				size = 19,
				position = UDim2.new(0.5, 0, 1, 2),
				anchor = Vector2.new(0.5, 0),
				zIndex = z,
			})
		)
	end

	return scope:New("Frame")({
		BackgroundTransparency = 1,
		AnchorPoint = props.anchor or Vector2.zero,
		Position = props.position or UDim2.new(),
		Size = UDim2.fromOffset(props.size.X, props.size.Y),
		Visible = if props.visible == nil then true else props.visible,
		[Fusion.Children] = rootChildren,
	})
end

return Button
