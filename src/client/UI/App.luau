--!strict
-- Mounts the game UI. Everything is laid out in design px (1440x664 landscape phone) inside a root frame
-- that's scaled to the real screen, so the mockups translate 1:1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Hud = require(script.Parent.Components.Hud)
local ShopPanel = require(script.Parent.Components.ShopPanel)
local Store = require(script.Parent.Store)
local Text = require(script.Parent.Components.Text)
local Theme = require(script.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

local App = {}

local MIN_SCALE = 0.45
local MAX_SCALE = 1.3

-- World marker over the plaza belt while a plaza drop is live ("tap the banner to find it").
local function PlazaMarker(scope: Scope, store: Store.Store, parent: Instance)
	task.spawn(function()
		local world = workspace:WaitForChild("World", 30)
		local belt = world and world:WaitForChild("PlazaDropBelt", 30)
		if not belt then
			return
		end
		scope:New("BillboardGui")({
			Name = "PlazaDropMarker",
			Adornee = belt,
			AlwaysOnTop = true,
			Size = UDim2.fromOffset(220, 60),
			StudsOffsetWorldSpace = Vector3.new(0, 9, 0),
			Enabled = scope:Computed(function(use)
				return use(store.plazaDrop) ~= nil
			end),
			Parent = parent,
			[Fusion.Children] = {
				Text(scope, {
					text = "PLAZA DROP ▼",
					size = 30,
					color = Theme.yellow,
					position = UDim2.fromScale(0.5, 0.5),
					anchor = Vector2.new(0.5, 0.5),
				}),
			},
		})
	end)
end

function App.mount(): Store.Store
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local scope = Fusion.scoped(Fusion)
	local store = Store.new(scope)

	local camera = workspace.CurrentCamera
	local viewport = scope:Value(camera.ViewportSize)
	table.insert(
		scope,
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			viewport:set(camera.ViewportSize)
		end)
	)
	local uiScale = scope:Computed(function(use)
		local size = use(viewport)
		-- fit the design canvas inside the screen
		local s = math.min(size.Y / Theme.DESIGN_HEIGHT, size.X / Theme.DESIGN_WIDTH)
		return math.clamp(s, MIN_SCALE, MAX_SCALE)
	end)

	scope:New("ScreenGui")({
		Name = "RotShiftUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
		[Fusion.Children] = {
			scope:New("Frame")({
				Name = "Root",
				BackgroundTransparency = 1,
				Size = scope:Computed(function(use)
					local s = use(uiScale)
					return UDim2.fromScale(1 / s, 1 / s)
				end),
				[Fusion.Children] = {
					scope:New("UIScale")({ Scale = uiScale }),
					Hud.CashPills(scope, store),
					Hud.CycleTimer(scope, store),
					Hud.Buttons(scope, store),
					Hud.Toast(scope, store),
					ShopPanel(scope, store),
				},
			}),
		},
	})
	PlazaMarker(scope, store, playerGui)

	-- Close the shop automatically when it closes for the night is NOT wanted: players see the closed state.
	-- Camera zoom cap (approved Q2) is also enforced on the server via Player.CameraMaxZoomDistance.
	player.CameraMaxZoomDistance = Config.Game.CAMERA_MAX_ZOOM
	return store
end

return App
