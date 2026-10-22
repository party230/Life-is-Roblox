--!strict
-- Builds the map from Config.Layout in classic Roblox style: studded baseplate, chunky bright blocks.
-- Vertical slice (Config.Game.VERTICAL_SLICE): plot 1 only, plus the plaza with the egg stall.
--
-- Each plot Model ("Plot1".., attribute Index) contains: Floor, Walls/*, Carpet, SpawnPortal, CarpetEnd,
-- Pedestals/Slot1..Slot14 (attributes Slot, Tier), Collector (+ BillboardGui "Label"), Sign (SurfaceGui),
-- Lane/* (escape lane), CarpetItems + Brainrots folders.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Parts = require(ReplicatedStorage.Shared.World.Parts)
local Plots = require(ReplicatedStorage.Shared.Logic.Plots)

local Builder = {}

local L = Config.Layout
local INK = "#000000"
local PLOT_COLORS = { "#2F8CFF", "#FF4F7B", "#2CC764", "#FFB21E", "#8B5CF6", "#FF7A2E", "#1FC1C1", "#E84DDB" }
local FLOOR_TOP = L.FLOOR_TOP

export type PlotRefs = {
	index: number,
	model: Model,
	origin: CFrame, -- plot centre at ground level, LookVector toward the plaza
	pedestals: { BasePart },
	collector: BasePart,
	collectorLabel: TextLabel,
	carpetItems: Folder,
	brainrots: Folder,
	signLabel: TextLabel,
}

function Builder.plotOrigin(index: number): CFrame
	local pose = Plots.pose(index)
	return CFrame.new(pose.x, 0, pose.z) * CFrame.Angles(0, pose.yaw, 0)
end

function Builder.at(origin: CFrame, x: number, y: number, z: number): CFrame
	return origin * CFrame.new(x, y, z)
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- stands a cylinder up

local function plotsToBuild(): { number }
	if Config.Game.VERTICAL_SLICE then
		return { 1 }
	end
	local out = {}
	for i = 1, Config.Game.PLOT_COUNT do
		table.insert(out, i)
	end
	return out
end

local function sign(parent: BasePart, face: Enum.NormalId, text: string, ppsOverride: number?): TextLabel
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Sign"
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = ppsOverride or 40
	surface.LightInfluence = 0
	surface.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromHex(INK)
	stroke.Parent = label
	label.Parent = surface
	return label
end

-- Palette (style reference: assets/reference/style.png)
local FLOOR_BLUE = "#2C7BE5"
local PATH_GREY = "#A3A2A5"
local CARPET_RED = "#E0262C"
local BUILDING = "#3B3F47"
local BUILDING_DARK = "#2B2E35"
local WINDOW = "#111318"

local function buildTrees(world: Folder)
	-- chunky voxel trees around the map edge
	local folder = Parts.folder("Trees", world)
	local r = Random.new(7)
	for i = 1, 28 do
		local angle = (i / 28) * math.pi * 2 + r:NextNumber(-0.05, 0.05)
		local radius = L.MAP_SIZE / 2 - r:NextNumber(18, 40)
		local base = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local h = r:NextNumber(6, 10)
		Parts.part({
			name = "Trunk",
			size = Vector3.new(3, h, 3),
			cframe = CFrame.new(base + Vector3.new(0, h / 2, 0)),
			color = "#7A4A24",
			studs = true,
			parent = folder,
		})
		for _, offset in
			{
				Vector3.new(0, h + 3, 0),
				Vector3.new(2.6, h + 1.5, 0.8),
				Vector3.new(-2.4, h + 1.8, -1),
				Vector3.new(0.6, h + 5.2, -0.4),
			}
		do
			local sz = r:NextNumber(5, 8)
			Parts.part({
				name = "Leaves",
				size = Vector3.new(sz, sz, sz),
				cframe = CFrame.new(base + offset),
				color = if r:NextNumber() > 0.5 then "#3FAF4A" else "#2E9440",
				studs = true,
				parent = folder,
			})
		end
	end
end

local function buildGround(world: Folder)
	Parts.part({
		name = "Baseplate",
		size = Vector3.new(L.MAP_SIZE, 2, L.MAP_SIZE),
		cframe = CFrame.new(0, -1, 0),
		color = FLOOR_BLUE,
		studs = true,
		parent = world,
	})
	Parts.part({
		name = "RingRoad",
		size = Vector3.new(
			0.3,
			(L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2) * 2,
			(L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2) * 2
		),
		cframe = CFrame.new(0, 0.15, 0) * UP,
		color = PATH_GREY,
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	Parts.part({
		name = "Plaza",
		size = Vector3.new(0.8, L.PLAZA_RADIUS * 2, L.PLAZA_RADIUS * 2),
		cframe = CFrame.new(0, 0.4, 0) * UP,
		color = "#C9C9CC",
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	-- fountain
	Parts.part({
		name = "FountainRim",
		size = Vector3.new(2.4, 24, 24),
		cframe = CFrame.new(0, 1.2, 0) * UP,
		color = "#8A8A8F",
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	Parts.part({
		name = "FountainWater",
		size = Vector3.new(2.5, 21, 21),
		cframe = CFrame.new(0, 1.3, 0) * UP,
		color = "#3FA9F5",
		material = Enum.Material.Glass,
		transparency = 0.25,
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	Parts.part({
		name = "FountainSpout",
		size = Vector3.new(7, 3, 3),
		cframe = CFrame.new(0, 4, 0) * UP,
		color = "#8A8A8F",
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	for _, i in plotsToBuild() do
		local origin = Builder.plotOrigin(i)
		local gate = Builder.at(origin, 0, 0, L.GATE.z).Position
		local inner = gate.Unit * (L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2)
		local mid = (gate + inner) / 2
		Parts.part({
			name = `Spoke{i}`,
			size = Vector3.new(14, 0.3, (gate - inner).Magnitude),
			cframe = CFrame.lookAt(Vector3.new(mid.X, 0.15, mid.Z), Vector3.new(0, 0.15, 0)),
			color = PATH_GREY,
			studs = true,
			parent = world,
		})
	end
	local belt = Parts.part({
		name = "PlazaDropBelt",
		size = Vector3.new(14, 1.2, 5),
		cframe = CFrame.new(L.PLAZA_DROP_BELT.x, 1.4, L.PLAZA_DROP_BELT.z),
		color = CARPET_RED,
		studs = true,
		parent = world,
	})
	Parts.billboard(belt, 5, { "PLAZA DROP" }, Vector2.new(8, 1.4))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(L.PLAZA_SPAWN.x, 0.9, L.PLAZA_SPAWN.z)
	spawn.Color = Color3.fromHex("#FFFFFF")
	spawn.Duration = 0
	spawn.Parent = world
	buildTrees(world)
end

-- Big floating world label (green text, thick black stroke), e.g. "Shop" over stalls.
local function floatingLabel(adornee: BasePart, text: string, color: string, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "FloatingLabel"
	gui.Adornee = adornee
	gui.Size = UDim2.fromScale(12, 3.2) -- studs, so it reads like part of the world
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 220
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = Color3.fromHex(color)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = adornee
end

-- Egg shop stall: wooden stall with a blue/white awning on a raised stone platform, merchant behind the counter.
local function buildStall(world: Folder)
	local pose = Plots.pose(1)
	local theta = math.atan2(pose.z, pose.x) + math.rad(L.STALL_ANGLE_OFFSET_DEG)
	local pos = Vector3.new(math.cos(theta) * L.STALL_RADIUS, 0.8, math.sin(theta) * L.STALL_RADIUS)
	local cf = CFrame.lookAt(pos, Vector3.new(0, 0.8, 0))
	local stall = Instance.new("Model")
	stall.Name = "EggStall"
	local function p(
		name: string,
		size: Vector3,
		offset: CFrame,
		color: string,
		mat: Enum.Material?,
		studs: boolean?
	): BasePart
		return Parts.part({
			name = name,
			size = size,
			cframe = cf * offset,
			color = color,
			material = mat,
			studs = studs,
			parent = stall,
		})
	end
	-- stone platform with a step
	p("Platform", Vector3.new(18, 1.6, 12), CFrame.new(0, 0.8, 1.5), "#9E9EA3", nil, true)
	p("Step", Vector3.new(18, 0.8, 2), CFrame.new(0, 0.4, -5.5), "#B4B4B8", nil, true)
	local y0 = 1.6
	local counter = p(
		"Counter",
		Vector3.new(12, 3, 2.4),
		CFrame.new(0, y0 + 1.5, -1),
		"#8A5A2E",
		Enum.Material.WoodPlanks
	)
	p(
		"CounterTop",
		Vector3.new(12.6, 0.5, 3),
		CFrame.new(0, y0 + 3.25, -1),
		"#A9743F",
		Enum.Material.WoodPlanks
	)
	for _, x in { -5.8, 5.8 } do
		for _, z in { -2, 4 } do
			p("Post", Vector3.new(0.8, 9, 0.8), CFrame.new(x, y0 + 4.5, z), "#6B4423", Enum.Material.Wood)
		end
	end
	p("Roof", Vector3.new(13, 0.6, 7.4), CFrame.new(0, y0 + 9.2, 1), "#6B4423", Enum.Material.WoodPlanks)
	-- blue / white striped awning sloping toward customers
	for i = 0, 6 do
		p(
			`Awning{i}`,
			Vector3.new(13.4 / 7, 0.5, 4.4),
			CFrame.new(-6.7 + 13.4 / 14 + i * 13.4 / 7, y0 + 8.4, -3.2) * CFrame.Angles(math.rad(-22), 0, 0),
			if i % 2 == 0 then "#2C7BE5" else "#FFFFFF"
		)
	end
	-- eggs on the counter
	for i, color in { "#FFF4E0", "#B98CFF", "#FFD23F" } do
		Parts.part({
			name = "Egg",
			size = Vector3.new(1.3, 1.7, 1.3),
			cframe = cf * CFrame.new(-3 + (i - 1) * 3, y0 + 4.4, -1.4),
			color = color,
			shape = Enum.PartType.Ball,
			parent = stall,
		})
	end
	-- merchant
	local npc = Instance.new("Model")
	npc.Name = "Egg Merchant"
	local torso = Parts.part({
		name = "Torso",
		size = Vector3.new(2, 2, 1),
		cframe = cf * CFrame.new(0, y0 + 4.2, 1.6),
		color = "#C98A55",
		parent = npc,
	})
	local head = Parts.part({
		name = "Head",
		size = Vector3.new(2, 1.2, 1.2),
		cframe = cf * CFrame.new(0, y0 + 5.8, 1.6),
		color = "#D9A066",
		parent = npc,
	})
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	Parts.part({
		name = "Hat",
		size = Vector3.new(2.3, 0.7, 1.5),
		cframe = cf * CFrame.new(0, y0 + 6.7, 1.6),
		color = "#2C7BE5",
		parent = npc,
	})
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = npc
	npc.PrimaryPart = torso
	npc.Parent = stall
	floatingLabel(counter, "Egg Shop", "#3DE05C", 10.5)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenEggs"
	prompt.ActionText = "Shop eggs"
	prompt.ObjectText = "Egg Merchant"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Opens", "Eggs")
	prompt.Parent = counter
	stall.Parent = world
end

-- Dark blocky building wall segment with a neon strip along the top and black window panels on the outside.
local function wall(
	origin: CFrame,
	parent: Instance,
	accent: string,
	x0: number,
	z0: number,
	x1: number,
	z1: number,
	height: number?
)
	local h = height or L.WALL_HEIGHT
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local sx, sz = math.max(2, math.abs(x1 - x0)), math.max(2, math.abs(z1 - z0))
	Parts.part({
		name = "Wall",
		size = Vector3.new(sx, h, sz),
		cframe = Builder.at(origin, cx, FLOOR_TOP + h / 2, cz),
		color = BUILDING,
		studs = true,
		parent = parent,
	})
	Parts.part({
		name = "Neon",
		size = Vector3.new(sx + 0.2, 0.5, sz + 0.2),
		cframe = Builder.at(origin, cx, FLOOR_TOP + h - 0.6, cz),
		color = accent,
		material = Enum.Material.Neon,
		canCollide = false,
		parent = parent,
	})
	Parts.part({
		name = "Cap",
		size = Vector3.new(sx + 0.6, 0.8, sz + 0.6),
		cframe = Builder.at(origin, cx, FLOOR_TOP + h + 0.4, cz),
		color = BUILDING_DARK,
		studs = true,
		parent = parent,
	})
	-- window panels every ~8 studs along the long side
	local long = math.max(sx, sz)
	local alongX = sx >= sz
	local n = math.floor(long / 8)
	for i = 1, n do
		local t = -long / 2 + (i - 0.5) * (long / n)
		local wx = if alongX then cx + t else cx
		local wz = if alongX then cz else cz + t
		Parts.part({
			name = "Window",
			size = if alongX
				then Vector3.new(5, h * 0.42, sz + 0.25)
				else Vector3.new(sx + 0.25, h * 0.42, 5),
			cframe = Builder.at(origin, wx, FLOOR_TOP + h * 0.55, wz),
			color = WINDOW,
			material = Enum.Material.Glass,
			canCollide = false,
			parent = parent,
		})
	end
end

local function buildPlot(index: number, world: Folder): PlotRefs
	local origin = Builder.plotOrigin(index)
	local accent = PLOT_COLORS[index]
	local model = Instance.new("Model")
	model.Name = `Plot{index}`
	model:SetAttribute("Index", index)
	local hw, hd = L.PLOT_WIDTH / 2, L.PLOT_DEPTH / 2

	Parts.part({
		name = "Floor",
		size = Vector3.new(L.PLOT_WIDTH, 1, L.PLOT_DEPTH),
		cframe = Builder.at(origin, 0, FLOOR_TOP - 0.5, 0),
		color = "#5A5E66",
		studs = true,
		parent = model,
	})

	-- building walls: back (taller), left, right (escape-lane gap) and front (gate gap)
	local walls = Parts.folder("Walls", model)
	wall(origin, walls, accent, -hw, hd, hw, hd, L.WALL_HEIGHT + 6)
	wall(origin, walls, accent, -hw, -hd, -hw, hd)
	wall(origin, walls, accent, hw, L.LANE_EXIT.zMax, hw, hd)
	wall(origin, walls, accent, hw, -hd, hw, L.LANE_EXIT.zMin)
	local g = L.GATE.width / 2
	wall(origin, walls, accent, -hw, -hd, -g - 1.5, -hd)
	wall(origin, walls, accent, g + 1.5, -hd, hw, -hd)
	for _, side in { -1, 1 } do
		Parts.part({
			name = "GatePillar",
			size = Vector3.new(3, L.WALL_HEIGHT + 3, 3),
			cframe = Builder.at(origin, side * (g + 1.5), FLOOR_TOP + (L.WALL_HEIGHT + 3) / 2, -hd),
			color = BUILDING_DARK,
			studs = true,
			parent = walls,
		})
		Parts.part({
			name = "GateNeon",
			size = Vector3.new(0.4, L.WALL_HEIGHT + 2, 3.2),
			cframe = Builder.at(
				origin,
				side * (g + 1.5) - side * 1.6,
				FLOOR_TOP + (L.WALL_HEIGHT + 2) / 2,
				-hd
			),
			color = accent,
			material = Enum.Material.Neon,
			canCollide = false,
			parent = walls,
		})
	end
	local beam = Parts.part({
		name = "GateBeam",
		size = Vector3.new(L.GATE.width + 6, 3, 3),
		cframe = Builder.at(origin, 0, FLOOR_TOP + L.WALL_HEIGHT + 1.5, -hd),
		color = BUILDING_DARK,
		studs = true,
		parent = walls,
	})
	local signLabel = sign(beam, Enum.NormalId.Front, "FREE PLOT")

	-- red studded carpet from the spawn portal to the front
	local c = L.CARPET
	local carpetLength = c.zStart - c.zEnd
	Parts.part({
		name = "Carpet",
		size = Vector3.new(c.width, 0.4, carpetLength),
		cframe = Builder.at(origin, c.x, FLOOR_TOP + 0.2, (c.zStart + c.zEnd) / 2),
		color = CARPET_RED,
		studs = true,
		parent = model,
	})

	-- spawn portal: dark arch, swirling purple disc, screen board above
	local portalZ = L.PORTAL.z
	for _, side in { -1, 1 } do
		Parts.part({
			name = "PortalPillar",
			size = Vector3.new(2, 11, 2),
			cframe = Builder.at(origin, side * 5.6, FLOOR_TOP + 5.5, portalZ),
			color = BUILDING_DARK,
			studs = true,
			parent = model,
		})
	end
	Parts.part({
		name = "PortalTop",
		size = Vector3.new(13.2, 2, 2),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 12, portalZ),
		color = BUILDING_DARK,
		studs = true,
		parent = model,
	})
	local disc = Parts.part({
		name = "SpawnPortal",
		size = Vector3.new(0.4, 9.5, 9.5),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 5.6, portalZ) * CFrame.Angles(0, math.rad(90), 0),
		color = "#8A3CFF",
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		canCollide = false,
		transparency = 0.1,
		parent = model,
	})
	local swirl = Instance.new("ParticleEmitter")
	swirl.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255))
	swirl.LightEmission = 1
	swirl.Rate = 30
	swirl.Lifetime = NumberRange.new(0.6, 1.2)
	swirl.Speed = NumberRange.new(1, 3)
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	swirl.Parent = disc
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 110, 255)
	light.Range = 18
	light.Brightness = 2
	light.Parent = disc
	local screen = Parts.part({
		name = "PortalScreen",
		size = Vector3.new(14, 5, 0.6),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 15.5, portalZ),
		color = WINDOW,
		parent = model,
	})
	sign(screen, Enum.NormalId.Front, "NEW BRAINROTS EVERY FEW SECONDS!", 30)
	Parts.part({
		name = "CarpetEnd",
		size = Vector3.new(c.width, 0.5, 1.2),
		cframe = Builder.at(origin, c.x, FLOOR_TOP + 0.25, c.zEnd - 0.6),
		color = "#FFD23F",
		material = Enum.Material.Neon,
		parent = model,
	})

	-- pedestals: round, with a neon rim in the occupant's rarity colour
	local pedFolder = Parts.folder("Pedestals", model)
	local pedestals: { BasePart } = {}
	for slot, def in L.SLOTS do
		local locked = def.tier > 0
		local p = Parts.part({
			name = `Slot{slot}`,
			size = Vector3.new(L.PEDESTAL_HEIGHT, L.PEDESTAL_SIZE, L.PEDESTAL_SIZE),
			cframe = Builder.at(origin, def.x, FLOOR_TOP + L.PEDESTAL_HEIGHT / 2, def.z) * UP,
			color = if locked then "#6E717A" else "#D8D8DC",
			shape = Enum.PartType.Cylinder,
			transparency = if locked then 0.5 else 0,
			parent = pedFolder,
		})
		p:SetAttribute("Slot", slot)
		p:SetAttribute("Tier", def.tier)
		local rim = Parts.part({
			name = "Rim",
			size = Vector3.new(0.3, L.PEDESTAL_SIZE + 0.4, L.PEDESTAL_SIZE + 0.4),
			cframe = Builder.at(origin, def.x, FLOOR_TOP + 0.2, def.z) * UP,
			color = if locked then "#4A4D55" else "#2F8CFF",
			material = Enum.Material.Neon,
			shape = Enum.PartType.Cylinder,
			canCollide = false,
			transparency = if locked then 0.6 else 0.2,
			parent = p,
		})
		rim:SetAttribute("Slot", slot)
		if locked then
			Parts.billboard(p, 2.5, { `🔒 Extra Slots {string.rep("I", def.tier)}` }, Vector2.new(6, 1))
		end
		pedestals[slot] = p
	end

	-- cash collector
	local cc = L.COLLECTOR
	local collector = Parts.part({
		name = "Collector",
		size = Vector3.new(cc.width, 0.5, cc.depth),
		cframe = Builder.at(origin, cc.x, FLOOR_TOP + 0.25, cc.z),
		color = "#FFD23F",
		material = Enum.Material.Neon,
		parent = model,
	})
	local _, collectorLabels = Parts.billboard(collector, 4, { "$0" }, Vector2.new(7, 1.8))
	collectorLabels[1].TextColor3 = Color3.fromHex("#7CFF9B")
	Parts.billboard(collector, 2.2, { "COLLECT" }, Vector2.new(5, 1))

	-- escape lane: floating obby blocks out of the right-wall gap
	local lane = Parts.folder("Lane", model)
	local laneColors = { "#FF4F7B", "#FFD23F", "#2CC764", "#8B5CF6", "#FF7A2E", "#1FC1C1" }
	local laneZ = (L.LANE_EXIT.zMin + L.LANE_EXIT.zMax) / 2
	for i = 1, L.LANE_BLOCKS do
		Parts.part({
			name = `LaneBlock{i}`,
			size = Vector3.new(5, 1, 6),
			cframe = Builder.at(
				origin,
				hw + 2 + i * 7,
				FLOOR_TOP + 0.5 + (i % 2) * 1.5,
				laneZ + (if i % 2 == 0 then 1.5 else -1.5)
			),
			color = laneColors[(i - 1) % #laneColors + 1],
			studs = true,
			parent = lane,
		})
	end
	local laneSign = Parts.part({
		name = "LaneSign",
		size = Vector3.new(0.4, 2.5, 7),
		cframe = Builder.at(origin, hw + 1.9, FLOOR_TOP + L.WALL_HEIGHT - 2, laneZ),
		color = WINDOW,
		parent = lane,
	})
	sign(laneSign, Enum.NormalId.Right, "ESCAPE LANE →", 30)

	local carpetItems = Parts.folder("CarpetItems", model)
	local brainrots = Parts.folder("Brainrots", model)
	model.PrimaryPart = model:FindFirstChild("Floor") :: BasePart
	model.Parent = world

	return {
		index = index,
		model = model,
		origin = origin,
		pedestals = pedestals,
		collector = collector,
		collectorLabel = collectorLabels[1],
		carpetItems = carpetItems,
		brainrots = brainrots,
		signLabel = signLabel,
	}
end

-- Builds everything once. Returns refs by plot index (only built plots are present).
function Builder.build(): { [number]: PlotRefs }
	local existing = workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	local world = Parts.folder("World", workspace)
	buildGround(world)
	buildStall(world)
	local plots: { [number]: PlotRefs } = {}
	for _, i in plotsToBuild() do
		plots[i] = buildPlot(i, world)
	end
	return plots
end

-- Top centre of a pedestal; brainrots face the plot front (gate).
function Builder.pedestalTop(refs: PlotRefs, slot: number): CFrame
	local def = L.SLOTS[slot]
	return Builder.at(refs.origin, def.x, FLOOR_TOP + L.PEDESTAL_HEIGHT, def.z)
end

function Builder.spawnCFrame(refs: PlotRefs): CFrame
	return Builder.at(refs.origin, L.SPAWN.x, FLOOR_TOP + 3, L.SPAWN.z)
end

-- Carpet path ends (walking toward the front = the model's facing direction).
function Builder.carpetStart(refs: PlotRefs): CFrame
	return Builder.at(refs.origin, L.CARPET.x, FLOOR_TOP + 0.3, L.CARPET.zStart)
end

function Builder.carpetEnd(refs: PlotRefs): CFrame
	return Builder.at(refs.origin, L.CARPET.x, FLOOR_TOP + 0.3, L.CARPET.zEnd)
end

-- Pedestal rim (lights up in the occupant's rarity colour).
function Builder.rim(refs: PlotRefs, slot: number): BasePart?
	return refs.pedestals[slot] and refs.pedestals[slot]:FindFirstChild("Rim") :: BasePart?
end

return Builder
