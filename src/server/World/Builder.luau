--!strict
-- Builds the map from Config.Layout: ground, plaza, ring road and the 8 plots. Placeholder low-poly geometry;
-- final art can replace any piece as long as the named parts/attributes below stay.
--
-- Each plot Model ("Plot1".."Plot8", attribute Index) contains:
--   Floor, Walls/*, Pedestals/Slot1..Slot14 (attribute Slot), Collector (+ BillboardGui "Label"),
--   Conveyor + BeltItems folder, Sign (SurfaceGui "Name"), EggStand, Brainrots folder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Plots = require(ReplicatedStorage.Shared.Logic.Plots)
local Parts = require(ReplicatedStorage.Shared.World.Parts)

local Builder = {}

local L = Config.Layout
local INK = "#1B1530"
local PLOT_COLORS = { "#4DA3FF", "#FF5C8A", "#3DDC84", "#FFB428", "#8B5CF6", "#FF8A3D", "#2EC4C4", "#E84DDB" }
local FLOOR_TOP = 1 -- plot floor top surface height

export type PlotRefs = {
	index: number,
	model: Model,
	origin: CFrame, -- plot centre at ground level, LookVector toward the plaza
	pedestals: { BasePart },
	collector: BasePart,
	collectorLabel: TextLabel,
	conveyor: BasePart,
	beltItems: Folder,
	brainrots: Folder,
	signLabel: TextLabel,
	eggStand: BasePart,
}

function Builder.plotOrigin(index: number): CFrame
	local pose = Plots.pose(index)
	return CFrame.new(pose.x, 0, pose.z) * CFrame.Angles(0, pose.yaw, 0)
end

-- Plot-local position -> world CFrame (same orientation as the plot).
function Builder.at(origin: CFrame, x: number, y: number, z: number): CFrame
	return origin * CFrame.new(x, y, z)
end

local function buildGround(world: Folder)
	Parts.part({
		name = "Ground",
		size = Vector3.new(L.MAP_SIZE, 2, L.MAP_SIZE),
		cframe = CFrame.new(0, -1, 0),
		color = "#7BD957",
		material = Enum.Material.Grass,
		parent = world,
	})
	-- ring road + plaza (cylinders lie on their side, so rotate to stand up)
	local up = CFrame.Angles(0, 0, math.rad(90))
	Parts.part({
		name = "RingRoad",
		size = Vector3.new(
			0.2,
			(L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2) * 2,
			(L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2) * 2
		),
		cframe = CFrame.new(0, 0.05, 0) * up,
		color = "#F2D9A0",
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	Parts.part({
		name = "Plaza",
		size = Vector3.new(0.6, L.PLAZA_RADIUS * 2, L.PLAZA_RADIUS * 2),
		cframe = CFrame.new(0, 0.3, 0) * up,
		color = "#EDE4D3",
		material = Enum.Material.Slate,
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	Parts.part({
		name = "Fountain",
		size = Vector3.new(3, 22, 22),
		cframe = CFrame.new(0, 1.5, 0) * up,
		color = "#4DA3FF",
		material = Enum.Material.Glass,
		transparency = 0.2,
		shape = Enum.PartType.Cylinder,
		parent = world,
	})
	-- spokes from the ring road to each plot gate
	for i = 1, Config.Game.PLOT_COUNT do
		local origin = Builder.plotOrigin(i)
		local gate = Builder.at(origin, 0, 0, L.GATE.z).Position
		local inner = gate.Unit * (L.RING_ROAD_RADIUS + L.RING_ROAD_WIDTH / 2)
		local mid = (gate + inner) / 2
		local length = (gate - inner).Magnitude
		Parts.part({
			name = `Spoke{i}`,
			size = Vector3.new(10, 0.2, length),
			cframe = CFrame.lookAt(Vector3.new(mid.X, 0.06, mid.Z), Vector3.new(0, 0.06, 0)),
			color = "#F2D9A0",
			parent = world,
		})
	end
	-- plaza drop belt
	local belt = Parts.part({
		name = "PlazaDropBelt",
		size = Vector3.new(14, 1.2, 4),
		cframe = CFrame.new(L.PLAZA_DROP_BELT.x, 1.2, L.PLAZA_DROP_BELT.z),
		color = "#3A3F55",
		parent = world,
	})
	Parts.billboard(belt, 4, { "PLAZA DROP" }, Vector2.new(8, 1.4))
	-- neutral spawn on the plaza (before a plot is picked)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(L.PLAZA_SPAWN.x, 0.6, L.PLAZA_SPAWN.z)
	spawn.Color = Color3.fromHex("#EDE4D3")
	spawn.Material = Enum.Material.Slate
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Duration = 0
	spawn.Parent = world
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
	local sx, sz = math.max(1, math.abs(x1 - x0)), math.max(1, math.abs(z1 - z0))
	Parts.part({
		name = "Wall",
		size = Vector3.new(sx, L.WALL_HEIGHT, sz),
		cframe = Builder.at(origin, cx, FLOOR_TOP + L.WALL_HEIGHT / 2, cz),
		color = color,
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
		color = "#E9E2CF",
		parent = model,
	})

	local walls = Parts.folder("Walls", model)
	wall(origin, walls, color, -hw, hd, hw, hd) -- back
	wall(origin, walls, color, -hw, -hd, -hw, hd) -- left
	-- right wall with the escape-lane gap
	wall(origin, walls, color, hw, L.LANE_EXIT.zMax, hw, hd)
	wall(origin, walls, color, hw, -hd, hw, L.LANE_EXIT.zMin)
	-- front wall with the gate gap
	local g = L.GATE.width / 2
	wall(origin, walls, color, -hw, -hd, -g - 1, -hd)
	wall(origin, walls, color, g + 1, -hd, hw, -hd)
	for _, side in { -1, 1 } do
		Parts.part({
			name = "GatePillar",
			size = Vector3.new(2, 7, 2),
			cframe = Builder.at(origin, side * (g + 1), FLOOR_TOP + 3.5, -hd),
			color = "#3A86D9",
			parent = walls,
		})
	end
	Parts.part({
		name = "GateBeam",
		size = Vector3.new(L.GATE.width + 4, 1.4, 2),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 7.7, -hd),
		color = "#FF8A3D",
		parent = walls,
	})

	-- sign on the gate beam
	local sign = Parts.part({
		name = "Sign",
		size = Vector3.new(L.GATE.width + 3, 1.2, 0.2),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 7.7, -hd - 1.05),
		color = "#FF8A3D",
		canCollide = false,
		parent = model,
	})
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Name"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.LightInfluence = 0
	surface.Parent = sign
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.FredokaOne
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.Text = "FREE PLOT"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromHex(INK)
	stroke.Parent = signLabel
	signLabel.Parent = surface

	-- pedestals
	local pedFolder = Parts.folder("Pedestals", model)
	local pedestals: { BasePart } = {}
	for slot, def in L.SLOTS do
		local p = Parts.part({
			name = `Slot{slot}`,
			size = Vector3.new(L.PEDESTAL_SIZE, L.PEDESTAL_HEIGHT, L.PEDESTAL_SIZE),
			cframe = Builder.at(origin, def.x, FLOOR_TOP + L.PEDESTAL_HEIGHT / 2, def.z),
			color = if def.tier == 0 then "#F7F3EA" else "#C9C2B0",
			transparency = if def.tier == 0 then 0 else 0.55,
			parent = pedFolder,
		})
		p:SetAttribute("Slot", slot)
		p:SetAttribute("Tier", def.tier)
		pedestals[slot] = p
	end

	-- cash collector
	local c = L.COLLECTOR
	local collector = Parts.part({
		name = "Collector",
		size = Vector3.new(c.width, 0.4, c.depth),
		cframe = Builder.at(origin, c.x, FLOOR_TOP + 0.2, c.z),
		color = "#FFD23F",
		material = Enum.Material.Neon,
		parent = model,
	})
	local _, collectorLabels = Parts.billboard(collector, 4, { "$0" }, Vector2.new(6, 1.6))
	collectorLabels[1].TextColor3 = Color3.fromHex("#7CFF9B")

	-- conveyor belt along the back wall
	local conveyor = Parts.part({
		name = "Conveyor",
		size = Vector3.new(L.CONVEYOR.length, 1, L.CONVEYOR.depth),
		cframe = Builder.at(origin, 0, FLOOR_TOP + 0.5, L.CONVEYOR.z),
		color = "#3A3F55",
		parent = model,
	})
	for _, side in { -1, 1 } do
		Parts.part({
			name = "Roller",
			size = Vector3.new(1.5, 1.6, L.CONVEYOR.depth + 1),
			cframe = Builder.at(origin, side * (L.CONVEYOR.length / 2 + 0.75), FLOOR_TOP + 0.8, L.CONVEYOR.z),
			color = "#FFD23F",
			parent = model,
		})
	end

	-- temporary egg stand (in-world prompts until the Eggs screen ships)
	local eggStand = Parts.part({
		name = "EggStand",
		size = Vector3.new(4, 3, 3),
		cframe = Builder.at(origin, L.EGG_STAND.x, FLOOR_TOP + 1.5, L.EGG_STAND.z),
		color = "#FFF4E0",
		parent = model,
	})

	local beltItems = Parts.folder("BeltItems", model)
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
		conveyor = conveyor,
		beltItems = beltItems,
		brainrots = brainrots,
		signLabel = signLabel,
		eggStand = eggStand,
	}
end

-- Builds everything once. Returns refs for each plot by index.
function Builder.build(): { PlotRefs }
	local existing = workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	local world = Parts.folder("World", workspace)
	buildGround(world)
	local plots: { PlotRefs } = {}
	for i = 1, Config.Game.PLOT_COUNT do
		plots[i] = buildPlot(i, world)
	end
	return plots
end

-- Top of a pedestal, facing the plot front (toward the gate / plaza).
function Builder.pedestalTop(refs: PlotRefs, slot: number): CFrame
	local def = L.SLOTS[slot]
	return Builder.at(refs.origin, def.x, FLOOR_TOP + L.PEDESTAL_HEIGHT, def.z)
end

function Builder.spawnCFrame(refs: PlotRefs): CFrame
	return Builder.at(refs.origin, L.SPAWN.x, FLOOR_TOP + 3, L.SPAWN.z)
end

-- Belt item positions, evenly spaced along the conveyor.
function Builder.beltSlot(refs: PlotRefs, i: number, count: number): CFrame
	local span = L.CONVEYOR.length - 6
	local x = -span / 2 + (i - 1) * span / math.max(1, count - 1)
	return Builder.at(refs.origin, x, FLOOR_TOP + 1, L.CONVEYOR.z)
end

return Builder
