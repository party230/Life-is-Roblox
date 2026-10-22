--!strict
-- Mounts the game UI. Everything is laid out in design px (1440x664 landscape phone) inside a root frame
-- that's scaled to the real screen, so the mockups translate 1:1.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Hud = require(script.Parent.Components.Hud)
local EggsPanel = require(script.Parent.Components.EggsPanel)
local ShopPanel = require(script.Parent.Components.ShopPanel)
local Store = require(script.Parent.Store)
local Theme = require(script.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

local App = {}

-- Studio-only Day/Night switch for the vertical slice (also the N key). Hidden on live servers.
local function DevToggle(scope: Scope, store: Store.Store): Instance
	local visible = RunService:IsStudio()
	local function toggle()
		local p = Fusion.peek(store.phase)
		Remotes.DevSetPhase:fire(if p == "Night" or p == "DawnVote" then "Day" else "Night")
	end
	if visible then
		table.insert(
			scope,
			UserInputService.InputBegan:Connect(function(input, processed)
				if not processed and input.KeyCode == Enum.KeyCode.N then
					toggle()
				end
			end)
		)
	end
	return scope:New("TextButton")({
		Name = "DevToggle",
		Visible = visible,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(240, 34),
		BackgroundColor3 = Color3.fromHex("#1B1530"),
		BackgroundTransparency = 0.3,
		TextColor3 = Color3.new(1, 1, 1),
		FontFace = Theme.body,
		TextSize = 16,
		Text = "DEV: Day ⇄ Night  (N)",
		[Fusion.OnEvent("Activated")] = toggle,
		[Fusion.Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
	})
end

local MIN_SCALE = 0.45
local MAX_SCALE = 1.3

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
					EggsPanel(scope, store),
					DevToggle(scope, store),
				},
			}),
		},
	})

	-- Shop stalls: prompts tagged with an "Opens" attribute open their screen (the hub Egg and Food shops).
	table.insert(
		scope,
		ProximityPromptService.PromptTriggered:Connect(function(prompt)
			local opens = prompt:GetAttribute("Opens")
			if opens == "Eggs" then
				store.shopVisible:set(false)
				store.eggsVisible:set(true)
			end
		end)
	)

	-- Camera zoom cap (approved Q2) is also enforced on the server via Player.CameraMaxZoomDistance.
	player.CameraMaxZoomDistance = Config.Game.CAMERA_MAX_ZOOM
	return store
end

return App
