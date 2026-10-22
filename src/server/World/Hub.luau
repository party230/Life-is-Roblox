--!strict
-- The central hub (D38): plaza disc, the shared red-carpet conveyor (central portal on an island, a ramp onto a
-- counter-clockwise loop, an exit vortex), the Egg Shop and Food Shop stalls with merchants, leaderboards,
-- the event stage, the trade zone and the hangout. Returns the refs services need.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Parts = require(ReplicatedStorage.Shared.World.Parts)

local Blocks = require(script.Parent.Blocks)
local Decor = require(script.Parent.Decor)

local Hub = {}

export type HubRefs = {
	model: Folder,
	carpetPath: { Vector3 }, -- walking order: portal -> ramp -> loop -> exit vortex (carpet top surface)
	carpetItems: Folder, -- brainrots walking the carpet live here
	announceGui: BillboardGui, -- server-wide Rare+ banner over the portal (disabled when idle)
	announceLabels: { TextLabel },
	eggCounter: BasePart,
	foodCounter: BasePart,
}

local L = Config.Layout
local box, cyl, neon, polar, facingHub = Blocks.box, Blocks.cyl, Blocks.neon, Blocks.polar, Blocks.facingHub

local function carpet(folder: Folder): { Vector3 }
	local c = L.CARPET
	local top = L.HUB_TOP + 1 -- carpet surface (parts are 0.4 thick, centred 0.2 below)
	local y = top - 0.2
	local path: { Vector3 } = {}
	-- ramp: from the portal out along +X to the loop
	local rampLen = c.radius - c.rampStart
	box(
		folder,
		"CarpetRamp",
		Vector3.new(rampLen, 0.4, c.width),
		CFrame.new(c.rampStart + rampLen / 2, y, 0),
		Blocks.CARPET_RED,
		{ studs = true }
	)
	table.insert(path, Vector3.new(c.rampStart + 1, top, 0))
	table.insert(path, Vector3.new(c.radius, top, 0))
	-- loop, counter-clockwise from startDeg
	for k = 0, c.segments - 1 do
		local a0 = c.startDeg + k * c.sweepDeg / c.segments
		local a1 = c.startDeg + (k + 1) * c.sweepDeg / c.segments
		local p0, p1 = polar(c.radius, a0, y), polar(c.radius, a1, y)
		local dir = (p1 - p0).Unit
		local right = dir:Cross(Vector3.yAxis).Unit
		box(
			folder,
			"Carpet",
			Vector3.new(c.width, 0.4, (p1 - p0).Magnitude + 0.9),
			CFrame.fromMatrix((p0 + p1) / 2, right, Vector3.yAxis),
			Blocks.CARPET_RED,
			{ studs = true }
		)
		table.insert(path, polar(c.radius, a1, top))
	end
	box(folder, "CarpetJoin", Vector3.new(c.width, 0.4, 10), CFrame.new(c.radius, y, 2), Blocks.CARPET_RED, {
		studs = true,
	})
	-- exit vortex where unsold brainrots despawn
	local exitP = polar(c.radius, c.startDeg + c.sweepDeg + 4, L.HUB_TOP)
	cyl(folder, "ExitVortex", 9, 0.4, CFrame.new(exitP + Vector3.new(0, 0.45, 0)), "#2B1240", {
		material = Enum.Material.Neon,
		canCollide = false,
	})
	cyl(folder, "ExitVortexCore", 5, 0.5, CFrame.new(exitP + Vector3.new(0, 0.5, 0)), "#8A3CFF", {
		material = Enum.Material.Neon,
		canCollide = false,
	})
	table.insert(path, Vector3.new(exitP.X, top, exitP.Z))
	return path
end

local function portal(folder: Folder): (BasePart, BillboardGui, { TextLabel })
	local cf = CFrame.new(4, L.HUB_TOP, 0) * CFrame.Angles(0, math.rad(-90), 0) -- faces +X, down the ramp
	box(
		folder,
		"PortalBase",
		Vector3.new(18, 2, 8),
		cf * CFrame.new(0, 1, 0),
		Blocks.BUILDING_DARK,
		{ studs = true }
	)
	for _, side in { -1, 1 } do
		box(
			folder,
			"PortalPillar",
			Vector3.new(3, 16, 3),
			cf * CFrame.new(side * 7.5, 10, 0),
			Blocks.BUILDING_DARK,
			{
				studs = true,
			}
		)
		neon(folder, "PortalNeon", Vector3.new(0.5, 15, 3.2), cf * CFrame.new(side * 5.9, 10, 0), "#B15CFF")
	end
	box(folder, "PortalTop", Vector3.new(18, 3, 3), cf * CFrame.new(0, 19.5, 0), Blocks.BUILDING_DARK, {
		studs = true,
	})
	local disc = cyl(
		folder,
		"PortalDisc",
		12.5,
		0.5,
		cf * CFrame.new(0, 9.5, 0) * CFrame.Angles(math.rad(90), 0, 0),
		"#8A3CFF",
		{
			material = Enum.Material.Neon,
			canCollide = false,
		}
	)
	local swirl = Instance.new("ParticleEmitter")
	swirl.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255))
	swirl.LightEmission = 1
	swirl.Rate = 30
	swirl.Lifetime = NumberRange.new(0.6, 1.2)
	swirl.Speed = NumberRange.new(1, 3)
	swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	swirl.Parent = disc
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 110, 255)
	light.Range = 30
	light.Brightness = 3
	light.Parent = disc
	local screen =
		box(folder, "PortalScreen", Vector3.new(22, 6, 0.6), cf * CFrame.new(0, 24, 0), Blocks.WINDOW)
	Blocks.surface(
		screen,
		Enum.NormalId.Back,
		{ { text = "NEW BRAINROTS EVERY FEW SECONDS!", color = "#FFFFFF" } },
		30
	)
	Blocks.floating(disc, { { text = "CONVEYOR", color = "#FF5C5C" } }, 22, 4.2, 24, 600)
	local gui, labels = Blocks.floating(disc, {
		{ text = "LEGENDARY SPAWNED!", color = "#FFD23F", weight = 1 },
		{ text = "", color = "#FFFFFF", weight = 0.7 },
	}, 28, 3, 36, 600)
	gui.Name = "Announcement"
	gui.Enabled = false
	return disc, gui, labels
end

-- Stall with a striped awning, goods on the counter and a merchant. Returns the counter (prompt host).
local function stall(
	folder: Folder,
	cf: CFrame,
	name: string,
	label: string,
	labelColor: string,
	awning: string,
	hat: string,
	goods: (place: (string, Vector3, CFrame, string, Enum.PartType?) -> ()) -> ()
): BasePart
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = folder
	local function p(
		n: string,
		size: Vector3,
		offset: CFrame,
		color: string,
		mat: Enum.Material?,
		studs: boolean?
	): Part
		return box(m, n, size, cf * offset, color, { material = mat, studs = studs })
	end
	p("Platform", Vector3.new(22, 1.6, 14), CFrame.new(0, 0.8, 1.5), "#9E9EA3", nil, true)
	p("Step", Vector3.new(22, 0.8, 2), CFrame.new(0, 0.4, -6.5), "#B4B4B8", nil, true)
	local y0 = 1.6
	local counter = p(
		"Counter",
		Vector3.new(16, 3, 2.4),
		CFrame.new(0, y0 + 1.5, -1),
		"#8A5A2E",
		Enum.Material.WoodPlanks
	)
	p(
		"CounterTop",
		Vector3.new(16.6, 0.5, 3),
		CFrame.new(0, y0 + 3.25, -1),
		"#A9743F",
		Enum.Material.WoodPlanks
	)
	for _, x in { -7.8, 7.8 } do
		for _, z in { -2, 5 } do
			p("Post", Vector3.new(0.8, 9.5, 0.8), CFrame.new(x, y0 + 4.75, z), "#6B4423", Enum.Material.Wood)
		end
	end
	p("Roof", Vector3.new(17, 0.6, 8.4), CFrame.new(0, y0 + 9.7, 1.5), "#6B4423", Enum.Material.WoodPlanks)
	for i = 0, 8 do
		p(
			`Awning{i}`,
			Vector3.new(17.4 / 9, 0.5, 4.6),
			CFrame.new(-8.7 + 17.4 / 18 + i * 17.4 / 9, y0 + 8.9, -3.4) * CFrame.Angles(math.rad(-22), 0, 0),
			if i % 2 == 0 then awning else "#FFFFFF"
		)
	end
	goods(function(n, size, offset, color, shape)
		box(m, n, size, cf * CFrame.new(0, y0 + 3.5, -1.2) * offset, color, { shape = shape })
	end)
	-- merchant
	local npc = Instance.new("Model")
	npc.Name = "Merchant"
	local torso = box(npc, "Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, y0 + 4.4, 2), "#C98A55")
	local head = box(npc, "Head", Vector3.new(2, 1.2, 1.2), cf * CFrame.new(0, y0 + 6, 2), "#D9A066")
	box(npc, "Hat", Vector3.new(2.3, 0.9, 1.5), cf * CFrame.new(0, y0 + 7, 2), hat)
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = npc
	npc.PrimaryPart = torso
	npc.Parent = m
	Blocks.floating(counter, { { text = label, color = labelColor } }, 14, 3.6, 11.5, 500)
	return counter
end

local function leaderboards(folder: Folder)
	local cf = facingHub(L.LEADERBOARDS.radius, L.LEADERBOARDS.deg, L.HUB_TOP)
	local titles = { "TOP CASH", "MOST STEALS", "BEST BREEDER" }
	for k = -1, 1 do
		local b = cf * CFrame.new(k * 11, 0, 0)
		box(folder, "BoardPost", Vector3.new(1, 12, 1), b * CFrame.new(-4, 6, 0.5), Blocks.BUILDING_DARK)
		box(folder, "BoardPost", Vector3.new(1, 12, 1), b * CFrame.new(4, 6, 0.5), Blocks.BUILDING_DARK)
		local board =
			box(folder, "Leaderboard", Vector3.new(9.5, 11, 0.6), b * CFrame.new(0, 9, 0), "#1B1D24")
		board:SetAttribute("Board", titles[k + 2])
		neon(folder, "BoardTrim", Vector3.new(9.9, 0.4, 0.8), b * CFrame.new(0, 14.6, 0), "#FFD23F")
		local lines: { Blocks.Line } = { { text = titles[k + 2], color = "#FFD23F", weight = 1.4 } }
		for i = 1, 5 do
			table.insert(lines, { text = `{i}. ---`, color = "#FFFFFF" })
		end
		Blocks.surface(board, Enum.NormalId.Front, lines)
	end
	local anchor = box(folder, "BoardsAnchor", Vector3.new(1, 1, 1), cf * CFrame.new(0, 19, 0), "#FFFFFF", {
		transparency = 1,
		canCollide = false,
	})
	Blocks.floating(anchor, { { text = "Leaderboards", color = "#FFD23F" } }, 14, 3, 0, 500)
end

local function eventStage(folder: Folder)
	local cf = facingHub(L.EVENT_STAGE.radius, L.EVENT_STAGE.deg, L.HUB_TOP)
	box(folder, "Stage", Vector3.new(30, 3, 16), cf * CFrame.new(0, 1.5, 2), "#3B3F47", { studs = true })
	box(
		folder,
		"StageFloor",
		Vector3.new(28, 0.4, 14),
		cf * CFrame.new(0, 3.2, 2),
		"#5A2E8A",
		{ studs = true }
	)
	for _, x in { -14, 14 } do
		box(folder, "Truss", Vector3.new(1.4, 16, 1.4), cf * CFrame.new(x, 11, 8), "#B4B4B8")
		box(folder, "Speaker", Vector3.new(3, 5, 3), cf * CFrame.new(x * 0.82, 5.6, 0), "#1B1D24")
	end
	box(folder, "TrussTop", Vector3.new(30, 1.4, 1.4), cf * CFrame.new(0, 19, 8), "#B4B4B8")
	local colors = { "#FF4F7B", "#FFD23F", "#2F8CFF", "#2CC764" }
	for k = -3, 3 do
		neon(
			folder,
			"StageLight",
			Vector3.new(1.4, 1.2, 1.4),
			cf * CFrame.new(k * 4, 17.8, 8),
			colors[(k + 3) % 4 + 1]
		)
	end
	local banner = box(folder, "Banner", Vector3.new(24, 5, 0.4), cf * CFrame.new(0, 14, 8.6), "#E0262C")
	Blocks.surface(banner, Enum.NormalId.Front, { { text = "EVENT STAGE", color = "#FFFFFF" } })
	Blocks.floating(banner, { { text = "Event Stage", color = "#FF7AC8" } }, 14, 3, 10, 500)
end

local function tradeZone(folder: Folder)
	local cf = facingHub(L.TRADE_ZONE.radius, L.TRADE_ZONE.deg, L.HUB_TOP)
	cyl(folder, "TradeRing", 30, 0.3, cf * CFrame.new(0, 0.15, 0), "#FFD23F", { studs = true })
	local floor = cyl(folder, "TradeFloor", 26, 0.35, cf * CFrame.new(0, 0.2, 0), "#2F8CFF", { studs = true })
	for k = -1, 1, 2 do
		local t = cf * CFrame.new(k * 6, 0, 0)
		box(folder, "TradeTable", Vector3.new(5, 0.6, 3), t * CFrame.new(0, 3, 0), "#FFFFFF")
		box(folder, "TradeLeg", Vector3.new(0.8, 2.8, 0.8), t * CFrame.new(0, 1.4, 0), "#B4B4B8")
	end
	Blocks.floating(floor, { { text = "Trade Zone", color = "#7CE0FF" } }, 12, 3, 10, 500)
end

local function hangout(folder: Folder)
	local cf = facingHub(L.HANGOUT.radius, L.HANGOUT.deg, L.HUB_TOP)
	Decor.cupFountain(folder, cf)
	for k = 0, 5 do
		Decor.bench(folder, cf * CFrame.Angles(0, math.rad(k * 60), 0) * CFrame.new(0, 0, -15))
	end
end

function Hub.build(world: Folder): HubRefs
	local folder = Parts.folder("Hub", world)
	cyl(folder, "HubEdge", L.HUB_RADIUS * 2 + 6, 0.5, CFrame.new(0, 0.25, 0), "#8E8E93", { studs = true })
	cyl(
		folder,
		"Hub",
		L.HUB_RADIUS * 2,
		0.6,
		CFrame.new(0, L.HUB_TOP / 2, 0),
		Blocks.PLAZA_GREY,
		{ studs = true }
	)
	cyl(
		folder,
		"Island",
		L.ISLAND_RADIUS * 2,
		0.6,
		CFrame.new(0, L.HUB_TOP + 0.3, 0),
		Blocks.MEADOW,
		{ studs = true }
	)
	for k = 1, 10 do
		Decor.bush(folder, polar(L.ISLAND_RADIUS - 4, k * 30 + 15, L.HUB_TOP + 0.6))
	end
	local carpetFolder = Parts.folder("Carpet", folder)
	local path = carpet(carpetFolder)
	local _, announceGui, announceLabels = portal(folder)

	local egg = L.EGG_SHOP
	local eggCounter = stall(
		folder,
		facingHub(egg.radius, egg.deg, L.HUB_TOP),
		"EggShop",
		"Egg Shop",
		"#3DE05C",
		"#2C7BE5",
		"#2C7BE5",
		function(place)
			for i, c in { "#FFF4E0", "#B98CFF", "#FFD23F", "#7CE0FF" } do
				place(
					"Egg",
					Vector3.new(1.4, 1.8, 1.4),
					CFrame.new(-4.5 + (i - 1) * 3, 0.9, 0),
					c,
					Enum.PartType.Ball
				)
			end
		end
	)
	Blocks.prompt(eggCounter, "Shop eggs", "Egg Merchant", "Eggs")
	local food = L.FOOD_SHOP
	local foodCounter = stall(
		folder,
		facingHub(food.radius, food.deg, L.HUB_TOP),
		"FoodShop",
		"Food Shop",
		"#FF9A1F",
		"#E0262C",
		"#FFFFFF",
		function(place)
			local up = Blocks.UP
			place(
				"Pizza",
				Vector3.new(0.3, 3, 3),
				CFrame.new(-5, 0.2, 0) * up,
				"#FFC94A",
				Enum.PartType.Cylinder
			)
			place(
				"PizzaSauce",
				Vector3.new(0.32, 2.4, 2.4),
				CFrame.new(-5, 0.22, 0) * up,
				"#D9442B",
				Enum.PartType.Cylinder
			)
			place(
				"Bowl",
				Vector3.new(1.2, 2.4, 2.4),
				CFrame.new(-1.6, 0.6, 0) * up,
				"#FFFFFF",
				Enum.PartType.Cylinder
			)
			place(
				"Spaghetti",
				Vector3.new(0.5, 2, 2),
				CFrame.new(-1.6, 1.3, 0) * up,
				"#F2D06B",
				Enum.PartType.Cylinder
			)
			for k, c in { "#FFB3C7", "#B6F0B0", "#FFF1B5" } do
				place(
					"Gelato",
					Vector3.new(1.3, 1.3, 1.3),
					CFrame.new(1.6, 0.6 + (k - 1) * 1.1, 0),
					c,
					Enum.PartType.Ball
				)
			end
			place(
				"Platter",
				Vector3.new(0.3, 3.4, 3.4),
				CFrame.new(5, 0.2, 0) * up,
				"#FFD23F",
				Enum.PartType.Cylinder
			)
			place("Roast", Vector3.new(2, 1.2, 1.4), CFrame.new(5, 0.9, 0), "#B5651D")
		end
	)
	Blocks.prompt(foodCounter, "Buy food", "Food Merchant", "Food")
	leaderboards(folder)
	eventStage(folder)
	tradeZone(folder)
	hangout(folder)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(-55, L.HUB_TOP + 0.1, 0)
	spawn.Color = Color3.fromHex("#FFFFFF")
	spawn.Transparency = 0.5
	spawn.Duration = 0
	spawn.Parent = folder

	return {
		model = folder,
		carpetPath = path,
		carpetItems = Parts.folder("CarpetItems", folder),
		announceGui = announceGui,
		announceLabels = announceLabels,
		eggCounter = eggCounter,
		foodCounter = foodCounter,
	}
end

return Hub
