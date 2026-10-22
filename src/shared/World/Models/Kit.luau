--!strict
-- Builder kit for part-based, rigged brainrot models (blocky low-poly, Roblox style).
--
-- Rig layout (every character follows it, so animation, variants and nameplates work on any model):
--   Model (attributes SpeciesId, Variant)
--   ├─ Root   anchored, invisible, non-colliding hitbox. PrimaryPart. Attachments: Nameplate, Vfx, TrailA, TrailB
--   │   └─ Anim (Motor6D Root -> Body)   the client drives .Transform for bob / sway / waddle
--   ├─ Body   main visual part (unanchored, welded to nothing but the Motor6D)
--   └─ ...    every other visual part, WeldConstraint'ed to Body; Spinners use their own Motor6D
--
-- Coordinates: feet at y = 0, model faces -Z (Roblox LookVector). Part attribute "Role" marks
-- eye / pupil / detail parts so variants can treat them specially.

local Kit = {}
Kit.__index = Kit

export type Role = "skin" | "eye" | "pupil" | "detail" | "glow"

export type PartOpts = {
	shape: ("block" | "ball" | "ellipsoid" | "cylinder" | "wedge" | "cornerwedge")?,
	material: Enum.Material?,
	role: Role?,
	transparency: number?,
}

export type Kit = typeof(setmetatable(
	{} :: {
		model: Model,
		root: Part,
		body: BasePart?,
		height: number,
	},
	Kit
))

local DEG = math.rad

function Kit.new(name: string, height: number, width: number?): Kit
	local model = Instance.new("Model")
	model.Name = name
	local w = width or 3
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true -- ProximityPrompts / pickups target the root
	root.CanTouch = false
	root.Transparency = 1
	root.Size = Vector3.new(w, height, w)
	root.CFrame = CFrame.new(0, height / 2, 0)
	root.Parent = model
	model.PrimaryPart = root

	local function attach(attName: string, y: number)
		local a = Instance.new("Attachment")
		a.Name = attName
		a.Position = Vector3.new(0, y - height / 2, 0)
		a.Parent = root
	end
	attach("Nameplate", height + 0.6)
	attach("Vfx", height * 0.55)
	attach("TrailA", height * 0.7)
	attach("TrailB", height * 0.25)

	return setmetatable({ model = model, root = root, body = nil :: BasePart?, height = height }, Kit)
end

local function makePart(shape: string?): BasePart
	if shape == "wedge" then
		return Instance.new("WedgePart")
	elseif shape == "cornerwedge" then
		return Instance.new("CornerWedgePart")
	end
	local p = Instance.new("Part")
	if shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cylinder" then
		p.Shape = Enum.PartType.Cylinder
	end
	return p
end

-- Adds a visual part at `cf` (model space). The first part added becomes Body unless `asBody` is false.
function Kit.part(
	self: Kit,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: string,
	opts: PartOpts?
): BasePart
	local o: PartOpts = opts or {}
	local p = makePart(o.shape)
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = Color3.fromHex(color)
	p.Material = o.material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Transparency = o.transparency or 0
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.Anchored = false
	p:SetAttribute("Role", o.role or "skin")
	p:SetAttribute("BaseColor", p.Color)
	if o.shape == "ellipsoid" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Parent = self.model
	if not self.body then
		self.body = p
		p.Name = "Body"
		local motor = Instance.new("Motor6D")
		motor.Name = "Anim"
		motor.Part0 = self.root
		motor.Part1 = p
		motor.C0 = self.root.CFrame:Inverse() * cf
		motor.C1 = CFrame.identity
		motor.Parent = self.root
	else
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = self.body
		weld.Part1 = p
		weld.Parent = p
	end
	return p
end

-- Shorthands ------------------------------------------------------------------------------------------------

function Kit.box(
	self: Kit,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: string,
	opts: PartOpts?,
	rot: Vector3?
): BasePart
	local r = rot or Vector3.zero
	return self:part(name, size, CFrame.new(pos) * CFrame.Angles(DEG(r.X), DEG(r.Y), DEG(r.Z)), color, opts)
end

function Kit.blob(
	self: Kit,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: string,
	rot: Vector3?,
	opts: PartOpts?
): BasePart
	local o: PartOpts = table.clone(opts or {})
	o.shape = "ellipsoid"
	return self:box(name, size, pos, color, o, rot)
end

-- Vertical cylinder (Roblox cylinders lie along X; this stands it up). `rot` tilts it after standing.
function Kit.post(
	self: Kit,
	name: string,
	length: number,
	diameter: number,
	pos: Vector3,
	color: string,
	rot: Vector3?,
	opts: PartOpts?
): BasePart
	local o: PartOpts = table.clone(opts or {})
	o.shape = "cylinder"
	local r = rot or Vector3.zero
	local cf = CFrame.new(pos) * CFrame.Angles(DEG(r.X), DEG(r.Y), DEG(r.Z)) * CFrame.Angles(0, 0, DEG(90))
	return self:part(name, Vector3.new(length, diameter, diameter), cf, color, o)
end

-- Cylinder spanning two points (arms, legs, branches, bats). Rounded joints come from blobs at the ends.
function Kit.limb(
	self: Kit,
	name: string,
	from: Vector3,
	to: Vector3,
	diameter: number,
	color: string,
	opts: PartOpts?
): BasePart
	local o: PartOpts = table.clone(opts or {})
	o.shape = "cylinder"
	local mid = (from + to) / 2
	local length = (to - from).Magnitude
	-- explicit basis (cylinder axis = X along the limb); avoids lookAt edge cases and matches Lune previews
	local x = (to - from).Unit
	local ref = if math.abs(x.Y) < 0.95 then Vector3.yAxis else Vector3.xAxis
	local y = (ref - x * ref:Dot(x)).Unit
	local cf = CFrame.fromMatrix(mid, x, y, x:Cross(y))
	return self:part(name, Vector3.new(length, diameter, diameter), cf, color, o)
end

-- Cylinder lying along Z (front-back), e.g. engines.
function Kit.rod(
	self: Kit,
	name: string,
	length: number,
	diameter: number,
	pos: Vector3,
	color: string,
	opts: PartOpts?
): BasePart
	local o: PartOpts = table.clone(opts or {})
	o.shape = "cylinder"
	return self:part(
		name,
		Vector3.new(length, diameter, diameter),
		CFrame.new(pos) * CFrame.Angles(0, DEG(90), 0),
		color,
		o
	)
end

function Kit.wedge(
	self: Kit,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: string,
	rot: Vector3?,
	opts: PartOpts?
): BasePart
	local o: PartOpts = table.clone(opts or {})
	o.shape = "wedge"
	return self:box(name, size, pos, color, o, rot)
end

-- Pair of cartoon eyes on the front (-Z) at height y: white ball + black pupil + highlight.
function Kit.eyes(self: Kit, y: number, spacing: number, z: number, size: number, white: string?)
	for _, side in { -1, 1 } do
		self:part(
			`Eye{side}`,
			Vector3.new(size, size * 1.1, size * 0.6),
			CFrame.new(side * spacing, y, z),
			white or "#FFFFFF",
			{
				shape = "ellipsoid",
				role = "eye",
			}
		)
		self:part(
			`Pupil{side}`,
			Vector3.new(size * 0.5, size * 0.55, size * 0.3),
			CFrame.new(side * spacing, y - size * 0.05, z - size * 0.25),
			"#141018",
			{
				shape = "ellipsoid",
				role = "pupil",
			}
		)
		self:part(
			`Shine{side}`,
			Vector3.new(size * 0.16, size * 0.16, size * 0.1),
			CFrame.new(side * spacing + size * 0.12, y + size * 0.12, z - size * 0.36),
			"#FFFFFF",
			{
				shape = "ellipsoid",
				role = "detail",
			}
		)
	end
end

-- A part that spins about its own local X axis (propellers). The client drives it (attribute Spin = rps).
function Kit.spinner(self: Kit, hub: BasePart, rps: number)
	local weld = hub:FindFirstChildOfClass("WeldConstraint")
	if weld then
		weld:Destroy()
	end
	local motor = Instance.new("Motor6D")
	motor.Name = "Spinner"
	motor.Part0 = self.body
	motor.Part1 = hub
	motor.C0 = (self.body :: BasePart).CFrame:Inverse() * hub.CFrame
	motor.Parent = hub
	motor:SetAttribute("Spin", rps)
end

-- Welds `child` to `parentPart` instead of Body (so it follows a spinner).
function Kit.weldTo(_self: Kit, child: BasePart, parentPart: BasePart)
	local weld = child:FindFirstChildOfClass("WeldConstraint")
	if weld then
		weld.Part0 = parentPart
	end
end

function Kit.finish(self: Kit, opts: { hover: number?, idle: string? }?): Model
	local o: { hover: number?, idle: string? } = opts or {}
	self.model:SetAttribute("Hover", o.hover or 0) -- flying characters bob higher
	self.model:SetAttribute("Idle", o.idle or "bob")
	self.model.WorldPivot = CFrame.identity
	return self.model
end

return Kit
