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
local INK = "#1B1530"
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

local function buildGround(world: Folder)
	Parts.part({
		name = "Baseplate",
		size = Vector3.new(L.MAP_SIZE, 2, L.MAP_SIZE),
		cframe = CFrame.new(0, -1, 0),
		color = "#4CB848",
		studs = true,
		parent = world,
	})
	Parts.part({
		name = "RingRoad",
		size = Vector3.new(
			0.2,
			(L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2) * 2,
			(L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2) * 2
		),
		cframe = CFrame.new(0, 0.05, 0) * UP,
		color = "#E8D49A",
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	Parts.part({
		name = "Plaza",
		size = Vector3.new(0.8, L.PLAZA_RADIUS * 2, L.PLAZA_RADIUS * 2),
		cframe = CFrame.new(0, 0.4, 0) * UP,
		color = "#D9D4C7",
		material = Enum.Material.Plastic,
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	-- fountain
	Parts.part({
		name = "FountainRim",
		size = Vector3.new(2.4, 24, 24),
		cframe = CFrame.new(0, 1.2, 0) * UP,
		color = "#BFB8A8",
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
		color = "#BFB8A8",
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	-- spokes from the ring road to each built plot's gate
	for _, i in plotsToBuild() do
		local origin = Builder.plotOrigin(i)
		local gate = Builder.at(origin, 0, 0, L.GATE.z).Position
		local inner = gate.Unit * (L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2)
		local mid = (gate + inner) / 2
		Parts.part({
			name = `Spoke{i}`,
			size = Vector3.new(12, 0.2, (gate - inner).Magnitude),
			cframe = CFrame.lookAt(Vector3.new(mid.X, 0.06, mid.Z), Vector3.new(0, 0.06, 0)),
			color = "#E8D49A",
			parent = world,
		})
	end
	-- plaza drop belt
	local belt = Parts.part({
		name = "PlazaDropBelt",
		size = Vector3.new(14, 1.2, 5),
		cframe = CFrame.new(L.PLAZA_DROP_BELT.x, 1.4, L.PLAZA_DROP_BELT.z),
		color = "#B3202A",
		material = Enum.Material.Fabric,
		parent = world,
	})
	Parts.billboard(belt, 5, { "PLAZA DROP" }, Vector2.new(8, 1.4))
	-- neutral spawn on the plaza
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(L.PLAZA_SPAWN.x, 0.9, L.PLAZA_SPAWN.z)
	spawn.Color = Color3.fromHex("#FFFFFF")
	spawn.Duration = 0
	spawn.Parent = world
end

-- Egg stall + merchant on the plaza edge, toward plot 1. The prompt opens the Eggs screen on the client.
local function buildStall(world: Folder)
	local pose = Plots.pose(1)
	local theta = math.atan2(pose.z, pose.x) + math.rad(L.STALL_ANGLE_OFFSET_DEG)
	local pos = Vector3.new(math.cos(theta) * L.STALL_RADIUS, 0.8, math.sin(theta) * L.STALL_RADIUS)
	-- face the plaza centre
	local cf = CFrame.lookAt(pos, Vector3.new(0, 0.8, 0))
	local stall = Instance.new("Model")
	stall.Name = "EggStall"
	local function p(
		name: string,
		size: Vector3,
		offset: CFrame,
		color: string,
		mat: Enum.Material?
	): BasePart
		return Parts.part({
			name = name,
			size = size,
			cframe = cf * offset,
			color = color,
			material = mat,
			parent = stall,
		})
	end
	local counter =
		p("Counter", Vector3.new(10, 3, 3), CFrame.new(0, 1.5, 0), "#8A5A2E", Enum.Material.WoodPlanks)
	p("CounterTop", Vector3.new(10.6, 0.4, 3.6), CFrame.new(0, 3.2, 0), "#F2E3C6")
	for _, x in { -4.8, 4.8 } do
		p("Post", Vector3.new(0.6, 8, 0.6), CFrame.new(x, 4, 1.4), "#6B4423", Enum.Material.Wood)
	end
	-- striped awning
	for i = 0, 5 do
		p(
			`Awning{i}`,
			Vector3.new(1.84, 0.4, 5),
			CFrame.new(-4.6 + i * 1.84, 8.2, 0) * CFrame.Angles(math.rad(-12), 0, 0),
			if i % 2 == 0 then "#FF4F7B" else "#FFFFFF"
		)
	end
	local board = p("SignBoard", Vector3.new(8, 1.6, 0.3), CFrame.new(0, 9.6, 1.4), "#FFD23F")
	sign(board, Enum.NormalId.Front, "EGG STALL")
	-- eggs on the counter
	for i, color in { "#FFF4E0", "#B98CFF", "#FFD23F" } do
		Parts.part({
			name = "Egg",
			size = Vector3.new(1.2, 1.6, 1.2),
			cframe = cf * CFrame.new(-3 + i * 1.6, 4.2, -0.6),
			color = color,
			shape = Enum.PartType.Ball,
			parent = stall,
		})
	end
	-- merchant: a simple blocky NPC behind the counter
	local npc = Instance.new("Model")
	npc.Name = "Egg Merchant"
	local torso = Parts.part({
		name = "Torso",
		size = Vector3.new(2, 2, 1),
		cframe = cf * CFrame.new(0, 4.5, 2),
		color = "#FF8A3D",
		parent = npc,
	})
	local head = Parts.part({
		name = "Head",
		size = Vector3.new(2, 1, 1),
		cframe = cf * CFrame.new(0, 6, 2),
		color = "#FFD9B0",
		parent = npc,
	})
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	Parts.part({
		name = "Hat",
		size = Vector3.new(2.2, 0.6, 1.4),
		cframe = cf * CFrame.new(0, 6.8, 2),
		color = "#FF4F7B",
		parent = npc,
	})
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.Parent = npc
	npc.PrimaryPart = torso
	npc.Parent = stall
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

local function wall(
	origin: CFrame,
	parent: Instance,
	color: string,
	x0: number,
	z0: number,
	x1: number,
	z1: number
)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	Parts.part({
		name = "Wall",
		size = Vector3.new(math.max(1.4, math.abs(x1 - x0)), L.WALL_HEIGHT, math.max(1.4, math.abs(z1 - z0))),
		cframe = Builder.at(origin, cx, FLOOR_TOP + L.WALL_HEIGHT / 2, cz),
		color = color,
		studs = true,
		parent = parent,
	})
end

local function buildPlot(index: number, world: Folder): PlotRefs
	local origin = Builder.plotOrigin(index)
	local color = PLOT_COLORS[index]
	local model = Instance.new("Model")
	model.Name = `Plot{index}`
	model:SetAttribute("Index", index)
	local hw, hd = L.PLOT_WIDTH / 2, L.PLOT_DEPTH / 2

	Parts.part({
		name = "Floor",
		size = Vector3.new(L.PLOT_WIDTH, 1, L.PLOT_DEPTH),
		cframe = Builder.at(origin, 0, FLOOR_TOP - 0.5, 0),
		color = "#C8C8C8",
		studs = true,
		parent = model,
	})

	-- walls: back, left, right (with the escape-lane gap) and front (with the gate gap)
	local walls = Parts.folder("Walls", model)
	wall(origin, walls, color, -hw, hd, hw, hd)
	wall(origin, walls, color, -hw, -hd, -hw, hd)
	wall(origin, walls, color, hw, L.LANE_EXIT.zMax, hw, hd)
	wall(origin, walls, color, hw, -hd, hw, L.LANE_EXIT.zMin)
	local g = L.GATE.width / 2
	wall(origin, walls, color, -hw, -hd, -g - 1, -hd)
	wall(origin, walls, color, g + 1, -hd, hw, -hd)
	for _, side in { -1, 1 } do
		Parts.part({
			name = "GatePillar",
			size = Vector3.new(2.4, 10, 2.4),
			cframe = Builder.at(origin, side * (g + 1.2), FLOOR_TOP + 5, -hd),
			color = color,
			studs = true,
			parent = walls,
		})
	end
	local beam = Parts.part({
		name = "GateBeam",
		size = Vector3.new(L.GATE.width + 5, 2.4, 2.4),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 11.2, -hd),
		color = "#FFD23F",
		studs = true,
		parent = walls,
	})
	local signLabel = sign(beam, Enum.NormalId.Front, "FREE PLOT")

	-- red carpet conveyor from the spawn portal at the back to the end at the front
	local c = L.CARPET
	local carpetLength = c.zStart - c.zEnd
	Parts.part({
		name = "Carpet",
		size = Vector3.new(c.width, 0.3, carpetLength),
		cframe = Builder.at(origin, c.x, FLOOR_TOP + 0.15, (c.zStart + c.zEnd) / 2),
		color = "#C8242C",
		material = Enum.Material.Fabric,
		parent = model,
	})
	for _, side in { -1, 1 } do
		Parts.part({
			name = "CarpetTrim",
			size = Vector3.new(0.4, 0.4, carpetLength),
			cframe = Builder.at(
				origin,
				c.x + side * (c.width / 2 + 0.2),
				FLOOR_TOP + 0.2,
				(c.zStart + c.zEnd) / 2
			),
			color = "#E8B530",
			material = Enum.Material.Foil,
			parent = model,
		})
	end
	-- spawn portal arch with a swirling disc
	local portalZ = L.PORTAL.z
	for _, side in { -1, 1 } do
		Parts.part({
			name = "PortalPillar",
			size = Vector3.new(1.6, 9, 1.6),
			cframe = Builder.at(origin, side * 4.4, FLOOR_TOP + 4.5, portalZ),
			color = "#3A2A6B",
			studs = true,
			parent = model,
		})
	end
	Parts.part({
		name = "PortalTop",
		size = Vector3.new(10.4, 1.6, 1.6),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 9.6, portalZ),
		color = "#3A2A6B",
		studs = true,
		parent = model,
	})
	local disc = Parts.part({
		name = "SpawnPortal",
		size = Vector3.new(0.4, 8, 8),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 4.6, portalZ) * CFrame.Angles(0, math.rad(90), 0),
		color = "#9B5CFF",
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		canCollide = false,
		transparency = 0.15,
		parent = model,
	})
	local swirl = Instance.new("ParticleEmitter")
	swirl.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255))
	swirl.LightEmission = 1
	swirl.Rate = 25
	swirl.Lifetime = NumberRange.new(0.6, 1.2)
	swirl.Speed = NumberRange.new(1, 3)
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	swirl.Parent = disc
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 110, 255)
	light.Range = 16
	light.Brightness = 2
	light.Parent = disc
	-- carpet end marker (brainrots that reach it vanish)
	Parts.part({
		name = "CarpetEnd",
		size = Vector3.new(c.width + 1, 0.4, 1.2),
		cframe = Builder.at(origin, c.x, FLOOR_TOP + 0.2, c.zEnd - 0.6),
		color = "#FFD23F",
		material = Enum.Material.Neon,
		parent = model,
	})

	-- pedestals: round, with a rarity-coloured rim that lights up when occupied
	local pedFolder = Parts.folder("Pedestals", model)
	local pedestals: { BasePart } = {}
	for slot, def in L.SLOTS do
		local locked = def.tier > 0
		local p = Parts.part({
			name = `Slot{slot}`,
			size = Vector3.new(L.PEDESTAL_HEIGHT, L.PEDESTAL_SIZE, L.PEDESTAL_SIZE),
			cframe = Builder.at(origin, def.x, FLOOR_TOP + L.PEDESTAL_HEIGHT / 2, def.z) * UP,
			color = if locked then "#9C9C9C" else "#F4F4F4",
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
			color = if locked then "#6B6B6B" else "#2F8CFF",
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

	-- escape lane: floating obby blocks heading out of the right-wall gap
	local lane = Parts.folder("Lane", model)
	local laneColors = { "#FF4F7B", "#FFD23F", "#2F8CFF", "#2CC764", "#8B5CF6", "#FF7A2E" }
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
		size = Vector3.new(0.4, 2, 6),
		cframe = Builder.at(origin, hw + 0.5, FLOOR_TOP + 6.5, laneZ),
		color = "#FFFFFF",
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
