--!strict
-- Client-side brainrot animation (cheap, no Animator assets needed): idle bob / sway / fly / twirl,
-- a waddle while walking the carpet, spinning propellers, rainbow hue cycling + trail, the Dark variant's
-- slow menacing idle, and the Rogue shake (Phase 4). Drives each model's Root.Anim Motor6D .Transform.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local BrainrotAnimator = {}

type Entry = {
	model: Model,
	motor: Motor6D?,
	spinners: { Motor6D },
	rainbowParts: { BasePart },
	trail: Trail?,
	phase: number,
}

local entries: { [Model]: Entry } = {}
local MAX_DISTANCE = 160
local RAINBOW_HZ = 20

local function track(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("Root") :: BasePart?
	if not root then
		return
	end
	local spinners: { Motor6D } = {}
	local rainbowParts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Name == "Spinner" then
			table.insert(spinners, d)
		elseif
			d:IsA("BasePart")
			and d.Name ~= "Root"
			and d:GetAttribute("Role") ~= "pupil"
			and d:GetAttribute("Role") ~= "eye"
		then
			table.insert(rainbowParts, d)
		end
	end
	entries[model] = {
		model = model,
		motor = root:FindFirstChild("Anim") :: Motor6D?,
		spinners = spinners,
		rainbowParts = if CollectionService:HasTag(model, "RainbowVariant") then rainbowParts else {},
		trail = root:FindFirstChild("RainbowTrail") :: Trail?,
		phase = math.random() * 10,
	}
end

local function untrack(model: Instance)
	entries[model :: Model] = nil
end

local function pose(e: Entry, t: number): CFrame
	local m = e.model
	local hover = (m:GetAttribute("Hover") :: number?) or 0
	local idle = (m:GetAttribute("Idle") :: string?) or "bob"
	local walking = m:GetAttribute("Walking") == true
	local dark = CollectionService:HasTag(m, "DarkVariant")
	local tt = t + e.phase
	if dark then
		tt *= 0.6
	end

	local y, rx, ry, rz = hover, 0, 0, 0
	if walking and hover == 0 then
		y += math.abs(math.sin(tt * 8)) * 0.25
		rz = math.sin(tt * 8) * 0.12
	elseif idle == "fly" then
		y += math.sin(tt * 2) * 0.35
		rz = math.sin(tt * 1.5) * 0.1
		rx = if walking then -0.08 else math.sin(tt * 1.1) * 0.04
	elseif idle == "twirl" then
		y += math.sin(tt * 2.5) * 0.12
		ry = math.sin(tt * 0.8) * 0.6
	elseif idle == "sway" then
		y += math.sin(tt * 2) * 0.08
		rz = math.sin(tt * 1.4) * 0.07
	else
		y += math.sin(tt * 3) * 0.12
		rz = math.sin(tt * 1.5) * 0.03
	end
	if dark then
		rx -= 0.1 -- lean in, menacing
		y -= 0.05
	end
	local cf = CFrame.new(0, y, 0) * CFrame.Angles(rx, ry, rz)
	if m:GetAttribute("Rogue") == true then
		-- Rogue (Phase 4): violent shake, no colour change (must not look like Dark)
		cf = CFrame.new(math.random(-10, 10) / 100, 0, math.random(-10, 10) / 100) * cf
	end
	return cf
end

function BrainrotAnimator.init() end

function BrainrotAnimator.start()
	for _, m in CollectionService:GetTagged("Brainrot") do
		track(m)
	end
	CollectionService:GetInstanceAddedSignal("Brainrot"):Connect(track)
	CollectionService:GetInstanceRemovedSignal("Brainrot"):Connect(untrack)

	local rainbowAcc = 0
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local camera = workspace.CurrentCamera
		local camPos = camera.CFrame.Position
		rainbowAcc += dt
		local doRainbow = rainbowAcc >= 1 / RAINBOW_HZ
		if doRainbow then
			rainbowAcc = 0
		end
		local cycle = Config.Variants.RAINBOW_CYCLE_SECONDS
		for model, e in entries do
			if not model.Parent then
				entries[model] = nil
				continue
			end
			local root = model.PrimaryPart
			if not root or (root.Position - camPos).Magnitude > MAX_DISTANCE then
				continue
			end
			if e.motor then
				e.motor.Transform = pose(e, t)
			end
			for _, s in e.spinners do
				local rps = (s:GetAttribute("Spin") :: number?) or 4
				s.Transform = CFrame.Angles(0, 0, t * rps * math.pi * 2)
			end
			if e.trail then
				e.trail.Enabled = model:GetAttribute("Walking") == true
			end
			if doRainbow and #e.rainbowParts > 0 then
				local shift = (t / cycle) % 1
				for i, p in e.rainbowParts do
					local base = p:GetAttribute("BaseColor") :: Color3?
					if base then
						local h, s, v = base:ToHSV()
						p.Color =
							Color3.fromHSV((h + shift + i * 0.015) % 1, math.max(s, 0.6), math.max(v, 0.55))
					end
				end
			end
		end
	end)
end

return BrainrotAnimator
