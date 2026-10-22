--!strict
-- Small building blocks for the map builders (Builder, Hub, Decor): boxes, upright cylinders, balls, neon,
-- world text. Classic Roblox style: studded Plastic tops on structural parts, flat colour everywhere else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.World.Parts)

local Blocks = {}

export type Opts = {
	material: Enum.Material?,
	shape: Enum.PartType?,
	transparency: number?,
	studs: boolean?,
	canCollide: boolean?,
}

-- Palette (style reference: assets/reference/style.png)
Blocks.FLOOR_BLUE = "#2C7BE5"
Blocks.PATH_GREY = "#A3A2A5"
Blocks.PLAZA_GREY = "#C7C7CB"
Blocks.MEADOW = "#4CB848"
Blocks.CARPET_RED = "#E0262C"
Blocks.BUILDING = "#3B3F47"
Blocks.BUILDING_DARK = "#2B2E35"
Blocks.WINDOW = "#111318"
Blocks.INK = "#000000"

local UP = CFrame.Angles(0, 0, math.rad(90)) -- stands a Roblox cylinder (axis X) upright
Blocks.UP = UP

function Blocks.box(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: string,
	opts: Opts?
): Part
	local o: Opts = opts or {}
	return Parts.part({
		name = name,
		size = size,
		cframe = cf,
		color = color,
		material = o.material,
		shape = o.shape,
		transparency = o.transparency,
		studs = o.studs,
		canCollide = o.canCollide,
		parent = parent,
	})
end

-- Upright cylinder centred on `cf`.
function Blocks.cyl(
	parent: Instance,
	name: string,
	diameter: number,
	height: number,
	cf: CFrame,
	color: string,
	opts: Opts?
): Part
	local o: Opts = table.clone(opts or {})
	o.shape = Enum.PartType.Cylinder
	return Blocks.box(parent, name, Vector3.new(height, diameter, diameter), cf * UP, color, o)
end

function Blocks.ball(
	parent: Instance,
	name: string,
	diameter: number,
	cf: CFrame,
	color: string,
	opts: Opts?
): Part
	local o: Opts = table.clone(opts or {})
	o.shape = Enum.PartType.Ball
	return Blocks.box(parent, name, Vector3.new(diameter, diameter, diameter), cf, color, o)
end

function Blocks.neon(parent: Instance, name: string, size: Vector3, cf: CFrame, color: string): Part
	return Blocks.box(parent, name, size, cf, color, { material = Enum.Material.Neon, canCollide = false })
end

function Blocks.wedge(parent: Instance, name: string, size: Vector3, cf: CFrame, color: string): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = Color3.fromHex(color)
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

-- Point on the ground ring: angle in degrees (0 = +X, counter-clockwise seen from above toward +Z).
function Blocks.polar(radius: number, deg: number, y: number?): Vector3
	local a = math.rad(deg)
	return Vector3.new(math.cos(a) * radius, y or 0, math.sin(a) * radius)
end

-- CFrame at a polar point, facing the hub centre (LookVector toward the origin).
function Blocks.facingHub(radius: number, deg: number, y: number?): CFrame
	local p = Blocks.polar(radius, deg, y)
	local look = (Vector3.new(0, p.Y, 0) - p).Unit
	local right = look:Cross(Vector3.yAxis).Unit
	return CFrame.fromMatrix(p, right, right:Cross(look))
end

-- Text -------------------------------------------------------------------------------------------------------

export type Line = { text: string, color: string, weight: number? }

local function addLines(gui: Instance, lines: { Line }, stroke: number): { TextLabel }
	local total = 0
	for _, l in lines do
		total += l.weight or 1
	end
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui
	local out: { TextLabel } = {}
	for i, l in lines do
		local label = Instance.new("TextLabel")
		label.Name = `Line{i}`
		label.LayoutOrder = i
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, (l.weight or 1) / total)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = l.text
		label.TextColor3 = Color3.fromHex(l.color)
		local s = Instance.new("UIStroke")
		s.Thickness = stroke
		s.Color = Color3.new(0, 0, 0)
		s.LineJoinMode = Enum.LineJoinMode.Round
		s.Parent = label
		label.Parent = gui
		table.insert(out, label)
	end
	return out
end

-- World-scaled floating label (size in studs) over `adornee`, e.g. "Egg Shop" over a stall.
function Blocks.floating(
	adornee: BasePart,
	lines: { Line },
	width: number,
	lineHeight: number,
	offsetY: number,
	maxDistance: number?
): (BillboardGui, { TextLabel })
	local total = 0
	for _, l in lines do
		total += l.weight or 1
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "FloatingLabel"
	gui.Adornee = adornee
	gui.Size = UDim2.fromScale(width, total * lineHeight)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance or 400
	local labels = addLines(gui, lines, 5)
	gui.Parent = adornee
	return gui, labels
end

-- Text painted on one face of a part (signs, boards).
function Blocks.surface(
	part: BasePart,
	face: Enum.NormalId,
	lines: { Line },
	pixelsPerStud: number?
): { TextLabel }
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 40
	gui.LightInfluence = 0
	local labels = addLines(gui, lines, 3)
	gui.Parent = part
	return labels
end

-- ProximityPrompt that opens a client screen (UI reads the "Opens" attribute).
function Blocks.prompt(
	parent: Instance,
	action: string,
	object: string,
	opens: string?,
	distance: number?
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = distance or 12
	prompt.RequiresLineOfSight = false
	if opens then
		prompt:SetAttribute("Opens", opens)
	end
	prompt.Parent = parent
	return prompt
end

return Blocks
