--!strict
-- Day -> Dusk -> Night -> DawnVote clock (built in Phase 2 so the HUD timer and night closures work;
-- night waves arrive in Phase 5). Studio only: set Workspace attribute `CycleTimeScale` (e.g. 20) to fast-forward.
-- Vertical slice: the clock is frozen at midday; the Studio-only DevSetPhase remote (N key) flips Day/Night.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Cycle = require(ReplicatedStorage.Shared.Logic.Cycle)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local DataService = require(script.Parent.DataService)

local CycleService = {
	-- (newPhase, previousPhase)
	phaseChanged = Signal.new() :: Signal.Signal<Types.CyclePhase, Types.CyclePhase?>,
}

-- Tuned for Future lighting (set in default.project.json) to match the style reference (assets/reference/style.png):
-- saturated and bright by day; at night a purple starry sky while the world stays vivid, not dark.
type Look = {
	clock: number,
	ambient: Color3,
	outdoor: Color3,
	brightness: number,
	exposure: number,
	haze: number,
	atmoColor: Color3,
	decay: Color3,
	density: number,
}
local LIGHTING: { [Types.CyclePhase]: Look } = {
	Day = {
		clock = 14,
		ambient = Color3.fromRGB(110, 110, 120),
		outdoor = Color3.fromRGB(165, 165, 175),
		brightness = 3.2,
		exposure = 0.15,
		haze = 0.4,
		atmoColor = Color3.fromRGB(199, 220, 255),
		decay = Color3.fromRGB(106, 140, 200),
		density = 0.22,
	},
	Dusk = {
		clock = 17.8,
		ambient = Color3.fromRGB(110, 90, 100),
		outdoor = Color3.fromRGB(180, 130, 130),
		brightness = 2.6,
		exposure = 0.15,
		haze = 1,
		atmoColor = Color3.fromRGB(255, 170, 130),
		decay = Color3.fromRGB(150, 80, 110),
		density = 0.28,
	},
	Night = {
		clock = 0,
		ambient = Color3.fromRGB(105, 100, 150),
		outdoor = Color3.fromRGB(155, 145, 210),
		brightness = 2.4,
		exposure = 0.45,
		haze = 0.8,
		atmoColor = Color3.fromRGB(120, 85, 200),
		decay = Color3.fromRGB(70, 40, 140),
		density = 0.3,
	},
	DawnVote = {
		clock = 6.2,
		ambient = Color3.fromRGB(110, 95, 120),
		outdoor = Color3.fromRGB(175, 150, 185),
		brightness = 2.6,
		exposure = 0.2,
		haze = 0.8,
		atmoColor = Color3.fromRGB(240, 190, 220),
		decay = Color3.fromRGB(150, 100, 160),
		density = 0.25,
	},
}

local SLICE_DAY_ELAPSED = 120 -- frozen point in the slice: 2 minutes into the day
local SLICE_NIGHT_ELAPSED = 0 -- set from Cycle when the dev toggle picks Night

local elapsed = if Config.Game.VERTICAL_SLICE then SLICE_DAY_ELAPSED else 0
local current: Cycle.PhaseInfo = Cycle.at(elapsed)

local function timeScale(): number
	if not RunService:IsStudio() then
		return 1
	end
	local v = workspace:GetAttribute("CycleTimeScale")
	return if type(v) == "number" and v > 0 then v else 1
end

function CycleService.phase(): Types.CyclePhase
	return current.phase
end

function CycleService.shopOpen(): boolean
	return Cycle.shopOpen(current.phase)
end

function CycleService.state(): Remotes.CycleState
	return {
		phase = current.phase,
		endsAt = workspace:GetServerTimeNow() + current.remaining / timeScale(),
		cycle = current.cycle,
	}
end

local function applyLighting(phase: Types.CyclePhase, instant: boolean)
	local look = LIGHTING[phase]
	local info = TweenInfo.new(if instant then 0 else 4, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, {
		ClockTime = look.clock,
		Ambient = look.ambient,
		OutdoorAmbient = look.outdoor,
		Brightness = look.brightness,
		ExposureCompensation = look.exposure,
	}):Play()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, info, {
			Haze = look.haze,
			Color = look.atmoColor,
			Decay = look.decay,
			Density = look.density,
		}):Play()
	end
end

function CycleService.init()
	applyLighting(current.phase, true)
end

function CycleService.start()
	local lastBroadcast = 0
	if Config.Game.VERTICAL_SLICE then
		local g = Config.Game
		SLICE_NIGHT_ELAPSED = g.DAY_LENGTH + g.DUSK + 60
	end
	Remotes.DevSetPhase:connect(function(_, phase)
		if not RunService:IsStudio() then
			return -- never on live servers
		end
		elapsed = if phase == "Night" then SLICE_NIGHT_ELAPSED else SLICE_DAY_ELAPSED
	end)
	RunService.Heartbeat:Connect(function(dt: number)
		if not Config.Game.VERTICAL_SLICE then
			elapsed += dt * timeScale()
		end
		local info = Cycle.at(elapsed)
		local previous = current
		current = info
		if info.phase ~= previous.phase or info.cycle ~= previous.cycle then
			applyLighting(info.phase, false)
			Remotes.CycleState:fireAll(CycleService.state())
			CycleService.phaseChanged:fire(info.phase, previous.phase)
		elseif os.clock() - lastBroadcast > 30 then
			-- periodic resync (cheap) so clients never drift far
			lastBroadcast = os.clock()
			Remotes.CycleState:fireAll(CycleService.state())
		end
	end)
	DataService.sessionReady:connect(function(player)
		Remotes.CycleState:fireClient(player, CycleService.state())
	end)
	workspace:GetAttributeChangedSignal("CycleTimeScale"):Connect(function()
		Remotes.CycleState:fireList(Players:GetPlayers(), CycleService.state())
	end)
end

return CycleService
