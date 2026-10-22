--!strict
-- Client-side brainrot animation (cheap, no Animator assets needed): idle bob / sway / fly / twirl,
-- a waddle while walking the carpet, spinning propellers, Rainbow band scrolling + trail, the Evil variant's
-- slow menacing idle and red lightning (D36), and the Rogue shake (Phase 4). Drives each model's
-- Root.Anim Motor6D .Transform. Lightning parts are client-only and never replicate.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EvilBolts = require(ReplicatedStorage.Shared.World.EvilBolts)
local VariantLook = require(ReplicatedStorage.Shared.World.VariantLook)

local BrainrotAnimator = {}

type Entry = {
	model: Model,
	motor: Motor6D?,
	spinners: { Motor6D },
	rainbowParts: { BasePart },
	trail: Trail?,
	phase: number,
	evil: boolean,
	bolts: { BasePart }?, -- pooled lightning segments (Evil only, created on first strike)
	nextStrike: number,
	hideBoltsAt: number,
}

local entries: { [Model]: Entry } = {}
local MAX_DISTANCE = 160
local RAINBOW_HZ = 12
local BOLT_VISIBLE_SECONDS = 0.07
local BOLT_THICKNESS = 0.09

local boltFolder: Folder? = nil
local rng = Random.new()
local function rand(): number
	return rng:NextNumber()
end

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
		elseif d:IsA("BasePart") and d:GetAttribute("RainbowBand") ~= nil then
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
		evil = CollectionService:HasTag(model, "EvilVariant"),
		bolts = nil,
		nextStrike = 0,
		hideBoltsAt = 0,
	}
end

local function untrack(model: Instance)
	local e = entries[model :: Model]
	if e and e.bolts then
		for _, b in e.bolts do
			b:Destroy()
		end
	end
	entries[model :: Model] = nil
end

local function hideBolts(e: Entry)
	local bolts = e.bolts
	if not bolts then
		return
	end
	for _, b in bolts do
		b.Transparency = 1
	end
end

-- One lightning strike around an Evil brainrot: reposition the pooled neon segments.
local function strike(e: Entry, root: BasePart, now: number)
	local V = Config.Variants
	if not e.bolts then
		local pool: { BasePart } = {}
		local folder = boltFolder :: Folder
		for _ = 1, EvilBolts.maxSegments(V.EVIL_BOLTS) do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromHex(V.EVIL_BOLT_COLOR)
			p.Transparency = 1
			p.Parent = folder
			table.insert(pool, p)
		end
		e.bolts = pool
	end
	local pool = e.bolts :: { BasePart }
	local segs = EvilBolts.strike(rand, root.Size, V.EVIL_BOLTS)
	for i, b in pool do
		local seg = segs[i]
		if seg then
			b.Size = Vector3.new(BOLT_THICKNESS, BOLT_THICKNESS, seg.length + BOLT_THICKNESS)
			b.CFrame = root.CFrame * seg.cframe
			b.Transparency = 0
		else
			b.Transparency = 1
		end
	end
	e.hideBoltsAt = now + BOLT_VISIBLE_SECONDS
	local gap = V.EVIL_BOLT_INTERVAL
	e.nextStrike = now + gap[1] + rand() * (gap[2] - gap[1])
end

local function pose(e: Entry, t: number): CFrame
	local m = e.model
	local hover = (m:GetAttribute("Hover") :: number?) or 0
	local idle = (m:GetAttribute("Idle") :: string?) or "bob"
	local walking = m:GetAttribute("Walking") == true
	local dark = e.evil
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
		-- Rogue (Phase 4): violent shake, no colour change (must not look like Evil)
		cf = CFrame.new(math.random(-10, 10) / 100, 0, math.random(-10, 10) / 100) * cf
	end
	return cf
end

function BrainrotAnimator.init() end

function BrainrotAnimator.start()
	local folder = Instance.new("Folder")
	folder.Name = "EvilLightning"
	folder.Parent = workspace
	boltFolder = folder
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
				hideBolts(e)
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
				-- bands scroll upward: each colour climbs one band every cycle / #bands seconds
				local shift = math.floor((t + e.phase) / cycle * #Config.Variants.RAINBOW_BANDS)
				for _, p in e.rainbowParts do
					p.Color = VariantLook.rainbowColor(p:GetAttribute("RainbowBand") :: number, shift)
				end
			end
			if e.evil then
				if t >= e.nextStrike then
					strike(e, root, t)
				elseif e.bolts and t >= e.hideBoltsAt then
					hideBolts(e)
				end
			end
		end
	end)
end

return BrainrotAnimator
