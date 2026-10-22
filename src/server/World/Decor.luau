--!strict
-- Props for the space between the hub and the bases (D38: "big but never empty"): voxel trees, bushes, rocks,
-- flower beds, lamp posts, benches, blocky stand-in NPCs and six landmark types. Deterministic (seeded).

local Blocks = require(script.Parent.Blocks)

local Decor = {}

local box, cyl, neon = Blocks.box, Blocks.cyl, Blocks.neon

local random = Random.new(11)
local function rand(a: number, b: number): number
	return random:NextNumber(a, b)
end

function Decor.tree(parent: Instance, pos: Vector3, scale: number?)
	local s = scale or 1
	local h = rand(6, 10) * s
	box(
		parent,
		"Trunk",
		Vector3.new(2.6 * s, h, 2.6 * s),
		CFrame.new(pos + Vector3.new(0, h / 2, 0)),
		"#7A4A24",
		{
			studs = true,
		}
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
			parent,
			"Leaves",
			Vector3.new(sz, sz, sz),
			CFrame.new(pos + Vector3.new(o.X * s, o.Y, o.Z * s)),
			if random:NextNumber() > 0.5 then "#3FAF4A" else "#2E9440",
			{ studs = true }
		)
	end
end

function Decor.bush(parent: Instance, pos: Vector3)
	local s = rand(2.5, 4)
	box(
		parent,
		"Bush",
		Vector3.new(s * 1.4, s, s * 1.2),
		CFrame.new(pos + Vector3.new(0, s / 2, 0)) * CFrame.Angles(0, rand(0, 3), 0),
		"#34A23F",
		{ studs = true }
	)
end

local FLOWERS = { "#FF4F7B", "#FFD23F", "#FFFFFF", "#B98CFF", "#FF7A2E" }
function Decor.flowerBed(parent: Instance, pos: Vector3, yaw: number)
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	box(parent, "Bed", Vector3.new(10, 1, 4), cf * CFrame.new(0, 0.5, 0), "#7A4A24", { studs = true })
	box(parent, "Soil", Vector3.new(9, 0.4, 3), cf * CFrame.new(0, 1.1, 0), "#4E3420")
	for i = 0, 7 do
		box(
			parent,
			"Flower",
			Vector3.new(0.9, 0.9, 0.9),
			cf * CFrame.new(-3.9 + i * 1.12, 1.8, rand(-0.8, 0.8)),
			FLOWERS[i % #FLOWERS + 1]
		)
	end
end

function Decor.rock(parent: Instance, pos: Vector3)
	local s = rand(2, 5)
	box(
		parent,
		"Rock",
		Vector3.new(s * 1.3, s * 0.8, s),
		CFrame.new(pos + Vector3.new(0, s * 0.35, 0))
			* CFrame.Angles(rand(-0.2, 0.2), rand(0, 3), rand(-0.2, 0.2)),
		"#8A8D93",
		{ studs = true }
	)
end

function Decor.lamp(parent: Instance, pos: Vector3, withLight: boolean)
	box(parent, "LampPost", Vector3.new(0.8, 9, 0.8), CFrame.new(pos + Vector3.new(0, 4.5, 0)), "#2B2E35")
	local head = neon(
		parent,
		"LampHead",
		Vector3.new(1.8, 1.4, 1.8),
		CFrame.new(pos + Vector3.new(0, 9.4, 0)),
		"#FFE9A8"
	)
	if withLight then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 220, 150)
		light.Brightness = 1
		light.Range = 14
		light.Shadows = false
		light.Parent = head
	end
end

function Decor.bench(parent: Instance, cf: CFrame)
	box(parent, "Seat", Vector3.new(6, 0.5, 2), cf * CFrame.new(0, 1.6, 0), "#A9743F", {
		material = Enum.Material.WoodPlanks,
	})
	box(parent, "Back", Vector3.new(6, 1.6, 0.4), cf * CFrame.new(0, 2.6, 0.9), "#A9743F", {
		material = Enum.Material.WoodPlanks,
	})
	for _, x in { -2.5, 2.5 } do
		box(parent, "Leg", Vector3.new(0.4, 1.4, 1.8), cf * CFrame.new(x, 0.7, 0), "#2B2E35")
	end
end

-- Landmarks -------------------------------------------------------------------------------------------------

local function pond(parent: Instance, cf: CFrame)
	cyl(parent, "PondRim", 30, 0.8, cf * CFrame.new(0, 0.4, 0), "#8A8D93", { studs = true })
	cyl(parent, "Pond", 27, 0.9, cf * CFrame.new(0, 0.5, 0), "#3FA8F5", {
		material = Enum.Material.Glass,
		transparency = 0.15,
		canCollide = false,
	})
	box(parent, "Bridge", Vector3.new(5, 0.8, 32), cf * CFrame.new(0, 1.6, 0), "#A9743F", {
		material = Enum.Material.WoodPlanks,
	})
	for _, o in { Vector3.new(-7, 1.05, 5), Vector3.new(6, 1.05, -6), Vector3.new(-5, 1.05, -8) } do
		cyl(parent, "LilyPad", 2.4, 0.1, cf * CFrame.new(o), "#3FAF4A")
	end
end

local function pizzaStatue(parent: Instance, cf: CFrame)
	box(parent, "Plinth", Vector3.new(10, 3, 10), cf * CFrame.new(0, 1.5, 0), "#B4B4B8", { studs = true })
	Blocks.wedge(
		parent,
		"Slice",
		Vector3.new(1.4, 14, 6),
		cf * CFrame.new(-3, 10, 0) * CFrame.Angles(0, math.rad(90), math.rad(180)),
		"#FFC94A"
	)
	Blocks.wedge(
		parent,
		"Slice",
		Vector3.new(1.4, 14, 6),
		cf * CFrame.new(3, 10, 0) * CFrame.Angles(0, math.rad(-90), math.rad(180)),
		"#FFC94A"
	)
	box(parent, "Crust", Vector3.new(13, 2, 2), cf * CFrame.new(0, 17, 0), "#C8873A", { studs = true })
	for _, o in { Vector3.new(-2, 13, -1), Vector3.new(1.5, 11, -1), Vector3.new(-0.5, 8.5, -1) } do
		cyl(parent, "Pepperoni", 2, 0.3, cf * CFrame.new(o) * CFrame.Angles(math.rad(90), 0, 0), "#C0392B")
	end
end

local function windmill(parent: Instance, cf: CFrame)
	box(parent, "MillBase", Vector3.new(10, 16, 10), cf * CFrame.new(0, 8, 0), "#E8E2D4", { studs = true })
	box(parent, "MillRoof", Vector3.new(11, 3, 11), cf * CFrame.new(0, 17.5, 0), "#C0392B", { studs = true })
	box(parent, "Door", Vector3.new(3, 5, 0.4), cf * CFrame.new(0, 2.5, -5.1), "#7A4A24")
	for k = 0, 3 do
		box(
			parent,
			"Blade",
			Vector3.new(2, 11, 0.4),
			cf * CFrame.new(0, 13, -5.6) * CFrame.Angles(0, 0, math.rad(k * 90 + 20)) * CFrame.new(0, 6, 0),
			"#FFFFFF"
		)
	end
end

function Decor.cupFountain(parent: Instance, cf: CFrame)
	cyl(parent, "FountainPool", 20, 1.2, cf * CFrame.new(0, 0.6, 0), "#B4B4B8", { studs = true })
	cyl(parent, "FountainWater", 18, 1.3, cf * CFrame.new(0, 0.7, 0), "#5AC8FF", {
		material = Enum.Material.Glass,
		transparency = 0.2,
		canCollide = false,
	})
	cyl(parent, "Cup", 7, 7, cf * CFrame.new(0, 4.5, 0), "#FFFFFF", { studs = true })
	cyl(parent, "Foam", 6.4, 0.6, cf * CFrame.new(0, 8.1, 0), "#E8C9A0")
	box(parent, "Handle", Vector3.new(1, 4, 3), cf * CFrame.new(4.2, 4.5, 0), "#FFFFFF")
	cyl(parent, "Saucer", 11, 0.6, cf * CFrame.new(0, 1.5, 0), "#FFFFFF")
end

local function picnic(parent: Instance, cf: CFrame)
	for k = 0, 2 do
		local c = cf * CFrame.new(-10 + k * 10, 0, rand(-3, 3))
		box(parent, "Table", Vector3.new(6, 0.5, 3), c * CFrame.new(0, 2.6, 0), "#A9743F", {
			material = Enum.Material.WoodPlanks,
		})
		box(parent, "TableLeg", Vector3.new(0.6, 2.4, 0.6), c * CFrame.new(0, 1.2, 0), "#7A4A24")
		cyl(parent, "Pole", 0.3, 7, c * CFrame.new(0, 4.5, 0), "#FFFFFF")
		cyl(parent, "Umbrella", 7, 0.6, c * CFrame.new(0, 8, 0), if k % 2 == 0 then "#FF4F7B" else "#2F8CFF")
		box(
			parent,
			"Blanket",
			Vector3.new(5, 0.1, 5),
			c * CFrame.new(0, 0.35, 5),
			if k % 2 == 0 then "#FF3B3B" else "#FFFFFF"
		)
	end
end

local function playground(parent: Instance, cf: CFrame)
	box(parent, "SlideTower", Vector3.new(5, 7, 5), cf * CFrame.new(0, 3.5, 0), "#FFB21E", { studs = true })
	box(
		parent,
		"Slide",
		Vector3.new(3, 0.5, 10),
		cf * CFrame.new(0, 3.6, -7) * CFrame.Angles(math.rad(-35), 0, 0),
		"#FF4F7B"
	)
	box(parent, "SwingBar", Vector3.new(10, 0.6, 0.6), cf * CFrame.new(12, 7, 0), "#2F8CFF")
	for _, x in { 7.5, 16.5 } do
		box(parent, "SwingPost", Vector3.new(0.6, 7, 0.6), cf * CFrame.new(x, 3.5, 0), "#2F8CFF")
	end
	for _, x in { 10, 14 } do
		box(parent, "Swing", Vector3.new(1.6, 0.3, 1), cf * CFrame.new(x, 2, 0), "#2CC764")
	end
end

local LANDMARKS: { (Instance, CFrame) -> () } =
	{ pond, pizzaStatue, windmill, Decor.cupFountain, picnic, playground }

-- Fills the meadow sector centred on `midDeg` (between two spokes) with a landmark and scattered props.
-- `isClear(pos)` says whether a spot is off the paths.
function Decor.sector(
	parent: Instance,
	index: number,
	midDeg: number,
	innerRadius: number,
	outerRadius: number,
	isClear: (Vector3) -> boolean
)
	local landmarkR = (innerRadius + outerRadius) / 2 + rand(-12, 12)
	local landmark = LANDMARKS[(index - 1) % #LANDMARKS + 1]
	landmark(parent, Blocks.facingHub(landmarkR, midDeg, 0))
	local landmarkPos = Blocks.polar(landmarkR, midDeg)
	for _ = 1, 26 do
		local p = Blocks.polar(rand(innerRadius + 10, outerRadius - 10), midDeg + rand(-13, 13))
		if isClear(p) and (p - landmarkPos).Magnitude > 22 then
			local k = random:NextNumber()
			if k < 0.4 then
				Decor.tree(parent, p, rand(0.8, 1.2))
			elseif k < 0.65 then
				Decor.bush(parent, p)
			elseif k < 0.8 then
				Decor.rock(parent, p)
			else
				Decor.flowerBed(parent, p, rand(0, 3))
			end
		end
	end
end

-- Outer tree line behind the bases.
function Decor.treeLine(parent: Instance, radius: number)
	for k = 1, 90 do
		Decor.tree(parent, Blocks.polar(radius - rand(10, 30), k * 4 + rand(-1, 1)), rand(0.9, 1.3))
	end
end

return Decor
