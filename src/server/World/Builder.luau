--!strict
-- Builds the map from Config.Layout (D38): blue studded baseplate, a meadow ring with 12 spoke paths, decor and
-- landmarks, the central hub (World/Hub), and 12 bases in a ring with their gates facing the hub.
--
-- Each base Model ("Plot1".., attribute Index) contains: Floor, Walls, Pedestals/Slot1..Slot14 (attributes Slot,
-- Tier, child Rim), Collector (+ "$" label), gate beam Sign, escape exits in both side walls, a Brainrots folder,
-- and the nursery across the back: an inner wall with a door, the pen floor, six incubators, and two toggled
-- groups (NurseryLocked: bars, padlock, covered incubators, price label; NurseryOpen: domes, toys, trough).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Parts = require(ReplicatedStorage.Shared.World.Parts)
local Plots = require(ReplicatedStorage.Shared.Logic.Plots)

local Blocks = require(script.Parent.Blocks)
local Decor = require(script.Parent.Decor)
local Hub = require(script.Parent.Hub)

local Builder = {}

local L = Config.Layout
local FLOOR_TOP = L.FLOOR_TOP
local box, cyl, neon = Blocks.box, Blocks.cyl, Blocks.neon
local PLOT_COLORS = {
	"#2F8CFF",
	"#FF4F7B",
	"#2CC764",
	"#FFB21E",
	"#8B5CF6",
	"#FF7A2E",
	"#1FC1C1",
	"#E84DDB",
	"#FF3B3B",
	"#7CD63A",
	"#4D6BFF",
	"#FFD23F",
}
local INCUBATORS = 6 -- built per base; how many work depends on the owner's passes (Config.Nursery)

export type NurseryRefs = {
	door: BasePart, -- hosts the nursery prompt (unlock / open)
	locked: Model, -- shown while locked (bars, padlock, covered incubators, price label)
	open: Model, -- shown once unlocked (domes, toys, trough)
	priceLabel: TextLabel, -- second line of the "NURSERY LOCKED" label
	incubatorTops: { CFrame }, -- egg resting point on each incubator, index 1..6
	passLabels: { BillboardGui }, -- "Extra incubator (pass)" over incubators the owner can't use yet
	pen: CFrame, -- centre of the pen floor (babies and teens wander around it)
}

export type PlotRefs = {
	index: number,
	model: Model,
	origin: CFrame, -- plot centre at ground level, LookVector toward the hub
	pedestals: { BasePart },
	collector: BasePart,
	collectorLabel: TextLabel,
	brainrots: Folder,
	signLabel: TextLabel,
	nursery: NurseryRefs,
}

export type HubRefs = Hub.HubRefs

local hubRefs: HubRefs? = nil

function Builder.plotOrigin(index: number): CFrame
	local pose = Plots.pose(index)
	return CFrame.new(pose.x, 0, pose.z) * CFrame.Angles(0, pose.yaw, 0)
end

function Builder.at(origin: CFrame, x: number, y: number, z: number): CFrame
	return origin * CFrame.new(x, y, z)
end

-- Ground, spokes, decor -----------------------------------------------------------------------------------

local function spokeDeg(i: number): number
	return L.PLOT_FIRST_ANGLE_DEG + (i - 1) * 360 / Config.Game.PLOT_COUNT
end

-- True if a ground point is clear of the spoke paths (for scattering decor).
local function offSpokes(p: Vector3): boolean
	local deg = math.deg(math.atan2(p.Z, p.X))
	for i = 1, Config.Game.PLOT_COUNT do
		local d = math.abs(((deg - spokeDeg(i) + 180) % 360) - 180)
		if math.rad(d) * p.Magnitude < L.SPOKE_WIDTH / 2 + 7 then
			return false
		end
	end
	return true
end

local function buildGround(world: Folder)
	local mapSize = L.MAP_RADIUS * 2
	box(
		world,
		"Baseplate",
		Vector3.new(mapSize, 2, mapSize),
		CFrame.new(0, -1, 0),
		Blocks.FLOOR_BLUE,
		{ studs = true }
	)
	cyl(
		world,
		"Meadow",
		(L.RING_ROAD_RADIUS - 6) * 2,
		0.3,
		CFrame.new(0, 0.15, 0),
		Blocks.MEADOW,
		{ studs = true }
	)
	cyl(world, "RingRoad", (L.RING_ROAD_RADIUS + 6) * 2, 0.2, CFrame.new(0, 0.1, 0), Blocks.PATH_GREY, {
		studs = true,
	})
	local props = Parts.folder("Props", world)
	for i = 1, Config.Game.PLOT_COUNT do
		local deg = spokeDeg(i)
		local r0, r1 = L.HUB_RADIUS - 2, L.GATE_RADIUS
		box(
			world,
			`Spoke{i}`,
			Vector3.new(L.SPOKE_WIDTH, 0.5, r1 - r0),
			Blocks.facingHub((r0 + r1) / 2, deg, 0.25),
			Blocks.PATH_GREY,
			{ studs = true }
		)
		local k = 0
		for r = r0 + 14, r1 - 10, 26 do
			k += 1
			for _, side in { -1, 1 } do
				local pos = (Blocks.facingHub(r, deg, 0) * CFrame.new(side * (L.SPOKE_WIDTH / 2 + 1.5), 0, 0)).Position
				Decor.lamp(props, pos, k % 2 == 0)
			end
		end
		-- the meadow sector between this spoke and the previous one
		local mid = deg - 180 / Config.Game.PLOT_COUNT
		Decor.sector(props, i, mid, L.HUB_RADIUS, L.RING_ROAD_RADIUS, offSpokes)
		for _, side in { -1, 1 } do
			Decor.bench(
				props,
				Blocks.facingHub(L.HUB_RADIUS + 40, deg, 0)
					* CFrame.new(side * (L.SPOKE_WIDTH / 2 + 5), 0, 0)
					* CFrame.Angles(0, math.rad(-90 * side), 0)
			)
		end
	end
	Decor.treeLine(props, L.MAP_RADIUS)
end

-- Bases -----------------------------------------------------------------------------------------------------

-- Dark blocky wall segment with a neon strip along the top and black windows on the long side.
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
	box(
		parent,
		"Wall",
		Vector3.new(sx, h, sz),
		origin * CFrame.new(cx, FLOOR_TOP + h / 2, cz),
		Blocks.BUILDING,
		{
			studs = true,
		}
	)
	neon(
		parent,
		"Neon",
		Vector3.new(sx + 0.2, 0.5, sz + 0.2),
		origin * CFrame.new(cx, FLOOR_TOP + h - 0.6, cz),
		accent
	)
	box(
		parent,
		"Cap",
		Vector3.new(sx + 0.6, 0.8, sz + 0.6),
		origin * CFrame.new(cx, FLOOR_TOP + h + 0.4, cz),
		Blocks.BUILDING_DARK,
		{
			studs = true,
		}
	)
	local long = math.max(sx, sz)
	local alongX = sx >= sz
	local n = math.floor(long / 9)
	for i = 1, n do
		local t = -long / 2 + (i - 0.5) * (long / n)
		box(
			parent,
			"Window",
			if alongX then Vector3.new(5, h * 0.42, sz + 0.25) else Vector3.new(sx + 0.25, h * 0.42, 5),
			origin
				* CFrame.new(
					if alongX then cx + t else cx,
					FLOOR_TOP + h * 0.55,
					if alongX then cz else cz + t
				),
			Blocks.WINDOW,
			{ material = Enum.Material.Glass, canCollide = false }
		)
	end
end

local function buildNursery(origin: CFrame, model: Model): NurseryRefs
	local N = L.NURSERY
	local hw, hd = L.PLOT_WIDTH / 2, L.PLOT_DEPTH / 2
	local door = N.doorHalfWidth
	local folder = Parts.folder("Nursery", model)
	box(
		folder,
		"PenFloor",
		Vector3.new(L.PLOT_WIDTH - 2, 0.2, hd - N.zFront - 1),
		origin * CFrame.new(0, FLOOR_TOP + 0.1, (N.zFront + hd) / 2),
		"#FFD6E8",
		{ studs = true }
	)
	wall(origin, folder, "#FF8FC8", -hw, N.zFront, -door, N.zFront, L.WALL_HEIGHT - 2)
	wall(origin, folder, "#FF8FC8", door, N.zFront, hw, N.zFront, L.WALL_HEIGHT - 2)
	box(
		folder,
		"DoorTop",
		Vector3.new(door * 2, 2, 2),
		origin * CFrame.new(0, FLOOR_TOP + L.WALL_HEIGHT - 3, N.zFront),
		Blocks.BUILDING_DARK,
		{
			studs = true,
		}
	)
	local sign = box(
		folder,
		"NurserySign",
		Vector3.new(12, 2.6, 0.4),
		origin * CFrame.new(0, FLOOR_TOP + L.WALL_HEIGHT + 0.4, N.zFront - 1.2),
		"#FF8FC8",
		{
			studs = true,
		}
	)
	Blocks.surface(sign, Enum.NormalId.Front, { { text = "NURSERY", color = "#FFFFFF" } })
	-- the door itself: invisible, hosts the prompt
	local doorPart = box(
		folder,
		"Door",
		Vector3.new(door * 2, L.WALL_HEIGHT - 4, 1),
		origin * CFrame.new(0, FLOOR_TOP + (L.WALL_HEIGHT - 4) / 2, N.zFront - 0.8),
		"#FFFFFF",
		{
			transparency = 1,
			canCollide = false,
		}
	)

	local locked = Instance.new("Model")
	locked.Name = "NurseryLocked"
	local open = Instance.new("Model")
	open.Name = "NurseryOpen"
	-- locked: barred door (solid), padlock, price label, dimmed floor cover, covered incubators
	for k = -1, 1 do
		neon(
			locked,
			"Bar",
			Vector3.new(0.4, L.WALL_HEIGHT - 4, 0.4),
			origin * CFrame.new(k * 2.6, FLOOR_TOP + (L.WALL_HEIGHT - 4) / 2, N.zFront),
			"#FF3B3B"
		)
	end
	for _, y in { 2.5, 6 } do
		neon(
			locked,
			"Bar",
			Vector3.new(door * 2, 0.4, 0.4),
			origin * CFrame.new(0, FLOOR_TOP + y, N.zFront),
			"#FF3B3B"
		)
	end
	box(
		locked,
		"Blocker",
		Vector3.new(door * 2, L.WALL_HEIGHT - 4, 0.6),
		origin * CFrame.new(0, FLOOR_TOP + (L.WALL_HEIGHT - 4) / 2, N.zFront),
		"#FFFFFF",
		{
			transparency = 1,
		}
	)
	local padlock = box(
		locked,
		"Padlock",
		Vector3.new(2.4, 2.2, 0.8),
		origin * CFrame.new(0, FLOOR_TOP + 4.2, N.zFront - 0.6),
		"#FFD23F",
		{
			material = Enum.Material.Metal,
		}
	)
	box(
		locked,
		"Shackle",
		Vector3.new(1.6, 1.2, 0.4),
		origin * CFrame.new(0, FLOOR_TOP + 5.8, N.zFront - 0.6),
		"#B4B4B8",
		{
			material = Enum.Material.Metal,
		}
	)
	box(
		locked,
		"DimFloor",
		Vector3.new(L.PLOT_WIDTH - 2.2, 0.05, hd - N.zFront - 1.2),
		origin * CFrame.new(0, FLOOR_TOP + 0.23, (N.zFront + hd) / 2),
		"#6E6E73",
		{
			canCollide = false,
		}
	)
	local _, lockLabels = Blocks.floating(padlock, {
		{ text = "NURSERY LOCKED", color = "#FF5C5C", weight = 1 },
		{ text = "", color = "#7CFF9B", weight = 0.8 },
	}, 11, 1.3, 4.5, 120)

	local incubatorTops: { CFrame } = {}
	local passLabels: { BillboardGui } = {}
	for k = 1, INCUBATORS do
		local x = -(INCUBATORS - 1) * N.incubatorSpacing / 2 + (k - 1) * N.incubatorSpacing
		local c = origin * CFrame.new(x, FLOOR_TOP, N.incubatorZ)
		cyl(folder, `IncubatorBase{k}`, 5.4, 1.4, c * CFrame.new(0, 0.7, 0), "#FFFFFF")
		neon(folder, `IncubatorRing{k}`, Vector3.new(5.6, 0.3, 5.6), c * CFrame.new(0, 1.45, 0), "#7CE0FF")
		Blocks.ball(open, `IncubatorDome{k}`, 5, c * CFrame.new(0, 2.6, 0), "#BFEFFF", {
			material = Enum.Material.Glass,
			transparency = 0.55,
			canCollide = false,
		})
		box(locked, `Covered{k}`, Vector3.new(5, 4.2, 5), c * CFrame.new(0, 2.1, 0), "#8A8D93", {
			material = Enum.Material.Fabric,
		})
		local anchor =
			box(open, `IncubatorLabel{k}`, Vector3.new(0.2, 0.2, 0.2), c * CFrame.new(0, 5.4, 0), "#FFFFFF", {
				transparency = 1,
				canCollide = false,
			})
		local gui =
			Blocks.floating(anchor, { { text = "Extra incubator (pass)", color = "#FFD23F" } }, 5, 0.9, 0, 60)
		gui.Enabled = false
		table.insert(passLabels, gui)
		table.insert(incubatorTops, c * CFrame.new(0, 1.6, 0))
	end
	-- open: trough and toy blocks
	box(
		open,
		"Trough",
		Vector3.new(10, 1.4, 3),
		origin * CFrame.new(-20, FLOOR_TOP + 0.7, N.zFront + 6),
		"#A9743F",
		{
			material = Enum.Material.WoodPlanks,
		}
	)
	box(
		open,
		"TroughFood",
		Vector3.new(9, 0.4, 2.2),
		origin * CFrame.new(-20, FLOOR_TOP + 1.5, N.zFront + 6),
		"#F2D06B"
	)
	for k, color in { "#FF4F7B", "#2F8CFF", "#FFD23F" } do
		box(
			open,
			"ToyBlock",
			Vector3.new(2, 2, 2),
			origin
				* CFrame.new(20 + (k - 2) * 2.4, FLOOR_TOP + 1, N.zFront + 5)
				* CFrame.Angles(0, k * 0.4, 0),
			color,
			{
				studs = true,
			}
		)
	end
	locked.Parent = folder
	return {
		door = doorPart,
		locked = locked,
		open = open,
		priceLabel = lockLabels[2],
		incubatorTops = incubatorTops,
		passLabels = passLabels,
		pen = origin * CFrame.new(0, FLOOR_TOP, N.penZ),
	}
end

local function buildPlot(index: number, world: Folder): PlotRefs
	local origin = Builder.plotOrigin(index)
	local accent = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]
	local model = Instance.new("Model")
	model.Name = `Plot{index}`
	model:SetAttribute("Index", index)
	local hw, hd = L.PLOT_WIDTH / 2, L.PLOT_DEPTH / 2

	box(
		model,
		"Floor",
		Vector3.new(L.PLOT_WIDTH, 1, L.PLOT_DEPTH),
		origin * CFrame.new(0, FLOOR_TOP - 0.5, 0),
		"#5A5E66",
		{
			studs = true,
		}
	)
	local walls = Parts.folder("Walls", model)
	local g = L.GATE.width / 2
	wall(origin, walls, accent, -hw, -hd, -g - 1.5, -hd)
	wall(origin, walls, accent, g + 1.5, -hd, hw, -hd)
	wall(origin, walls, accent, -hw, hd, hw, hd, L.WALL_HEIGHT + 6)
	local exit = L.LANE_EXIT
	for _, side in { -1, 1 } do
		wall(origin, walls, accent, side * hw, -hd, side * hw, exit.zMin)
		wall(origin, walls, accent, side * hw, exit.zMax, side * hw, hd)
		for _, z in { exit.zMin, exit.zMax } do
			neon(
				walls,
				"ExitFrame",
				Vector3.new(0.6, 9, 0.6),
				origin * CFrame.new(side * hw, FLOOR_TOP + 4.5, z),
				"#FF7A2E"
			)
		end
		box(
			walls,
			"GatePillar",
			Vector3.new(3, L.WALL_HEIGHT + 3, 3),
			origin * CFrame.new(side * (g + 1.5), FLOOR_TOP + (L.WALL_HEIGHT + 3) / 2, -hd),
			Blocks.BUILDING_DARK,
			{
				studs = true,
			}
		)
		neon(
			walls,
			"GateNeon",
			Vector3.new(0.4, L.WALL_HEIGHT + 2, 3.2),
			origin * CFrame.new(side * (g + 1.5) - side * 1.6, FLOOR_TOP + (L.WALL_HEIGHT + 2) / 2, -hd),
			accent
		)
	end
	local beam = box(
		walls,
		"GateBeam",
		Vector3.new(L.GATE.width + 6, 3, 3),
		origin * CFrame.new(0, FLOOR_TOP + L.WALL_HEIGHT + 1.5, -hd),
		Blocks.BUILDING_DARK,
		{
			studs = true,
		}
	)
	local signLabel =
		Blocks.surface(beam, Enum.NormalId.Front, { { text = "FREE BASE", color = "#FFFFFF" } })[1]

	-- pedestals: round, with a neon rim in the occupant's rarity colour
	local pedFolder = Parts.folder("Pedestals", model)
	local pedestals: { BasePart } = {}
	for slot, def in L.SLOTS do
		local locked = def.tier > 0
		local p = cyl(
			pedFolder,
			`Slot{slot}`,
			L.PEDESTAL_SIZE,
			L.PEDESTAL_HEIGHT,
			origin * CFrame.new(def.x, FLOOR_TOP + L.PEDESTAL_HEIGHT / 2, def.z),
			if locked then "#6E717A" else "#D8D8DC",
			{
				transparency = if locked then 0.5 else 0,
			}
		)
		p:SetAttribute("Slot", slot)
		p:SetAttribute("Tier", def.tier)
		local rim = cyl(
			p,
			"Rim",
			L.PEDESTAL_SIZE + 0.4,
			0.3,
			origin * CFrame.new(def.x, FLOOR_TOP + 0.2, def.z),
			if locked then "#4A4D55" else accent,
			{
				material = Enum.Material.Neon,
				canCollide = false,
				transparency = if locked then 0.6 else 0.2,
			}
		)
		rim:SetAttribute("Slot", slot)
		if locked then
			Parts.billboard(p, 2.5, { `🔒 Extra Slots {string.rep("I", def.tier)}` }, Vector2.new(6, 1))
		end
		pedestals[slot] = p
	end

	local cc = L.COLLECTOR
	local collector = neon(
		model,
		"Collector",
		Vector3.new(cc.width, 0.5, cc.depth),
		origin * CFrame.new(cc.x, FLOOR_TOP + 0.25, cc.z),
		"#FFD23F"
	)
	collector.CanCollide = true
	local _, collectorLabels = Parts.billboard(collector, 4, { "$0" }, Vector2.new(7, 1.8))
	collectorLabels[1].TextColor3 = Color3.fromHex("#7CFF9B")
	Parts.billboard(collector, 2.2, { "COLLECT" }, Vector2.new(5, 1))

	local nursery = buildNursery(origin, model)
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
		brainrots = brainrots,
		signLabel = signLabel,
		nursery = nursery,
	}
end

-- Escape lanes: obby tiles + a jump pad in an arc between each pair of neighbouring bases' side exits.
local LANE_COLORS = { "#FF4F7B", "#FFD23F", "#2CC764", "#8B5CF6", "#FF7A2E", "#1FC1C1" }
local function buildLanes(world: Folder)
	local lanes = Parts.folder("EscapeLanes", world)
	local laneRadius = L.PLOT_RING_RADIUS - L.LANE_INSET
	local exitDeg = math.deg((L.PLOT_WIDTH / 2 + 2) / laneRadius)
	for i = 1, Config.Game.PLOT_COUNT do
		local a0, a1 = spokeDeg(i) + exitDeg, spokeDeg(i) + 360 / Config.Game.PLOT_COUNT - exitDeg
		local n = 9
		for k = 0, n - 1 do
			local a = a0 + (k + 0.5) * (a1 - a0) / n
			local cf = Blocks.facingHub(
				laneRadius + (if k % 2 == 0 then 1.5 else -1.5),
				a,
				FLOOR_TOP + 0.5 + (k % 3) * 1.2
			)
			box(
				lanes,
				`LaneBlock{i}_{k}`,
				Vector3.new(7, 1, 5),
				cf,
				LANE_COLORS[(k + i) % #LANE_COLORS + 1],
				{
					studs = true,
				}
			)
		end
		local mid = Blocks.facingHub(laneRadius, (a0 + a1) / 2, FLOOR_TOP + 2.6)
		neon(lanes, `JumpPad{i}`, Vector3.new(4, 0.3, 4), mid * CFrame.new(0, 0.7, 0), "#7CFF9B")
	end
end

-- Builds everything once. Returns refs by plot index.
function Builder.build(): { [number]: PlotRefs }
	local existing = workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	local world = Parts.folder("World", workspace)
	buildGround(world)
	hubRefs = Hub.build(world)
	buildLanes(world)
	local plots: { [number]: PlotRefs } = {}
	for i = 1, Config.Game.PLOT_COUNT do
		plots[i] = buildPlot(i, world)
	end
	return plots
end

function Builder.hub(): HubRefs
	return hubRefs :: HubRefs
end

-- Top centre of a pedestal; brainrots face the plot front (gate).
function Builder.pedestalTop(refs: PlotRefs, slot: number): CFrame
	local def = L.SLOTS[slot]
	return Builder.at(refs.origin, def.x, FLOOR_TOP + L.PEDESTAL_HEIGHT, def.z)
end

function Builder.spawnCFrame(refs: PlotRefs): CFrame
	return Builder.at(refs.origin, L.SPAWN.x, FLOOR_TOP + 3, L.SPAWN.z)
end

-- Just outside the gate, facing the hub (runaways leave this way).
function Builder.gateCFrame(refs: PlotRefs): CFrame
	return Builder.at(refs.origin, 0, FLOOR_TOP, L.GATE.z - 4)
end

-- Pedestal rim (lights up in the occupant's rarity colour).
function Builder.rim(refs: PlotRefs, slot: number): BasePart?
	return refs.pedestals[slot] and refs.pedestals[slot]:FindFirstChild("Rim") :: BasePart?
end

-- Shows the nursery as locked (bars, covered incubators, price) or open, and which incubators need a pass.
function Builder.setNursery(refs: PlotRefs, unlocked: boolean, usableIncubators: number, priceText: string)
	local n = refs.nursery
	local folder = refs.model:FindFirstChild("Nursery")
	n.locked.Parent = if unlocked then nil else folder
	n.open.Parent = if unlocked then folder else nil
	n.priceLabel.Text = priceText
	for k, gui in n.passLabels do
		gui.Enabled = unlocked and k > usableIncubators
	end
end

-- A spot in the pen for the k-th nursery brainrot (spread out on the pink floor).
function Builder.penSpot(refs: PlotRefs, k: number): CFrame
	local cols = 5
	local col = (k - 1) % cols
	local row = (k - 1) // cols
	return refs.nursery.pen * CFrame.new(-20 + col * 10, 0, -4 + row * 6)
end

return Builder
