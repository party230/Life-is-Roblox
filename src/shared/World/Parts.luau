--!strict
-- Tiny helpers for building chunky low-poly placeholder geometry from code.

local Parts = {}

export type PartProps = {
	name: string?,
	size: Vector3,
	cframe: CFrame,
	color: string | Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	transparency: number?,
	canCollide: boolean?,
	studs: boolean?, -- classic studded top surface (Plastic)
	parent: Instance?,
}

function Parts.color(c: string | Color3): Color3
	return if typeof(c) == "Color3" then c else Color3.fromHex(c :: string)
end

function Parts.part(props: PartProps): Part
	local p = Instance.new("Part")
	p.Name = props.name or "Part"
	p.Anchored = true
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = Parts.color(props.color)
	p.Material = props.material
		or (if props.studs then Enum.Material.Plastic else Enum.Material.SmoothPlastic)
	p.TopSurface = if props.studs then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	p.BottomSurface = if props.studs then Enum.SurfaceType.Inlet else Enum.SurfaceType.Smooth
	p.Transparency = props.transparency or 0
	p.CanCollide = if props.canCollide == nil then true else props.canCollide
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent
	return p
end

function Parts.folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Billboard with one or more stacked text lines. Returns the gui and its labels in order.
function Parts.billboard(
	adornee: BasePart,
	offsetY: number,
	lines: { string },
	size: Vector2?
): (BillboardGui, { TextLabel })
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = adornee
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	local s = size or Vector2.new(6, 1.4 * #lines)
	gui.Size = UDim2.fromScale(s.X, s.Y)
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	local labels: { TextLabel } = {}
	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.Name = `Line{i}`
		label.LayoutOrder = i
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1 / #lines)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = line
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromHex("#1B1530")
		stroke.Parent = label
		label.Parent = gui
		table.insert(labels, label)
	end
	gui.Parent = adornee
	return gui, labels
end

return Parts
