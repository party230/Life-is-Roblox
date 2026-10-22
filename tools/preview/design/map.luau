--!nocheck
-- DESIGN PROPOSAL (not game code): the 12-base ring around a central hub with the shared red-carpet conveyor,
-- Egg + Food shops, nursery bases (one unlocked, one locked) and owner-only loyalty/runaway overlays.
-- Built headless with the real Parts helpers and character models, dumped for world.mjs to render.
-- Once approved, this becomes src/server/World/Builder.luau with these numbers moved into Config/Layout.
-- Usage (repo root): lune run tools/preview/design/map.luau > build/design.json

local Runtime = require("../runtime")
local roblox = require("@lune/roblox")
local Instance, Vector3, Color3, Enum, Vector2, UDim2 =
	roblox.Instance, roblox.Vector3, roblox.Color3, roblox.Enum, roblox.Vector2, roblox.UDim2
local CFrame, Random = Runtime.CFrame, Runtime.Random
local load, place = Runtime.load, Runtime.place
local workspace = Runtime.workspace

local Config = load("src/shared/Config/init.luau")
local Parts = load("src/shared/World/Parts.luau")
local Brainrot = load("src/shared/World/Brainrot.luau")
local ShopStock = load("src/shared/Logic/ShopStock.luau")

-- Proposed layout numbers (would move to Config/Layout) --------------------------------------------------

local BASES = 12
local WALK_SPEED = 16 -- Roblox default
local HUB_RADIUS = 84 -- plaza disc
local CARPET_RADIUS = 34 -- carpet loop centreline
local CARPET_WIDTH = 10
local CARPET_SWEEP_DEG = 330 -- loop length; the gap holds the portal ramp and the exit vortex
local ISLAND_RADIUS = 27
local GATE_RADIUS = 230 -- gate distance from the hub centre
local BASE_W, BASE_D = 64, 84 -- base footprint (gate at local -Z, facing the hub)
local BASE_RADIUS = GATE_RADIUS + BASE_D / 2
local FLOOR_TOP = 1
local WALL_H = 12
local NURSERY_Z = 16 -- nursery wall (local z); the nursery fills the back of the base
local SPOKE_WIDTH = 12
local RING_ROAD_RADIUS = GATE_RADIUS - 16
local LANE_RADIUS = BASE_RADIUS - 6 -- escape lanes link neighbouring bases' side exits
local MAP_RADIUS = BASE_RADIUS + BASE_D / 2 + 60
local NAMEPLATE_W, NAMEPLATE_LINE, NAMEPLATE_MAX_DISTANCE = 5.6, 0.72, 60

-- the walk the brief asks for: gate -> nearest carpet edge
local walkStuds = GATE_RADIUS - (CARPET_RADIUS + CARPET_WIDTH / 2)

-- Palette (same classic style as the slice)
local FLOOR_BLUE = "#2C7BE5"
local PATH_GREY = "#A3A2A5"
local PLAZA_GREY = "#C7C7CB"
local CARPET_RED = "#E0262C"
local BUILDING = "#3B3F47"
local BUILDING_DARK = "#2B2E35"
local WINDOW = "#111318"
local ACCENTS = {
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
local UP = CFrame.Angles(0, 0, math.rad(90))

local world = Parts.folder("World", workspace)
local rng = Random.new(11)
local function rand(a, b)
	return rng:NextNumber(a, b)
end
local function roll()
	return rng:NextNumber()
end

-- Part helpers -------------------------------------------------------------------------------------------

local function box(parent, name, size, cf, color, opts)
	opts = opts or {}
	return Parts.part({
		name = name,
		size = size,
		cframe = cf,
		color = color,
		material = opts.material,
		shape = opts.shape,
		transparency = opts.transparency,
		studs = opts.studs,
		canCollide = opts.canCollide,
		parent = parent,
	})
end

local function cyl(parent, name, diameter, height, cf, color, opts)
	opts = opts or {}
	opts.shape = Enum.PartType.Cylinder
	return box(parent, name, Vector3.new(height, diameter, diameter), cf * UP, color, opts)
end

local function ball(parent, name, d, cf, color, opts)
	opts = opts or {}
	opts.shape = Enum.PartType.Ball
	return box(parent, name, Vector3.new(d, d, d), cf, color, opts)
end

local function neon(parent, name, size, cf, color)
	return box(parent, name, size, cf, color, { material = Enum.Material.Neon, canCollide = false })
end

local function polar(r, deg, y)
	local a = math.rad(deg)
	return Vector3.new(math.cos(a) * r, y or 0, math.sin(a) * r)
end

-- CFrame at polar position facing the hub centre (LookVector toward the centre).
local function facingHub(r, deg, y)
	local p = polar(r, deg, y)
	return CFrame.lookAt(p, Vector3.new(0, p.Y, 0))
end

-- Text -----------------------------------------------------------------------------------------------------

local function textLine(parent, order, text, color, weight, total, strokeThickness)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, weight / total)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = if typeof(color) == "Color3" then color else Color3.fromHex(color)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeThickness or 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = l
	l.Parent = parent
	return l
end

-- Floating world label at `pos`; lines = { { text, color, weight? } }, size in studs.
local function floating(pos, lines, width, lineHeight, maxDistance)
	local anchor = box(world, "LabelAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), "#FFFFFF", {
		transparency = 1,
		canCollide = false,
	})
	local total = 0
	for _, l in lines do
		total += l[3] or 1
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(width, total * lineHeight)
	gui.MaxDistance = maxDistance or 400
	gui.Adornee = anchor
	for i, l in lines do
		textLine(gui, i, l[1], l[2], l[3] or 1, total, 5)
	end
	gui.Parent = anchor
	return gui
end

local function surfaceText(part, face, lines)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	local total = 0
	for _, l in lines do
		total += l[3] or 1
	end
	for i, l in lines do
		textLine(gui, i, l[1], l[2], l[3] or 1, total, 3)
	end
	gui.Parent = part
end

-- Props ------------------------------------------------------------------------------------------------------

local props = Parts.folder("Props", world)

local function tree(pos, scale)
	local s = scale or 1
	local h = rand(6, 10) * s
	box(
		props,
		"Trunk",
		Vector3.new(2.6, h, 2.6) * Vector3.new(s, 1, s),
		CFrame.new(pos + Vector3.new(0, h / 2, 0)),
		"#7A4A24",
		{ studs = true }
	)
	for _, o in
		{
			Vector3.new(0, h + 3, 0),
			Vector3.new(2.4, h + 1.5, 0.8),
			Vector3.new(-2.2, h + 1.8, -1),
			Vector3.new(0.5, h + 5, -0.3),
		}
	do
		local sz = rand(4.5, 7.5) * s
		box(
			props,
			"Leaves",
			Vector3.new(sz, sz, sz),
			CFrame.new(pos + o * s),
			if roll() > 0.5 then "#3FAF4A" else "#2E9440",
			{ studs = true }
		)
	end
end

local function bush(pos)
	local s = rand(2.5, 4)
	box(
		props,
		"Bush",
		Vector3.new(s * 1.4, s, s * 1.2),
		CFrame.new(pos + Vector3.new(0, s / 2, 0)) * CFrame.Angles(0, rand(0, 3), 0),
		"#34A23F",
		{ studs = true }
	)
end

local FLOWER = { "#FF4F7B", "#FFD23F", "#FFFFFF", "#B98CFF", "#FF7A2E" }
local function flowerBed(pos, yaw)
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw or 0, 0)
	box(props, "Bed", Vector3.new(10, 1, 4), cf * CFrame.new(0, 0.5, 0), "#7A4A24", { studs = true })
	box(props, "Soil", Vector3.new(9, 0.4, 3), cf * CFrame.new(0, 1.1, 0), "#4E3420")
	for i = 0, 7 do
		box(
			props,
			"Flower",
			Vector3.new(0.9, 0.9, 0.9),
			cf * CFrame.new(-3.9 + i * 1.12, 1.8, rand(-0.8, 0.8)),
			FLOWER[i % #FLOWER + 1]
		)
	end
end

local function rock(pos)
	local s = rand(2, 5)
	box(
		props,
		"Rock",
		Vector3.new(s * 1.3, s * 0.8, s),
		CFrame.new(pos + Vector3.new(0, s * 0.35, 0))
			* CFrame.Angles(rand(-0.2, 0.2), rand(0, 3), rand(-0.2, 0.2)),
		"#8A8D93",
		{ studs = true }
	)
end

local function lamp(pos)
	box(props, "LampPost", Vector3.new(0.8, 9, 0.8), CFrame.new(pos + Vector3.new(0, 4.5, 0)), "#2B2E35")
	local head = neon(
		props,
		"LampHead",
		Vector3.new(1.8, 1.4, 1.8),
		CFrame.new(pos + Vector3.new(0, 9.4, 0)),
		"#FFE9A8"
	)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 150)
	light.Brightness = 1
	light.Range = 14
	light.Parent = head
end

local function bench(cf)
	box(
		props,
		"Seat",
		Vector3.new(6, 0.5, 2),
		cf * CFrame.new(0, 1.6, 0),
		"#A9743F",
		{ material = Enum.Material.WoodPlanks }
	)
	box(
		props,
		"Back",
		Vector3.new(6, 1.6, 0.4),
		cf * CFrame.new(0, 2.6, 0.9),
		"#A9743F",
		{ material = Enum.Material.WoodPlanks }
	)
	for _, x in { -2.5, 2.5 } do
		box(props, "Leg", Vector3.new(0.4, 1.4, 1.8), cf * CFrame.new(x, 0.7, 0), "#2B2E35")
	end
end

-- Blocky stand-in players (R15 avatars in game) for scale.
local SHIRTS = { "#2F8CFF", "#FF4F7B", "#2CC764", "#FFB21E", "#8B5CF6", "#1FC1C1", "#FFFFFF", "#E84DDB" }
local function person(cf, i)
	local shirt = SHIRTS[(i % #SHIRTS) + 1]
	local skin = if i % 3 == 0 then "#8D5A3B" elseif i % 3 == 1 then "#F2C9A0" else "#C68E5E"
	box(props, "Legs", Vector3.new(2, 2, 1), cf * CFrame.new(0, 1, 0), "#2B3A67")
	box(props, "Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, 3, 0), shirt)
	box(props, "ArmL", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 3, 0), skin)
	box(props, "ArmR", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 3, 0), skin)
	box(props, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 4.6, 0), skin)
	box(
		props,
		"Hair",
		Vector3.new(1.3, 0.4, 1.3),
		cf * CFrame.new(0, 5.3, 0),
		if i % 2 == 0 then "#3B2414" else "#1B1B1B"
	)
end

-- Brainrots --------------------------------------------------------------------------------------------------

local function rarityOf(id)
	return Config.Species.byId[id].rarity
end

-- The proposed tighter nameplate (§1.4): narrower, shorter lines, hidden beyond 60 studs.
local function tighten(model)
	local anchor = model.PrimaryPart:FindFirstChild("Nameplate")
	local gui = anchor and anchor:FindFirstChild("Nameplate")
	if not gui then
		return 0
	end
	local total = 0
	for _, l in gui:GetChildren() do
		if l:IsA("TextLabel") then
			total += l.Size.Y.Scale
		end
	end
	local lines = 0
	for _, l in gui:GetChildren() do
		if l:IsA("TextLabel") then
			lines += 1
		end
	end
	gui.Size = UDim2.fromScale(NAMEPLATE_W, lines * NAMEPLATE_LINE)
	gui.MaxDistance = NAMEPLATE_MAX_DISTANCE
	return lines * NAMEPLATE_LINE
end

-- Owner-only rows on top of the nameplate (§2.2/2.5): loyalty bar + runaway timer. In game the owner's client
-- adds these rows locally to the replicated nameplate (they never replicate, other players never get the data).
-- state: "ok" | "low" | "leaving"
local OWNER_ROWS = 2 * 0.62 -- studs added on top of the plate
local function ownerStatus(model, plateHeight, loyalty, timer, state)
	local gui = model.PrimaryPart.Nameplate.Nameplate
	local total = plateHeight + OWNER_ROWS
	for _, l in gui:GetChildren() do
		if l:IsA("TextLabel") then
			l.Size = UDim2.fromScale(1, l.Size.Y.Scale * plateHeight / total)
		end
	end
	local bar = Instance.new("Frame")
	bar.Name = "OwnerLoyalty"
	bar.LayoutOrder = -2
	bar.Size = UDim2.fromScale(0.78, 0.62 / total)
	bar.BackgroundColor3 = Color3.fromHex("#3A1630")
	bar:SetAttribute("Bar", loyalty)
	bar:SetAttribute("Icon", "♥")
	bar:SetAttribute("IconColor", Color3.fromHex("#FF4F7B"))
	bar:SetAttribute("OwnerOnly", true)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 =
		Color3.fromHex(if loyalty >= 0.6 then "#FF4F7B" elseif loyalty >= 0.3 then "#FF8FA8" else "#C9A0AE")
	fill.Parent = bar
	bar.Parent = gui
	local t = Instance.new("TextLabel")
	t.Name = "OwnerTimer"
	t.LayoutOrder = -1
	t.Size = UDim2.fromScale(if state == "leaving" then 0.92 else 0.5, 0.62 / total)
	t.Text = timer
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.BackgroundTransparency = 0.15
	t.BackgroundColor3 = Color3.fromHex(if state == "leaving" then "#D61F2C" else "#14121C")
	t.TextColor3 = Color3.fromHex(if state == "low" then "#FFD23F" else "#FFFFFF")
	t:SetAttribute("OwnerOnly", true)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = t
	t.Parent = gui
	gui.Size = UDim2.fromScale(NAMEPLATE_W, total)
end

local function brainrot(id, variant, cf, opts)
	opts = opts or {}
	local model = Brainrot.create(id, rarityOf(id), variant, { price = opts.price })
	if opts.scale then
		Runtime.scale(model, opts.scale)
	end
	local hover = (model:GetAttribute("Hover") or 0) * (opts.scale or 1)
	place(model, cf * CFrame.new(0, hover, 0))
	Runtime.lightning(model, roll)
	local h = tighten(model)
	if opts.stageLine then
		-- growth stage line on nursery brainrots (public: everyone can see a baby is a baby)
		local gui = model.PrimaryPart.Nameplate.Nameplate
		local lines = 0
		for _, l in gui:GetChildren() do
			if l:IsA("TextLabel") then
				lines += 1
			end
		end
		local l = Instance.new("TextLabel")
		l.LayoutOrder = 0
		l.Size = UDim2.fromScale(1, 1 / (lines + 1))
		l.Text = opts.stageLine
		l.TextColor3 = Color3.fromHex("#9FE8FF")
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.BackgroundTransparency = 1
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Parent = l
		for _, other in gui:GetChildren() do
			if other:IsA("TextLabel") then
				other.Size = UDim2.fromScale(1, 1 / (lines + 1))
			end
		end
		l.Parent = gui
		gui.Size = UDim2.fromScale(NAMEPLATE_W, (lines + 1) * NAMEPLATE_LINE)
		h += NAMEPLATE_LINE
	end
	if opts.owner then
		ownerStatus(model, h, opts.owner[1], opts.owner[2], opts.owner[3])
	end
	model.Parent = world
	return model
end

-- Ground, roads ---------------------------------------------------------------------------------------------

box(
	world,
	"Baseplate",
	Vector3.new(MAP_RADIUS * 2, 2, MAP_RADIUS * 2),
	CFrame.new(0, -1, 0),
	FLOOR_BLUE,
	{ studs = true }
)

-- a grassy ring between the hub and the bases (decor lives here)
cyl(world, "Meadow", (RING_ROAD_RADIUS - 6) * 2, 0.3, CFrame.new(0, 0.15, 0), "#4CB848", { studs = true })
cyl(world, "RingRoad", (RING_ROAD_RADIUS + 6) * 2, 0.2, CFrame.new(0, 0.1, 0), PATH_GREY, { studs = true })
cyl(world, "HubEdge", HUB_RADIUS * 2 + 6, 0.5, CFrame.new(0, 0.25, 0), "#8E8E93", { studs = true })
cyl(world, "Hub", HUB_RADIUS * 2, 0.6, CFrame.new(0, 0.3, 0), PLAZA_GREY, { studs = true })

-- spokes: one straight path from every gate to the hub
for i = 1, BASES do
	local deg = (i - 1) * 360 / BASES + 15
	local r0, r1 = HUB_RADIUS - 2, GATE_RADIUS
	local mid = (r0 + r1) / 2
	box(
		world,
		"Spoke",
		Vector3.new(SPOKE_WIDTH, 0.5, r1 - r0),
		facingHub(mid, deg, 0.25),
		PATH_GREY,
		{ studs = true }
	)
	for r = r0 + 14, r1 - 10, 26 do
		for _, side in { -1, 1 } do
			lamp((facingHub(r, deg, 0) * CFrame.new(side * (SPOKE_WIDTH / 2 + 1.5), 0, 0)).Position)
		end
	end
end

-- Decor in the 12 meadow sectors between spokes ----------------------------------------------------------

local function nearSpoke(p)
	local deg = math.deg(math.atan2(p.Z, p.X))
	for i = 1, BASES do
		local s = (i - 1) * 360 / BASES + 15
		local d = math.abs(((deg - s + 180) % 360) - 180)
		local r = p.Magnitude
		if math.rad(d) * r < SPOKE_WIDTH / 2 + 7 then
			return true
		end
	end
	return false
end

local function pond(cf)
	cyl(props, "PondRim", 30, 0.8, cf * CFrame.new(0, 0.4, 0), "#8A8D93", { studs = true })
	cyl(
		props,
		"Pond",
		27,
		0.9,
		cf * CFrame.new(0, 0.5, 0),
		"#3FA8F5",
		{ material = Enum.Material.Glass, transparency = 0.15 }
	)
	box(
		props,
		"Bridge",
		Vector3.new(5, 0.8, 32),
		cf * CFrame.new(0, 1.6, 0),
		"#A9743F",
		{ material = Enum.Material.WoodPlanks }
	)
	for _, z in { -14, 14 } do
		box(
			props,
			"BridgeEnd",
			Vector3.new(5, 1.2, 2),
			cf * CFrame.new(0, 0.8, z),
			"#8A5A2E",
			{ material = Enum.Material.WoodPlanks }
		)
	end
	for _, o in { Vector3.new(-7, 1.05, 5), Vector3.new(6, 1.05, -6), Vector3.new(-5, 1.05, -8) } do
		cyl(props, "LilyPad", 2.4, 0.1, cf * CFrame.new(o), "#3FAF4A")
	end
end

local function pizzaStatue(cf)
	box(props, "Plinth", Vector3.new(10, 3, 10), cf * CFrame.new(0, 1.5, 0), "#B4B4B8", { studs = true })
	-- a giant pizza slice standing on its tip
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.Size = Vector3.new(1.4, 14, 6)
	w.CFrame = cf * CFrame.new(-3, 10, 0) * CFrame.Angles(0, math.rad(90), math.rad(180))
	w.Color = Color3.fromHex("#FFC94A")
	w.Parent = props
	local w2 = Instance.new("WedgePart")
	w2.Anchored = true
	w2.Size = Vector3.new(1.4, 14, 6)
	w2.CFrame = cf * CFrame.new(3, 10, 0) * CFrame.Angles(0, math.rad(-90), math.rad(180))
	w2.Color = Color3.fromHex("#FFC94A")
	w2.Parent = props
	box(props, "Crust", Vector3.new(13, 2, 2), cf * CFrame.new(0, 17, 0), "#C8873A", { studs = true })
	for _, o in { Vector3.new(-2, 13, -1), Vector3.new(1.5, 11, -1), Vector3.new(-0.5, 8.5, -1) } do
		cyl(props, "Pepperoni", 2, 0.3, cf * CFrame.new(o) * CFrame.Angles(math.rad(90), 0, 0), "#C0392B")
	end
end

local function windmill(cf)
	box(props, "MillBase", Vector3.new(10, 16, 10), cf * CFrame.new(0, 8, 0), "#E8E2D4", { studs = true })
	box(props, "MillRoof", Vector3.new(11, 3, 11), cf * CFrame.new(0, 17.5, 0), "#C0392B", { studs = true })
	box(props, "Door", Vector3.new(3, 5, 0.4), cf * CFrame.new(0, 2.5, -5.1), "#7A4A24")
	for k = 0, 3 do
		box(
			props,
			"Blade",
			Vector3.new(2, 11, 0.4),
			cf * CFrame.new(0, 13, -5.6) * CFrame.Angles(0, 0, math.rad(k * 90 + 20)) * CFrame.new(0, 6, 0),
			"#FFFFFF"
		)
	end
end

local function cupFountain(cf)
	cyl(props, "FountainPool", 20, 1.2, cf * CFrame.new(0, 0.6, 0), "#B4B4B8", { studs = true })
	cyl(
		props,
		"FountainWater",
		18,
		1.3,
		cf * CFrame.new(0, 0.7, 0),
		"#5AC8FF",
		{ material = Enum.Material.Glass, transparency = 0.2 }
	)
	cyl(props, "Cup", 7, 7, cf * CFrame.new(0, 4.5, 0), "#FFFFFF", { studs = true })
	cyl(props, "Foam", 6.4, 0.6, cf * CFrame.new(0, 8.1, 0), "#E8C9A0")
	box(props, "Handle", Vector3.new(1, 4, 3), cf * CFrame.new(4.2, 4.5, 0), "#FFFFFF")
	cyl(props, "Saucer", 11, 0.6, cf * CFrame.new(0, 1.5, 0), "#FFFFFF")
end

local function picnic(cf)
	for k = 0, 2 do
		local c = cf * CFrame.new(-10 + k * 10, 0, rand(-3, 3))
		box(
			props,
			"Table",
			Vector3.new(6, 0.5, 3),
			c * CFrame.new(0, 2.6, 0),
			"#A9743F",
			{ material = Enum.Material.WoodPlanks }
		)
		box(props, "Leg", Vector3.new(0.6, 2.4, 0.6), c * CFrame.new(0, 1.2, 0), "#7A4A24")
		cyl(props, "Pole", 0.3, 7, c * CFrame.new(0, 4.5, 0), "#FFFFFF")
		cyl(props, "Umbrella", 7, 0.6, c * CFrame.new(0, 8, 0), if k % 2 == 0 then "#FF4F7B" else "#2F8CFF")
		box(
			props,
			"Blanket",
			Vector3.new(5, 0.1, 5),
			c * CFrame.new(0, 0.35, 5),
			if k % 2 == 0 then "#FF3B3B" else "#FFFFFF"
		)
	end
end

local function playground(cf)
	box(props, "SlideTower", Vector3.new(5, 7, 5), cf * CFrame.new(0, 3.5, 0), "#FFB21E", { studs = true })
	box(
		props,
		"Slide",
		Vector3.new(3, 0.5, 10),
		cf * CFrame.new(0, 3.6, -7) * CFrame.Angles(math.rad(-35), 0, 0),
		"#FF4F7B"
	)
	box(props, "SwingBar", Vector3.new(10, 0.6, 0.6), cf * CFrame.new(12, 7, 0), "#2F8CFF")
	for _, x in { 7.5, 16.5 } do
		box(props, "SwingPost", Vector3.new(0.6, 7, 0.6), cf * CFrame.new(x, 3.5, 0), "#2F8CFF")
	end
	for _, x in { 10, 14 } do
		box(props, "Swing", Vector3.new(1.6, 0.3, 1), cf * CFrame.new(x, 2, 0), "#2CC764")
	end
end

local LANDMARKS = { pond, pizzaStatue, windmill, cupFountain, picnic, playground }
for i = 1, BASES do
	local mid = (i - 1) * 360 / BASES -- sector centre (between spokes at 15 + 30k)
	local landmarkR = (HUB_RADIUS + RING_ROAD_RADIUS) / 2 + rand(-12, 12)
	local lm = LANDMARKS[(i - 1) % #LANDMARKS + 1]
	lm(facingHub(landmarkR, mid, 0))
	for _ = 1, 26 do
		local p = polar(rand(HUB_RADIUS + 10, RING_ROAD_RADIUS - 10), mid + rand(-13, 13))
		if not nearSpoke(p) and (p - polar(landmarkR, mid)).Magnitude > 22 then
			local k = roll()
			if k < 0.4 then
				tree(p, rand(0.8, 1.2))
			elseif k < 0.65 then
				bush(p)
			elseif k < 0.8 then
				rock(p)
			else
				flowerBed(p, rand(0, 3))
			end
		end
	end
	-- benches facing the spoke on each side
	local s = mid + 15
	for _, side in { -1, 1 } do
		bench(
			facingHub(HUB_RADIUS + 40, s, 0)
				* CFrame.new(side * (SPOKE_WIDTH / 2 + 5), 0, 0)
				* CFrame.Angles(0, math.rad(-90 * side), 0)
		)
	end
end
-- outer tree line behind the bases
for k = 1, 90 do
	local p = polar(MAP_RADIUS - rand(10, 30), k * 4 + rand(-1, 1))
	tree(p, rand(0.9, 1.3))
end

-- Hub ----------------------------------------------------------------------------------------------------------

local hub = Parts.folder("Hub", world)
local HUB_TOP = 0.6

-- central island with the portal tower
cyl(hub, "Island", ISLAND_RADIUS * 2, 0.6, CFrame.new(0, HUB_TOP + 0.3, 0), "#4CB848", { studs = true })
for k = 0, 11 do
	local p = polar(ISLAND_RADIUS - 4, k * 30 + 15, HUB_TOP)
	if k ~= 0 and k ~= 11 then
		bush(p)
	end
end
-- portal faces +X (down the ramp to the loop)
local portalCF = CFrame.new(4, HUB_TOP, 0) * CFrame.Angles(0, math.rad(-90), 0)
box(hub, "PortalBase", Vector3.new(18, 2, 8), portalCF * CFrame.new(0, 1, 0), BUILDING_DARK, { studs = true })
for _, side in { -1, 1 } do
	box(
		hub,
		"PortalPillar",
		Vector3.new(3, 16, 3),
		portalCF * CFrame.new(side * 7.5, 10, 0),
		BUILDING_DARK,
		{ studs = true }
	)
	neon(hub, "PortalNeon", Vector3.new(0.5, 15, 3.2), portalCF * CFrame.new(side * 5.9, 10, 0), "#B15CFF")
end
box(
	hub,
	"PortalTop",
	Vector3.new(18, 3, 3),
	portalCF * CFrame.new(0, 19.5, 0),
	BUILDING_DARK,
	{ studs = true }
)
local disc = cyl(
	hub,
	"PortalDisc",
	12.5,
	0.5,
	portalCF * CFrame.new(0, 9.5, 0) * CFrame.Angles(math.rad(90), 0, 0),
	"#8A3CFF",
	{ material = Enum.Material.Neon }
)
local pl = Instance.new("PointLight")
pl.Color = Color3.fromRGB(170, 110, 255)
pl.Range = 30
pl.Brightness = 3
pl.Parent = disc
local screen = box(hub, "PortalScreen", Vector3.new(22, 6, 0.6), portalCF * CFrame.new(0, 24, 0), WINDOW)
surfaceText(screen, Enum.NormalId.Back, { { "NEW BRAINROTS EVERY FEW SECONDS!", "#FFFFFF" } })
floating(Vector3.new(0, 34, 0), { { "CONVEYOR", "#FF5C5C" } }, 22, 4.2, 600)

-- server-wide announcement for a Rare+ spawn (lives on the shared carpet now)
floating(Vector3.new(0, 46, 0), {
	{ "LEGENDARY SPAWNED!", "#FFD23F", 1 },
	{ "Bombardiro Crocodilo is on the carpet", "#FFFFFF", 0.7 },
}, 28, 3, 600)

-- ramp from the portal to the loop, then the loop (counter-clockwise), then the exit vortex
local carpet = Parts.folder("Carpet", hub)
local rampLen = CARPET_RADIUS - 8
box(
	carpet,
	"CarpetRamp",
	Vector3.new(rampLen, 0.4, CARPET_WIDTH),
	CFrame.new(8 + rampLen / 2 - 1, HUB_TOP + 0.8, 0),
	CARPET_RED,
	{ studs = true }
)
local SEGMENTS = 44
local startDeg = 8 -- the loop starts just past the ramp and runs CARPET_SWEEP_DEG
local loopPoints = {}
for k = 0, SEGMENTS - 1 do
	local a0 = startDeg + k * CARPET_SWEEP_DEG / SEGMENTS
	local a1 = startDeg + (k + 1) * CARPET_SWEEP_DEG / SEGMENTS
	local p0, p1 = polar(CARPET_RADIUS, a0, HUB_TOP + 0.8), polar(CARPET_RADIUS, a1, HUB_TOP + 0.8)
	local len = (p1 - p0).Magnitude + 0.9
	local cf = CFrame.lookAt((p0 + p1) / 2, p1)
	box(carpet, "Carpet", Vector3.new(CARPET_WIDTH, 0.4, len), cf, CARPET_RED, { studs = true })
	table.insert(loopPoints, { p = (p0 + p1) / 2, cf = cf })
end
-- connector from the ramp end onto the loop
box(
	carpet,
	"CarpetJoin",
	Vector3.new(CARPET_WIDTH, 0.4, 10),
	CFrame.new(CARPET_RADIUS, HUB_TOP + 0.8, 2),
	CARPET_RED,
	{ studs = true }
)
-- exit vortex where unsold brainrots despawn
local exitP = polar(CARPET_RADIUS, startDeg + CARPET_SWEEP_DEG + 4, HUB_TOP)
cyl(
	hub,
	"ExitVortex",
	9,
	0.4,
	CFrame.new(exitP + Vector3.new(0, 0.45, 0)),
	"#2B1240",
	{ material = Enum.Material.Neon }
)
cyl(
	hub,
	"ExitVortexCore",
	5,
	0.5,
	CFrame.new(exitP + Vector3.new(0, 0.5, 0)),
	"#8A3CFF",
	{ material = Enum.Material.Neon }
)
floating(exitP + Vector3.new(0, 6, 0), { { "Unsold brainrots leave here", "#FFFFFF" } }, 12, 1.4, 120)

-- brainrots walking the loop (with prices), counter-clockwise
local walkers = {
	{ "tralalero_tralala", "Normal" },
	{ "brr_brr_patapim", "Normal" },
	{ "cappuccino_assassino", "Rainbow" },
	{ "tung_tung_tung_sahur", "Normal" },
	{ "ballerina_cappuccina", "Normal" },
	{ "bombardiro_crocodilo", "Normal" },
	{ "brr_brr_patapim", "Evil" },
	{ "cappuccino_assassino", "Normal" },
	{ "tralalero_tralala", "Rainbow" },
	{ "ballerina_cappuccina", "Normal" },
	{ "tung_tung_tung_sahur", "Normal" },
	{ "brr_brr_patapim", "Normal" },
}
for k, w in walkers do
	local idx = math.floor((k - 0.5) / #walkers * #loopPoints) + 1
	local lp = loopPoints[idx]
	local price = ShopStock.priceFor(rarityOf(w[1]), w[2], roll)
	brainrot(
		w[1],
		w[2],
		CFrame.new(lp.p + Vector3.new(0, 0.2, 0))
			* (lp.cf - lp.cf.Position)
			* CFrame.Angles(0, math.rad(180), 0),
		{ price = price }
	)
end

-- stall (Egg Shop / Food Shop) -----------------------------------------------------------------------------

local function stall(cf, name, label, labelColor, awning, hat, goods)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = hub
	local function p(n, size, offset, color, mat, studs)
		return box(m, n, size, cf * offset, color, { material = mat, studs = studs })
	end
	p("Platform", Vector3.new(22, 1.6, 14), CFrame.new(0, 0.8, 1.5), "#9E9EA3", nil, true)
	p("Step", Vector3.new(22, 0.8, 2), CFrame.new(0, 0.4, -6.5), "#B4B4B8", nil, true)
	local y0 = 1.6
	p("Counter", Vector3.new(16, 3, 2.4), CFrame.new(0, y0 + 1.5, -1), "#8A5A2E", Enum.Material.WoodPlanks)
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
		return box(m, n, size, cf * CFrame.new(0, y0 + 3.5, -1.2) * offset, color, { shape = shape })
	end)
	-- merchant
	box(m, "Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, y0 + 4.4, 2), "#C98A55")
	box(m, "Head", Vector3.new(2, 1.2, 1.2), cf * CFrame.new(0, y0 + 6, 2), "#D9A066")
	box(m, "Hat", Vector3.new(2.3, 0.9, 1.5), cf * CFrame.new(0, y0 + 7, 2), hat)
	floating((cf * CFrame.new(0, y0 + 13, 0)).Position, { { label, labelColor } }, 14, 3.6, 500)
	floating((cf * CFrame.new(0, y0 + 10.6, -4)).Position, { { "[E] Shop", "#FFFFFF" } }, 5, 1, 50)
end

-- Egg Shop at -30 deg, Food Shop at +30 deg (both face the conveyor and the camera side)
stall(facingHub(62, -30, HUB_TOP), "EggShop", "Egg Shop", "#3DE05C", "#2C7BE5", "#2C7BE5", function(g)
	for i, c in { "#FFF4E0", "#B98CFF", "#FFD23F", "#7CE0FF" } do
		g("Egg", Vector3.new(1.4, 1.8, 1.4), CFrame.new(-4.5 + (i - 1) * 3, 0.9, 0), c, Enum.PartType.Ball)
	end
end)
stall(facingHub(62, 30, HUB_TOP), "FoodShop", "Food Shop", "#FF9A1F", "#E0262C", "#FFFFFF", function(g)
	-- pizza, spaghetti bowl, gelato tower, banquet platter
	g("Pizza", Vector3.new(0.3, 3, 3), CFrame.new(-5, 0.2, 0) * UP, "#FFC94A", Enum.PartType.Cylinder)
	g(
		"PizzaSauce",
		Vector3.new(0.32, 2.4, 2.4),
		CFrame.new(-5, 0.22, 0) * UP,
		"#D9442B",
		Enum.PartType.Cylinder
	)
	g("Bowl", Vector3.new(1.2, 2.4, 2.4), CFrame.new(-1.6, 0.6, 0) * UP, "#FFFFFF", Enum.PartType.Cylinder)
	g("Spaghetti", Vector3.new(0.5, 2, 2), CFrame.new(-1.6, 1.3, 0) * UP, "#F2D06B", Enum.PartType.Cylinder)
	for k = 0, 2 do
		g(
			"Gelato",
			Vector3.new(1.3, 1.3, 1.3),
			CFrame.new(1.6, 0.6 + k * 1.1, 0),
			({ "#FFB3C7", "#B6F0B0", "#FFF1B5" })[k + 1],
			Enum.PartType.Ball
		)
	end
	g("Platter", Vector3.new(0.3, 3.4, 3.4), CFrame.new(5, 0.2, 0) * UP, "#FFD23F", Enum.PartType.Cylinder)
	g("Roast", Vector3.new(2, 1.2, 1.4), CFrame.new(5, 0.9, 0), "#B5651D")
end)

-- leaderboards (90 deg)
do
	local cf = facingHub(66, 90, HUB_TOP)
	local titles = { "TOP CASH", "MOST STEALS", "BEST BREEDER" }
	for k = -1, 1 do
		local b = cf * CFrame.new(k * 11, 0, 0)
		box(hub, "BoardPost", Vector3.new(1, 12, 1), b * CFrame.new(-4, 6, 0.5), BUILDING_DARK)
		box(hub, "BoardPost", Vector3.new(1, 12, 1), b * CFrame.new(4, 6, 0.5), BUILDING_DARK)
		local board = box(hub, "Leaderboard", Vector3.new(9.5, 11, 0.6), b * CFrame.new(0, 9, 0), "#1B1D24")
		neon(hub, "BoardTrim", Vector3.new(9.9, 0.4, 0.8), b * CFrame.new(0, 14.6, 0), "#FFD23F")
		surfaceText(board, Enum.NormalId.Front, {
			{ titles[k + 2], "#FFD23F", 1.4 },
			{ "1. NoobMaster   $4.2B", "#FFFFFF" },
			{ "2. Brainrotter  $3.9B", "#FFFFFF" },
			{ "3. Tralalala    $2.1B", "#FFFFFF" },
			{ "4. xX_Tung_Xx   $1.8B", "#FFFFFF" },
			{ "5. Bombardino   $1.2B", "#FFFFFF" },
		})
	end
	floating((cf * CFrame.new(0, 19, 0)).Position, { { "Leaderboards", "#FFD23F" } }, 14, 3, 500)
end

-- event stage (150 deg)
do
	local cf = facingHub(64, 150, HUB_TOP)
	box(hub, "Stage", Vector3.new(30, 3, 16), cf * CFrame.new(0, 1.5, 2), "#3B3F47", { studs = true })
	box(hub, "StageFloor", Vector3.new(28, 0.4, 14), cf * CFrame.new(0, 3.2, 2), "#5A2E8A", { studs = true })
	for _, x in { -14, 14 } do
		box(hub, "Truss", Vector3.new(1.4, 16, 1.4), cf * CFrame.new(x, 11, 8), "#B4B4B8")
		box(hub, "Speaker", Vector3.new(3, 5, 3), cf * CFrame.new(x * 0.82, 5.6, 0), "#1B1D24")
	end
	box(hub, "TrussTop", Vector3.new(30, 1.4, 1.4), cf * CFrame.new(0, 19, 8), "#B4B4B8")
	for k = -3, 3 do
		neon(
			hub,
			"StageLight",
			Vector3.new(1.4, 1.2, 1.4),
			cf * CFrame.new(k * 4, 17.8, 8),
			({ "#FF4F7B", "#FFD23F", "#2F8CFF", "#2CC764" })[(k + 3) % 4 + 1]
		)
	end
	local banner = box(hub, "Banner", Vector3.new(24, 5, 0.4), cf * CFrame.new(0, 14, 8.6), "#E0262C")
	surfaceText(banner, Enum.NormalId.Front, { { "EVENT STAGE", "#FFFFFF" } })
	floating((cf * CFrame.new(0, 24, 4)).Position, { { "Event Stage", "#FF7AC8" } }, 14, 3, 500)
end

-- trading zone (210 deg)
do
	local cf = facingHub(62, 210, HUB_TOP)
	cyl(hub, "TradeRing", 30, 0.3, cf * CFrame.new(0, 0.15, 0), "#FFD23F", { studs = true })
	cyl(hub, "TradeFloor", 26, 0.35, cf * CFrame.new(0, 0.2, 0), "#2F8CFF", { studs = true })
	for k = -1, 1, 2 do
		local t = cf * CFrame.new(k * 6, 0, 0)
		box(hub, "TradeTable", Vector3.new(5, 0.6, 3), t * CFrame.new(0, 3, 0), "#FFFFFF")
		box(hub, "TradeLeg", Vector3.new(0.8, 2.8, 0.8), t * CFrame.new(0, 1.4, 0), "#B4B4B8")
	end
	floating((cf * CFrame.new(0, 10, 0)).Position, { { "Trade Zone", "#7CE0FF" } }, 12, 3, 500)
end

-- hangout (270 deg): benches round a fountain
do
	local cf = facingHub(62, 270, HUB_TOP)
	cupFountain(cf)
	for k = 0, 5 do
		bench(cf * CFrame.Angles(0, math.rad(k * 60), 0) * CFrame.new(0, 0, -15))
	end
	floating((cf * CFrame.new(0, 14, 0)).Position, { { "Hangout", "#FFFFFF" } }, 10, 2.6, 500)
end

-- players around the hub
for k = 1, 14 do
	local deg = rand(0, 360)
	local r = rand(44, 78)
	person(facingHub(r, deg, HUB_TOP), k)
end

-- Bases ---------------------------------------------------------------------------------------------------------

local function wallSeg(origin, parent, accent, x0, z0, x1, z1, h)
	h = h or WALL_H
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local sx, sz = math.max(2, math.abs(x1 - x0)), math.max(2, math.abs(z1 - z0))
	box(
		parent,
		"Wall",
		Vector3.new(sx, h, sz),
		origin * CFrame.new(cx, FLOOR_TOP + h / 2, cz),
		BUILDING,
		{ studs = true }
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
		BUILDING_DARK,
		{ studs = true }
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
			WINDOW,
			{ material = Enum.Material.Glass, canCollide = false }
		)
	end
end

-- 14 pedestals: 4 columns 12 studs apart x 4 rows 11 apart, minus the 2 inner front slots (gate path)
local SLOTS = {}
for _, z in { -26, -15, -4, 7 } do
	for _, x in { -23, -11, 11, 23 } do
		if not (z == -26 and math.abs(x) == 11) then
			table.insert(SLOTS, { x = x, z = z, tier = 0 })
		end
	end
end
for i = 11, 14 do
	SLOTS[i].tier = if i <= 12 then 1 elseif i == 13 then 2 else 3
end

local INCUBATORS = 6 -- 3 free + 3 game-pass tiers
local function buildBase(index, opts)
	local deg = (index - 1) * 360 / BASES + 15
	local origin = facingHub(BASE_RADIUS, deg, 0)
	local accent = ACCENTS[index]
	local m = Instance.new("Model")
	m.Name = `Base{index}`
	m.Parent = world
	local hw, hd = BASE_W / 2, BASE_D / 2
	box(
		m,
		"Floor",
		Vector3.new(BASE_W, 1, BASE_D),
		origin * CFrame.new(0, FLOOR_TOP - 0.5, 0),
		"#5A5E66",
		{ studs = true }
	)
	-- outer walls: front with the gate, sides with the escape exits, back taller
	local g = 7
	wallSeg(origin, m, accent, -hw, -hd, -g - 1.5, -hd)
	wallSeg(origin, m, accent, g + 1.5, -hd, hw, -hd)
	wallSeg(origin, m, accent, -hw, hd, hw, hd, WALL_H + 6)
	for _, side in { -1, 1 } do
		wallSeg(origin, m, accent, side * hw, -hd, side * hw, -14)
		wallSeg(origin, m, accent, side * hw, -4, side * hw, hd)
		-- escape exit frame
		neon(
			m,
			"ExitFrame",
			Vector3.new(0.6, 9, 0.6),
			origin * CFrame.new(side * hw, FLOOR_TOP + 4.5, -14),
			"#FF7A2E"
		)
		neon(
			m,
			"ExitFrame",
			Vector3.new(0.6, 9, 0.6),
			origin * CFrame.new(side * hw, FLOOR_TOP + 4.5, -4),
			"#FF7A2E"
		)
		box(
			m,
			"GatePillar",
			Vector3.new(3, WALL_H + 3, 3),
			origin * CFrame.new(side * (g + 1.5), FLOOR_TOP + (WALL_H + 3) / 2, -hd),
			BUILDING_DARK,
			{ studs = true }
		)
		neon(
			m,
			"GateNeon",
			Vector3.new(0.4, WALL_H + 2, 3.2),
			origin * CFrame.new(side * (g + 1.5) - side * 1.6, FLOOR_TOP + (WALL_H + 2) / 2, -hd),
			accent
		)
	end
	local beam = box(
		m,
		"GateBeam",
		Vector3.new(2 * g + 6, 3, 3),
		origin * CFrame.new(0, FLOOR_TOP + WALL_H + 1.5, -hd),
		BUILDING_DARK,
		{ studs = true }
	)
	surfaceText(beam, Enum.NormalId.Front, {
		{
			if opts.owner == "You"
				then "Your Base"
				elseif opts.owner then `{opts.owner}'s Base`
				else "FREE BASE",
			"#FFFFFF",
		},
	})

	-- pedestals
	for slot, def in SLOTS do
		local locked = def.tier > 0 and not opts.allSlots
		cyl(
			m,
			`Slot{slot}`,
			5,
			1.6,
			origin * CFrame.new(def.x, FLOOR_TOP + 0.8, def.z),
			if locked then "#6E717A" else "#D8D8DC",
			{ transparency = if locked then 0.5 else 0 }
		)
		cyl(
			m,
			"Rim",
			5.4,
			0.3,
			origin * CFrame.new(def.x, FLOOR_TOP + 0.2, def.z),
			if locked then "#4A4D55" else accent,
			{ material = Enum.Material.Neon, transparency = if locked then 0.6 else 0.2 }
		)
	end
	-- collector by the gate
	neon(m, "Collector", Vector3.new(8, 0.5, 5), origin * CFrame.new(-19, FLOOR_TOP + 0.25, -35), "#FFD23F")

	-- nursery: walled room across the back
	local nz0, nz1 = NURSERY_Z, hd
	local nurseryFloor = if opts.nursery == "unlocked" then "#FFD6E8" else "#6E6E73"
	box(
		m,
		"NurseryFloor",
		Vector3.new(BASE_W - 2, 0.2, nz1 - nz0 - 1),
		origin * CFrame.new(0, FLOOR_TOP + 0.1, (nz0 + nz1) / 2),
		nurseryFloor,
		{ studs = true }
	)
	-- inner wall with a door (6 wide) and two windows
	local door = 4
	wallSeg(origin, m, "#FF8FC8", -hw, nz0, -door, nz0, WALL_H - 2)
	wallSeg(origin, m, "#FF8FC8", door, nz0, hw, nz0, WALL_H - 2)
	box(
		m,
		"DoorTop",
		Vector3.new(door * 2, 2, 2),
		origin * CFrame.new(0, FLOOR_TOP + WALL_H - 3, nz0),
		BUILDING_DARK,
		{ studs = true }
	)
	local signPart = box(
		m,
		"NurserySign",
		Vector3.new(12, 2.6, 0.4),
		origin * CFrame.new(0, FLOOR_TOP + WALL_H + 0.4, nz0 - 1.2),
		"#FF8FC8",
		{ studs = true }
	)
	surfaceText(signPart, Enum.NormalId.Front, { { "NURSERY", "#FFFFFF" } })
	-- incubators along the back wall
	for k = 1, INCUBATORS do
		local x = -22.5 + (k - 1) * 9
		local c = origin * CFrame.new(x, FLOOR_TOP, nz1 - 7)
		local passLocked = k > 3
		if opts.nursery == "unlocked" then
			cyl(
				m,
				"IncubatorBase",
				5.4,
				1.4,
				c * CFrame.new(0, 0.7, 0),
				if passLocked then "#9A9AA2" else "#FFFFFF"
			)
			neon(
				m,
				"IncubatorRing",
				Vector3.new(5.6, 0.3, 5.6),
				c * CFrame.new(0, 1.45, 0),
				if passLocked then "#6E6E73" else "#7CE0FF"
			)
			ball(
				m,
				"IncubatorDome",
				5,
				c * CFrame.new(0, 2.6, 0),
				"#BFEFFF",
				{ material = Enum.Material.Glass, transparency = if passLocked then 0.75 else 0.55 }
			)
			if not passLocked and k ~= 3 then
				ball(m, "Egg", 2.2, c * CFrame.new(0, 2.6, 0), if k == 1 then "#B98CFF" else "#FFD23F")
				floating(
					(c * CFrame.new(0, 6.2, 0)).Position,
					{ { if k == 1 then "Hatching 2:14" else "Hatching 0:48", "#FFFFFF" } },
					4.6,
					1,
					60
				)
			elseif passLocked then
				floating(
					(c * CFrame.new(0, 5.4, 0)).Position,
					{ { "Extra slot (pass)", "#FFD23F" } },
					5,
					0.9,
					60
				)
			else
				floating((c * CFrame.new(0, 5.2, 0)).Position, { { "Empty", "#FFFFFF" } }, 3, 0.9, 60)
			end
		else
			-- covered incubators in the dark, locked room
			box(
				m,
				"Covered",
				Vector3.new(5, 4.2, 5),
				c * CFrame.new(0, 2.1, 0),
				"#8A8D93",
				{ material = Enum.Material.Fabric }
			)
		end
	end
	if opts.nursery == "unlocked" then
		-- feeding trough, toy blocks
		box(
			m,
			"Trough",
			Vector3.new(10, 1.4, 3),
			origin * CFrame.new(-20, FLOOR_TOP + 0.7, nz0 + 6),
			"#A9743F",
			{ material = Enum.Material.WoodPlanks }
		)
		box(
			m,
			"Food",
			Vector3.new(9, 0.4, 2.2),
			origin * CFrame.new(-20, FLOOR_TOP + 1.5, nz0 + 6),
			"#F2D06B"
		)
		for k, c in { "#FF4F7B", "#2F8CFF", "#FFD23F" } do
			box(
				m,
				"ToyBlock",
				Vector3.new(2, 2, 2),
				origin * CFrame.new(20 + (k - 2) * 2.4, FLOOR_TOP + 1, nz0 + 5) * CFrame.Angles(0, k * 0.4, 0),
				c,
				{ studs = true }
			)
		end
	else
		-- barred door, padlock, unlock price
		for k = -1, 1 do
			neon(
				m,
				"Bar",
				Vector3.new(0.4, WALL_H - 4, 0.4),
				origin * CFrame.new(k * 2.6, FLOOR_TOP + (WALL_H - 4) / 2, nz0),
				"#FF3B3B"
			)
		end
		for _, y in { 2.5, 6 } do
			neon(
				m,
				"Bar",
				Vector3.new(door * 2, 0.4, 0.4),
				origin * CFrame.new(0, FLOOR_TOP + y, nz0),
				"#FF3B3B"
			)
		end
		box(
			m,
			"Padlock",
			Vector3.new(2.4, 2.2, 0.8),
			origin * CFrame.new(0, FLOOR_TOP + 4.2, nz0 - 0.6),
			"#FFD23F",
			{ material = Enum.Material.Metal }
		)
		box(
			m,
			"Shackle",
			Vector3.new(1.6, 1.2, 0.4),
			origin * CFrame.new(0, FLOOR_TOP + 5.8, nz0 - 0.6),
			"#B4B4B8",
			{ material = Enum.Material.Metal }
		)
		floating((origin * CFrame.new(0, FLOOR_TOP + 9, nz0 - 3)).Position, {
			{ "NURSERY LOCKED", "#FF5C5C", 1 },
			{ "Unlock: $250,000  or  R$ 99", "#7CFF9B", 0.8 },
		}, 11, 1.3, 120)
	end
	return origin
end

-- Escape lanes between neighbouring bases' side exits (arc at LANE_RADIUS) ------------------------------
local LANE_COLORS = { "#FF4F7B", "#FFD23F", "#2CC764", "#8B5CF6", "#FF7A2E", "#1FC1C1" }
local lanes = Parts.folder("EscapeLanes", world)
for i = 1, BASES do
	local d0 = (i - 1) * 360 / BASES + 15
	local exitDeg = math.deg((BASE_W / 2 + 2) / LANE_RADIUS)
	local a0, a1 = d0 + exitDeg, d0 + 360 / BASES - exitDeg
	local n = 9
	for k = 0, n - 1 do
		local a = a0 + (k + 0.5) * (a1 - a0) / n
		local cf =
			facingHub(LANE_RADIUS + (if k % 2 == 0 then 1.5 else -1.5), a, FLOOR_TOP + 0.5 + (k % 3) * 1.2)
		box(
			lanes,
			"LaneBlock",
			Vector3.new(7, 1, 5),
			cf,
			LANE_COLORS[(k + i) % #LANE_COLORS + 1],
			{ studs = true }
		)
	end
	-- jump pad in the middle of each lane
	local mid = facingHub(LANE_RADIUS, (a0 + a1) / 2, FLOOR_TOP + 2.6)
	neon(lanes, "JumpPad", Vector3.new(4, 0.3, 4), mid * CFrame.new(0, 0.7, 0), "#7CFF9B")
end

-- the 12 bases: base 1 is yours (nursery unlocked), base 2 a neighbour with it locked
local yourOrigin
local neighbourOrigin
local owners = {
	"You",
	"Brainrotter",
	"NoobMaster",
	"Tralalala",
	"xX_Tung_Xx",
	nil,
	"Bombardino",
	"GelatoKid",
	nil,
	"Patapim99",
	"Sahur4Life",
	"CappuCat",
}
for i = 1, BASES do
	local o = buildBase(i, {
		owner = owners[i],
		nursery = if i == 1 or (i > 2 and i % 3 == 0) then "unlocked" else "locked",
		allSlots = i == 1,
	})
	if i == 1 then
		yourOrigin = o
	elseif i == 2 then
		neighbourOrigin = o
	end
end

-- Brainrots in the bases ------------------------------------------------------------------------------------
-- Your base: owner overlays (loyalty bar + runaway timer) on every brainrot you own.
local mine = {
	{ 1, "tralalero_tralala", "Rainbow", { 0.92, "12d 4h", "ok" } },
	{ 2, "ballerina_cappuccina", "Normal", { 0.7, "5d 18h", "ok" } },
	{ 3, "brr_brr_patapim", "Normal", { 0.35, "0d 9h", "low" } },
	{ 4, "bombardiro_crocodilo", "Normal", { 0.6, "3d 6h", "ok" } },
	{ 5, "tung_tung_tung_sahur", "Evil", { 0.12, "LEAVING TONIGHT!", "leaving" } },
	{ 6, "cappuccino_assassino", "Normal", { 0.8, "8d 2h", "ok" } },
	{ 7, "ballerina_cappuccina", "Rainbow", { 0.5, "1d 20h", "ok" } },
	{ 9, "brr_brr_patapim", "Normal", { 0.25, "0d 3h", "low" } },
}
for _, b in mine do
	local def = SLOTS[b[1]]
	local cf = yourOrigin * CFrame.new(def.x, FLOOR_TOP + 1.6, def.z)
	if b[4][3] == "leaving" then
		cf *= CFrame.Angles(0, math.rad(150), 0) -- restless: turned to look out toward the hub
	end
	brainrot(b[2], b[3], cf, { owner = b[4] })
end
-- nursery babies/teens (public stage line + owner overlay)
brainrot(
	"tung_tung_tung_sahur",
	"Normal",
	yourOrigin * CFrame.new(-8, FLOOR_TOP, NURSERY_Z + 10) * CFrame.Angles(0, math.rad(20), 0),
	{ scale = 0.5, stageLine = "Baby", owner = { 0.55, "2d 0h", "ok" } }
)
brainrot(
	"ballerina_cappuccina",
	"Normal",
	yourOrigin * CFrame.new(6, FLOOR_TOP, NURSERY_Z + 12) * CFrame.Angles(0, math.rad(-30), 0),
	{ scale = 0.72, stageLine = "Teen", owner = { 0.8, "6d 10h", "ok" } }
)
brainrot(
	"cappuccino_assassino",
	"Normal",
	yourOrigin * CFrame.new(16, FLOOR_TOP, NURSERY_Z + 8),
	{ scale = 0.5, stageLine = "Baby", owner = { 0.3, "0d 14h", "low" } }
)
person(yourOrigin * CFrame.new(3, FLOOR_TOP, -10) * CFrame.Angles(0, math.rad(200), 0), 3)

-- Neighbour's base: no overlays (other players never see loyalty or timers)
local theirs = {
	{ 1, "tung_tung_tung_sahur", "Normal" },
	{ 2, "cappuccino_assassino", "Rainbow" },
	{ 4, "tralalero_tralala", "Normal" },
	{ 5, "ballerina_cappuccina", "Normal" },
	{ 7, "brr_brr_patapim", "Evil" },
}
for _, b in theirs do
	local def = SLOTS[b[1]]
	brainrot(b[2], b[3], neighbourOrigin * CFrame.new(def.x, FLOOR_TOP + 1.6, def.z))
end
person(neighbourOrigin * CFrame.new(-4, FLOOR_TOP, -20), 5)

-- a few pedestals filled in the other bases so the ring doesn't look empty from above
local ids = {
	"tralalero_tralala",
	"tung_tung_tung_sahur",
	"bombardiro_crocodilo",
	"ballerina_cappuccina",
	"brr_brr_patapim",
	"cappuccino_assassino",
}
for i = 3, BASES do
	local o = facingHub(BASE_RADIUS, (i - 1) * 360 / BASES + 15, 0)
	for k = 1, 3 + (i % 4) do
		local def = SLOTS[k]
		brainrot(ids[(i + k) % #ids + 1], "Normal", o * CFrame.new(def.x, FLOOR_TOP + 1.6, def.z))
	end
end

-- Overlay studio: the three owner-overlay states side by side, away from the map (design shot only) -------
local STUDIO = CFrame.new(0, 0, 900) -- looks toward -Z
box(
	world,
	"StudioFloor",
	Vector3.new(60, 1, 40),
	STUDIO * CFrame.new(0, FLOOR_TOP - 0.5, 0),
	"#5A5E66",
	{ studs = true }
)
box(world, "StudioWall", Vector3.new(60, 24, 2), STUDIO * CFrame.new(0, 12, 14), BUILDING, { studs = true })
local states = {
	{ x = 12, id = "tung_tung_tung_sahur", owner = { 0.8, "4d 6h", "ok" }, caption = "Normal" },
	{ x = 0, id = "tung_tung_tung_sahur", owner = { 0.35, "0d 7h", "low" }, caption = "Low (under 1 day)" },
	{
		x = -12,
		id = "tung_tung_tung_sahur",
		owner = { 0.1, "LEAVING TONIGHT!", "leaving" },
		caption = "Leaving tonight",
	},
}
for _, st in states do
	local c = STUDIO * CFrame.new(st.x, FLOOR_TOP, 0)
	cyl(world, "StudioPedestal", 5, 1.6, c * CFrame.new(0, 0.8, 0), "#D8D8DC")
	cyl(
		world,
		"StudioRim",
		5.4,
		0.3,
		c * CFrame.new(0, 0.2, 0),
		ACCENTS[1],
		{ material = Enum.Material.Neon, transparency = 0.2 }
	)
	local face = if st.owner[3] == "leaving" then CFrame.Angles(0, math.rad(-50), 0) else CFrame.identity
	brainrot(st.id, "Normal", c * CFrame.new(0, 1.6, 0) * face, { owner = st.owner })
	local cap = box(world, "Caption", Vector3.new(10, 1.6, 0.4), c * CFrame.new(0, 0.9, -3.6), "#1B1D24")
	surfaceText(cap, Enum.NormalId.Front, { { st.caption, "#FFFFFF" } })
end

-- Map labels for the top-down view (huge, only drawn from far away) ----------------------------------------
local mapLabels = {}
local function mapLabel(pos, text, color)
	table.insert(mapLabels, { pos = { pos.X, pos.Y, pos.Z }, text = text, color = color })
end
mapLabel(Vector3.new(0, 5, -54), "HUB + CONVEYOR", "#FFFFFF")
for i = 1, BASES do
	local p = polar(BASE_RADIUS + 4, (i - 1) * 360 / BASES + 15, 5)
	mapLabel(p, if i == 1 then "YOUR BASE" else `BASE {i}`, if i == 1 then "#FFD23F" else "#FFFFFF")
end
mapLabel(polar(62, -30, 5), "Egg Shop", "#3DE05C")
mapLabel(polar(62, 30, 5), "Food Shop", "#FF9A1F")
mapLabel(polar(66, 90, 5), "Leaderboards", "#FFD23F")
mapLabel(polar(64, 150, 5), "Event Stage", "#FF7AC8")
mapLabel(polar(62, 210, 5), "Trade Zone", "#7CE0FF")
mapLabel(polar(62, 270, 5), "Hangout", "#FFFFFF")
mapLabel(polar(LANE_RADIUS + 14, 30, 5), "escape lane", "#FF7A2E")

print(Runtime.dump({
	yourBase = Runtime.comps(yourOrigin),
	studio = Runtime.comps(STUDIO),
	neighbourBase = Runtime.comps(neighbourOrigin),
	mapLabels = mapLabels,
	stats = {
		walkStuds = walkStuds,
		walkSeconds = walkStuds / WALK_SPEED,
		mapDiameter = MAP_RADIUS * 2,
		gateRadius = GATE_RADIUS,
	},
}))
