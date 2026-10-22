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

-- Tuned for Future lighting (set in default.project.json). Night stays readable: moonlit blue, not black.
type Look = {
	clock: number,
	ambient: Color3,
	outdoor: Color3,
	brightness: number,
	exposure: number,
	haze: number,
	atmoColor: Color3,
}
local LIGHTING: { [Types.CyclePhase]: Look } = {
	Day = {
		clock = 14.5,
		ambient = Color3.fromRGB(70, 70, 80),
		outdoor = Color3.fromRGB(140, 140, 150),
		brightness = 3,
		exposure = 0.1,
		haze = 0.6,
		atmoColor = Color3.fromRGB(199, 214, 235),
	},
	Dusk = {
		clock = 17.8,
		ambient = Color3.fromRGB(80, 60, 70),
		outdoor = Color3.fromRGB(170, 120, 110),
		brightness = 2.2,
		exposure = 0.05,
		haze = 1.2,
		atmoColor = Color3.fromRGB(255, 170, 130),
	},
	Night = {
		clock = 0,
		ambient = Color3.fromRGB(45, 50, 85),
		outdoor = Color3.fromRGB(95, 105, 165),
		brightness = 1.6,
		exposure = 0.35,
		haze = 1.5,
		atmoColor = Color3.fromRGB(70, 80, 140),
	},
	DawnVote = {
		clock = 6.2,
		ambient = Color3.fromRGB(70, 60, 80),
		outdoor = Color3.fromRGB(160, 140, 170),
		brightness = 2,
		exposure = 0.15,
		haze = 1,
		atmoColor = Color3.fromRGB(240, 190, 200),
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
		TweenService:Create(atmosphere, info, { Haze = look.haze, Color = look.atmoColor }):Play()
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
