--!strict
-- Day -> Dusk -> Night -> DawnVote clock (built in Phase 2 so the HUD timer and night closures work;
-- night waves arrive in Phase 5). Studio only: set Workspace attribute `CycleTimeScale` (e.g. 20) to fast-forward.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Cycle = require(ReplicatedStorage.Shared.Logic.Cycle)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local DataService = require(script.Parent.DataService)

local CycleService = {
	-- (newPhase, previousPhase)
	phaseChanged = Signal.new() :: Signal.Signal<Types.CyclePhase, Types.CyclePhase?>,
}

local LIGHTING: { [Types.CyclePhase]: { clock: number, ambient: Color3, brightness: number } } = {
	Day = { clock = 14, ambient = Color3.fromRGB(150, 150, 160), brightness = 2.2 },
	Dusk = { clock = 18, ambient = Color3.fromRGB(170, 120, 120), brightness = 1.6 },
	Night = { clock = 0, ambient = Color3.fromRGB(95, 105, 170), brightness = 1 },
	DawnVote = { clock = 6.3, ambient = Color3.fromRGB(160, 140, 170), brightness = 1.4 },
}

local elapsed = 0
local current: Cycle.PhaseInfo = Cycle.at(0)

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
		OutdoorAmbient = look.ambient,
		Brightness = look.brightness,
	}):Play()
end

function CycleService.init()
	applyLighting(current.phase, true)
end

function CycleService.start()
	local lastBroadcast = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * timeScale()
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
