--!strict
-- Always-visible HUD (approved HUD-1/2/3): cash + income/s, the cycle timer with its phase bar,
-- side buttons (max 6), and a single alert toast under the timer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Button = require(script.Parent.Button)
local Pill = require(script.Parent.Pill)
local Store = require(script.Parent.Parent.Store)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

local Hud = {}

function Hud.CashPills(scope: Scope, store: Store.Store): Instance
	return scope:New("Frame")({
		Name = "Cash",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(146, 14),
		Size = UDim2.fromOffset(250, 104),
		[Fusion.Children] = {
			Pill(scope, {
				size = UDim2.fromOffset(250, 58),
				children = {
					Text(scope, {
						text = "$",
						size = 30,
						color = Theme.yellow,
						position = UDim2.fromOffset(20, 26),
						anchor = Vector2.new(0, 0.5),
					}),
					Text(scope, {
						text = scope:Computed(function(use)
							return Format.cash(use(store.cash))
						end),
						size = 34,
						color = Theme.ink,
						outline = false,
						position = UDim2.fromOffset(52, 28),
						anchor = Vector2.new(0, 0.5),
					}),
				},
			}),
			Pill(scope, {
				size = UDim2.fromOffset(150, 38),
				position = UDim2.fromOffset(10, 64),
				color = Theme.moneyGreen,
				children = {
					Text(scope, {
						text = scope:Computed(function(use)
							return Format.perSec(use(store.perSec))
						end),
						size = 24,
						position = UDim2.fromScale(0.5, 0.5),
						anchor = Vector2.new(0.5, 0.5),
					}),
				},
			}),
		},
	})
end

local PHASES = { "Day", "Dusk", "Night", "DawnVote" }

function Hud.CycleTimer(scope: Scope, store: Store.Store): Instance
	local g = Config.Game
	local lengths = { Day = g.DAY_LENGTH, Dusk = g.DUSK, Night = g.NIGHT_LENGTH, DawnVote = g.DAWN_VOTE }
	local total = g.DAY_LENGTH + g.DUSK + g.NIGHT_LENGTH + g.DAWN_VOTE
	local width = 320
	local barWidth = width - 40

	local isNight = scope:Computed(function(use)
		local p = use(store.phase)
		return p == "Night" or p == "DawnVote"
	end)
	local remaining = scope:Computed(function(use)
		return math.max(0, use(store.phaseEndsAt) - use(store.now))
	end)

	local segments: { Instance } = {}
	local x = 0
	for _, name in PHASES do
		local w = (lengths[name] / total) * barWidth
		table.insert(
			segments,
			scope:New("Frame")({
				BackgroundColor3 = Theme.cycleColors[name],
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(x + 1, 3),
				Size = UDim2.fromOffset(w - 2, 12),
			})
		)
		x += w
	end
	-- marker position: start of current phase + elapsed within it
	local markerX = scope:Computed(function(use)
		local phase = use(store.phase)
		local start = 0
		for _, name in PHASES do
			if name == phase then
				break
			end
			start += lengths[name]
		end
		local into = math.clamp(lengths[phase] - use(remaining), 0, lengths[phase])
		return (start + into) / total * barWidth
	end)

	local label: { [string]: string } = { Day = "DAY", Dusk = "DUSK", Night = "NIGHT", DawnVote = "VOTE" }

	return scope:New("Frame")({
		Name = "CycleTimer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(width, 92),
		[Fusion.Children] = {
			Pill(scope, {
				size = UDim2.fromOffset(width, 62),
				color = scope:Computed(function(use)
					return if use(isNight) then Theme.panelNight else Theme.white
				end),
				children = {
					Text(scope, {
						text = scope:Computed(function(use)
							return if use(isNight) then "☾" else "☀"
						end),
						size = 32,
						color = Theme.yellow,
						position = UDim2.fromOffset(40, 31),
						anchor = Vector2.new(0.5, 0.5),
					}),
					Text(scope, {
						text = scope:Computed(function(use)
							return label[use(store.phase)]
						end),
						size = 30,
						color = scope:Computed(function(use)
							return if use(isNight) then Theme.white else Theme.ink
						end),
						outline = false,
						position = UDim2.fromOffset(70, 31),
						anchor = Vector2.new(0, 0.5),
					}),
					Text(scope, {
						text = scope:Computed(function(use)
							return Format.clock(use(remaining))
						end),
						size = 34,
						color = scope:Computed(function(use)
							return if use(isNight) then Theme.yellow else Theme.ink
						end),
						outline = false,
						position = UDim2.new(1, -24, 0, 31),
						anchor = Vector2.new(1, 0.5),
					}),
				},
			}),
			-- phase bar
			scope:New("Frame")({
				BackgroundColor3 = Theme.ink,
				Position = UDim2.fromOffset(20, 70),
				Size = UDim2.fromOffset(barWidth, 18),
				[Fusion.Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, 9) }),
					scope:New("Frame")({
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						ClipsDescendants = true,
						[Fusion.Children] = segments,
					}),
					-- marker
					scope:New("Frame")({
						BackgroundColor3 = Theme.white,
						AnchorPoint = Vector2.new(0.5, 1),
						Position = scope:Computed(function(use)
							return UDim2.fromOffset(use(markerX), 2)
						end),
						Size = UDim2.fromOffset(8, 14),
						[Fusion.Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0, 3) }),
							scope:New("UIStroke")({ Color = Theme.ink, Thickness = 2.5 }),
						},
					}),
				},
			}),
		},
	})
end

-- Side buttons. Only screens that exist are shown; the rest arrive with their phases
-- (Eggs/Base/Trade/Store/Menu by day; Defend + BONK at night), staying within the 6-button budget.
function Hud.Buttons(scope: Scope, store: Store.Store): Instance
	return scope:New("Frame")({
		Name = "SideButtons",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 158),
		Size = UDim2.fromOffset(84, 380),
		[Fusion.Children] = {
			Button(scope, {
				size = Vector2.new(84, 84),
				color = Theme.pink,
				icon = "🛒",
				caption = "Shop",
				visible = store.shopOpen,
				onClick = function()
					store.shopVisible:set(not Fusion.peek(store.shopVisible))
				end,
			}),
		},
	})
end

local TOAST_COLORS: { [string]: Color3 } = {
	info = Theme.blue,
	good = Theme.green,
	warn = Theme.pink,
	drop = Theme.yellow,
}

function Hud.Toast(scope: Scope, store: Store.Store): Instance
	local visible = scope:Computed(function(use)
		return use(store.toast) ~= nil
	end)
	return Pill(scope, {
		size = UDim2.fromOffset(0, 52),
		automaticSize = Enum.AutomaticSize.X,
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 112),
		visible = visible,
		zIndex = 20,
		children = {
			scope:New("UIPadding")({ PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 20) }),
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 12),
			}),
			Pill(scope, {
				size = UDim2.fromOffset(28, 28),
				strokeThickness = 3,
				color = scope:Computed(function(use)
					local t = use(store.toast)
					return if t then TOAST_COLORS[t.kind] or Theme.blue else Theme.blue
				end),
				zIndex = 21,
			}),
			Text(scope, {
				text = scope:Computed(function(use)
					local t = use(store.toast)
					return if t then t.text else ""
				end),
				size = 21,
				body = true,
				color = Theme.ink,
				zIndex = 21,
			}),
		},
	})
end

return Hud
