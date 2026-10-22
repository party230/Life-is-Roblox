--!nocheck
-- Headless Roblox stand-in for the preview tools (world.luau, design/*.luau): runs game modules in Lune and
-- dumps the resulting Workspace (parts, lights, BillboardGui / SurfaceGui text) as JSON for world.mjs.
--
-- A tiny module runtime stands in for Roblox: src/shared is mirrored as ModuleScripts under
-- ReplicatedStorage.Shared so instance requires (require(ReplicatedStorage.Shared.X), require(script.Kit))
-- and string requires ("./Kit", "@self/Game") both resolve to the source files.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Instance, Vector3, CFrame, Color3, Enum =
	roblox.Instance, roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

-- Roblox globals the game code uses ------------------------------------------------------------------------

-- Lune's CFrame.lookAt disagrees with Roblox (DECISIONS D29); this is Roblox's definition.
local function lookAt(at, target, up)
	local look = (target - at).Unit
	local right = look:Cross(up or Vector3.yAxis).Unit
	return CFrame.fromMatrix(at, right, right:Cross(look))
end
local CFrameShim = setmetatable({ lookAt = lookAt }, { __index = CFrame })

-- Deterministic stand-in for Roblox's Random.
local Random = {}
function Random.new(seed)
	local state = (seed or 1) % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local function nextFloat()
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
	return {
		NextNumber = function(_, a, b)
			a, b = a or 0, b or 1
			return a + (b - a) * nextFloat()
		end,
		NextInteger = function(_, a, b)
			return math.floor(a + (b - a + 1) * nextFloat())
		end,
	}
end

local dataModel = Instance.new("DataModel")
local workspace = dataModel:GetService("Workspace")
local replicatedStorage = dataModel:GetService("ReplicatedStorage")
local collectionService = {
	AddTag = function(_, inst, tag)
		inst:AddTag(tag)
	end,
	HasTag = function(_, inst, tag)
		return inst:HasTag(tag)
	end,
}
local game = {
	GetService = function(_, name)
		if name == "CollectionService" then
			return collectionService
		end
		return dataModel:GetService(name)
	end,
}

local globals = {
	game = game,
	workspace = workspace,
	Random = Random,
	CFrame = CFrameShim,
}
for _, k in
	{
		"Instance",
		"Vector3",
		"Color3",
		"Enum",
		"Vector2",
		"UDim2",
		"UDim",
		"ColorSequence",
		"ColorSequenceKeypoint",
		"NumberSequence",
		"NumberSequenceKeypoint",
		"NumberRange",
		"Font",
	}
do
	globals[k] = roblox[k]
end

-- Module runtime ---------------------------------------------------------------------------------------------

local pathOf = {} -- ModuleScript full name -> source file (Lune instances aren't identity-stable table keys)
local instOf = {} -- source file -> ModuleScript
local cache = {}

local function dirname(path)
	return string.match(path, "^(.*)/[^/]*$") or "."
end

local function normalize(path)
	local out = {}
	for seg in string.gmatch(path, "[^/]+") do
		if seg == ".." and #out > 0 and out[#out] ~= ".." then
			table.remove(out)
		elseif seg ~= "." then
			table.insert(out, seg)
		end
	end
	return table.concat(out, "/")
end

local function resolveFile(base)
	if fs.isFile(base .. ".luau") then
		return base .. ".luau"
	elseif fs.isFile(base .. "/init.luau") then
		return base .. "/init.luau"
	end
	error(`world.luau: cannot resolve module {base}`)
end

local load

local function makeRequire(file)
	local isInit = string.match(file, "/init%.luau$") ~= nil
	local folder = dirname(file)
	return function(target)
		if type(target) == "string" then
			local base
			if string.sub(target, 1, 6) == "@self/" then
				base = folder .. "/" .. string.sub(target, 7)
			else
				-- "./" is relative to the module's parent: the folder for a file, the folder's parent for an init
				base = (if isInit then dirname(folder) else folder) .. "/" .. target
			end
			return load(resolveFile(normalize(base)))
		end
		local path = pathOf[target:GetFullName()]
		assert(path, `world.luau: no source for {target:GetFullName()}`)
		return load(path)
	end
end

function load(file)
	if cache[file] ~= nil then
		return cache[file]
	end
	local env = setmetatable({
		script = instOf[file],
		require = makeRequire(file),
	}, {
		__index = function(_, k)
			local g = globals[k]
			if g ~= nil then
				return g
			end
			return getfenv(0)[k]
		end,
	})
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = env, injectGlobals = false })
	local result = chunk()
	cache[file] = result
	return result
end

-- Mirrors a source directory as ModuleScripts (an init.luau folder becomes a ModuleScript with children).
local function mirror(dir, name, parent)
	local initFile = dir .. "/init.luau"
	local node
	if fs.isFile(initFile) then
		node = Instance.new("ModuleScript")
		instOf[initFile] = node
	else
		node = Instance.new("Folder")
	end
	node.Name = name
	node.Parent = parent
	if fs.isFile(initFile) then
		pathOf[node:GetFullName()] = initFile
	end
	for _, entry in fs.readDir(dir) do
		local full = dir .. "/" .. entry
		if fs.isDir(full) then
			mirror(full, entry, node)
		elseif string.match(entry, "%.luau$") and entry ~= "init.luau" then
			local m = Instance.new("ModuleScript")
			m.Name = string.gsub(entry, "%.luau$", "")
			m.Parent = node
			pathOf[m:GetFullName()] = full
			instOf[full] = m
		end
	end
	return node
end

mirror("src/shared", "Shared", replicatedStorage)
local serverScripts = dataModel:GetService("ServerScriptService")
mirror("src/server", "Server", serverScripts)

-- Helpers --------------------------------------------------------------------------------------------------

local Runtime = {}
Runtime.load = load
Runtime.workspace = workspace
Runtime.Random = Random
Runtime.CFrame = CFrameShim
Runtime.globals = globals

-- Model:PivotTo, which uses the PrimaryPart's pivot (Root.CFrame * Root.PivotOffset) as Roblox does.
function Runtime.place(model, cf)
	local root = model.PrimaryPart
	local pivot = root.CFrame * root.PivotOffset
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = cf * pivot:Inverse() * d.CFrame
		end
	end
end

-- Lune keeps Attachment.Position and Attachment.CFrame as separate properties (Roblox derives one from
-- the other); the game code sets Position, so read that.
local function attachmentOffset(a)
	local ok, pos = pcall(function()
		return a.Position
	end)
	return if ok and pos then pos else a.CFrame.Position
end

-- Scales a model about its pivot (Model:ScaleTo stand-in for previews).
function Runtime.scale(model, factor)
	local root = model.PrimaryPart
	local pivot = root.CFrame * root.PivotOffset
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local rel = pivot:Inverse() * d.CFrame
			d.Size *= factor
			d.CFrame = pivot * (CFrame.new(rel.Position * factor) * (rel - rel.Position))
		elseif d:IsA("Attachment") then
			d.Position = attachmentOffset(d) * factor
		end
	end
	root.PivotOffset = CFrame.new(root.PivotOffset.Position * factor)
end

-- One frozen strike of the Evil lightning (in game the client re-strikes it every few frames).
function Runtime.lightning(model, rng)
	if model:GetAttribute("Variant") ~= "Evil" then
		return
	end
	local Config = load("src/shared/Config/init.luau")
	local EvilBolts = load("src/shared/World/EvilBolts.luau")
	local root = model.PrimaryPart
	for _, seg in EvilBolts.strike(rng, root.Size, Config.Variants.EVIL_BOLTS) do
		local p = Instance.new("Part")
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromHex(Config.Variants.EVIL_BOLT_COLOR)
		p.Size = Vector3.new(0.09, 0.09, seg.length + 0.09)
		p.CFrame = root.CFrame * seg.cframe
		p.Parent = model
	end
end

local function comps(cf)
	return { cf:GetComponents() }
end

local function rgb(c)
	return { c.R, c.G, c.B }
end

local function worldPos(inst)
	if inst:IsA("Attachment") then
		return inst.Parent.CFrame:PointToWorldSpace(attachmentOffset(inst))
	elseif inst:IsA("BasePart") then
		return inst.CFrame.Position
	end
	return nil
end

-- Rows of a BillboardGui / SurfaceGui in LayoutOrder: TextLabels (optionally on a pill background) and bars
-- (a Frame with a "Bar" attribute = fill 0..1, its Fill child's colour, optional "Icon" attribute text).
local function labels(gui)
	local out = {}
	for _, l in gui:GetChildren() do
		if l:IsA("TextLabel") then
			local stroke = l:FindFirstChildOfClass("UIStroke")
			table.insert(out, {
				kind = "text",
				order = l.LayoutOrder,
				text = l.Text,
				color = rgb(l.TextColor3),
				height = l.Size.Y.Scale,
				stroke = stroke and stroke.Thickness or 0,
				strokeColor = stroke and rgb(stroke.Color) or { 0, 0, 0 },
				gradient = l:FindFirstChildOfClass("UIGradient") ~= nil,
				background = if l.BackgroundTransparency < 1 then rgb(l.BackgroundColor3) else nil,
				owner = l:GetAttribute("OwnerOnly") == true,
				backgroundAlpha = 1 - l.BackgroundTransparency,
				width = l.Size.X.Scale,
			})
		elseif l:IsA("Frame") and l:GetAttribute("Bar") ~= nil then
			local fill = l:FindFirstChild("Fill")
			table.insert(out, {
				kind = "bar",
				order = l.LayoutOrder,
				value = l:GetAttribute("Bar"),
				color = fill and rgb(fill.BackgroundColor3) or { 1, 1, 1 },
				back = rgb(l.BackgroundColor3),
				height = l.Size.Y.Scale,
				width = l.Size.X.Scale,
				icon = l:GetAttribute("Icon"),
				owner = l:GetAttribute("OwnerOnly") == true,
				iconColor = l:GetAttribute("IconColor") and rgb(l:GetAttribute("IconColor")) or { 1, 1, 1 },
			})
		end
	end
	table.sort(out, function(x, y)
		return x.order < y.order
	end)
	return out
end

-- Every visible part, light and text label under the Workspace, as the JSON world.mjs renders.
-- `extra` is merged in (e.g. plotOrigin for plot-relative camera shots).
function Runtime.dump(extra)
	local parts, billboards, surfaces, lights = {}, {}, {}, {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Transparency < 0.99 then
				local shape = "Block"
				if d.ClassName == "WedgePart" then
					shape = "Wedge"
				elseif d.ClassName == "CornerWedgePart" then
					shape = "CornerWedge"
				elseif d.ClassName == "Part" and d.Shape == Enum.PartType.Ball then
					shape = "Ball"
				elseif d.ClassName == "Part" and d.Shape == Enum.PartType.Cylinder then
					shape = "Cylinder"
				end
				if d:FindFirstChildOfClass("SpecialMesh") then
					shape = "Ellipsoid"
				end
				table.insert(parts, {
					shape = shape,
					size = { d.Size.X, d.Size.Y, d.Size.Z },
					cf = comps(d.CFrame),
					color = rgb(d.Color),
					transparency = d.Transparency,
					material = d.Material.Name,
					reflectance = d.Reflectance,
					studs = d.TopSurface == Enum.SurfaceType.Studs,
				})
			end
		elseif d:IsA("BillboardGui") then
			local adornee = d.Adornee or d.Parent
			local pos = worldPos(adornee)
			if pos then
				pos += d.StudsOffsetWorldSpace + d.StudsOffset
				table.insert(billboards, {
					pos = { pos.X, pos.Y, pos.Z },
					size = { d.Size.X.Scale, d.Size.Y.Scale },
					sizeOffset = { d.SizeOffset.X, d.SizeOffset.Y },
					maxDistance = d.MaxDistance,
					name = d.Name,
					lines = labels(d),
				})
			end
		elseif d:IsA("SurfaceGui") then
			local part = d.Adornee or d.Parent
			if part:IsA("BasePart") then
				table.insert(surfaces, {
					cf = comps(part.CFrame),
					size = { part.Size.X, part.Size.Y, part.Size.Z },
					face = d.Face.Name,
					lines = labels(d),
				})
			end
		elseif d:IsA("PointLight") or d:IsA("SpotLight") then
			local pos = worldPos(d.Parent)
			if pos then
				table.insert(lights, {
					pos = { pos.X, pos.Y, pos.Z },
					color = rgb(d.Color),
					brightness = d.Brightness,
					range = d.Range,
				})
			end
		end
	end

	local out = { parts = parts, billboards = billboards, surfaces = surfaces, lights = lights }
	for k, v in extra or {} do
		out[k] = v
	end
	return serde.encode("json", out)
end

Runtime.comps = comps

return Runtime
