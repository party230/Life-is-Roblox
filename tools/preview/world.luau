--!nocheck
-- Runs the real world builder (src/server/World/Builder.luau) headless in Lune, places brainrots on the shared
-- hub carpet and on your pedestals with the real Brainrot.create, and dumps every part, light and text label for
-- world.mjs (three.js) to render. Usage (repo root): lune run tools/preview/world.luau > build/world.json

local Runtime = require("./runtime")
local load, place = Runtime.load, Runtime.place
local Random, CFrame = Runtime.Random, Runtime.CFrame
local roblox = require("@lune/roblox")
local Vector3, Color3, Enum = roblox.Vector3, roblox.Color3, roblox.Enum

-- Build the world -----------------------------------------------------------------------------------------

local Config = load("src/shared/Config/init.luau")
local Builder = load("src/server/World/Builder.luau")
local Brainrot = load("src/shared/World/Brainrot.luau")
local ShopStock = load("src/shared/Logic/ShopStock.luau")

local plots = Builder.build()
local refs = plots[1]

local rng = Random.new(3)
local function roll()
	return rng:NextNumber()
end

local function lightning(model)
	Runtime.lightning(model, roll)
end

local function rarityOf(id)
	return Config.Species.byId[id].rarity
end

-- The shared hub carpet: brainrots spread along the path (same sampling as ShopService), with prices.
local hub = Builder.hub()
local path = hub.carpetPath
local cumulative = { 0 }
for i = 2, #path do
	cumulative[i] = cumulative[i - 1] + (path[i] - path[i - 1]).Magnitude
end
local function sample(d)
	for i = 2, #path do
		if d <= cumulative[i] or i == #path then
			local seg = cumulative[i] - cumulative[i - 1]
			local t = if seg > 0 then (d - cumulative[i - 1]) / seg else 0
			local p0, p1 = path[i - 1], path[i]
			local dir = (p1 - p0).Unit
			local right = dir:Cross(Vector3.yAxis).Unit
			return CFrame.fromMatrix(p0:Lerp(p1, t), right, Vector3.yAxis)
		end
	end
	return CFrame.new(path[1])
end
local carpet = {
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
local total = cumulative[#path]
for i, entry in carpet do
	local id, variant = entry[1], entry[2]
	local rarity = rarityOf(id)
	local price = ShopStock.priceFor(rarity, variant, roll)
	local model = Brainrot.create(id, rarity, variant, { price = price })
	local hover = model:GetAttribute("Hover") or 0
	place(model, sample(total * (i - 0.5) / #carpet) * CFrame.new(0, hover, 0))
	lightning(model)
	model.Parent = hub.carpetItems
end

-- Your base (plot 1): brainrots on pedestals with the owner-only rows (as the owner's client draws them),
-- the nursery open with babies, teens and eggs. Plot 2: nursery locked.
local OwnerStatus = load("src/shared/World/OwnerStatus.luau")
local Blocks = load("src/server/World/Blocks.luau")
local function nameplateOf(model)
	return model.PrimaryPart:FindFirstChild("Nameplate"):FindFirstChild("Nameplate")
end
local owned = {
	-- slot, character, variant, loyalty 0..1, timer fraction 0..1 (0 = leaving tonight)
	{ 1, "tralalero_tralala", "Rainbow", 0.92, 0.9 },
	{ 2, "ballerina_cappuccina", "Normal", 0.7, 0.62 },
	{ 3, "brr_brr_patapim", "Normal", 0.35, 0.2 },
	{ 4, "bombardiro_crocodilo", "Normal", 0.6, 0.45 },
	{ 5, "tung_tung_tung_sahur", "Evil", 0.12, 0 },
	{ 6, "cappuccino_assassino", "Normal", 0.8, 0.75 },
	{ 7, "ballerina_cappuccina", "Rainbow", 0.5, 0.33 },
	{ 8, "brr_brr_patapim", "Normal", 0.25, 0.07 },
}
for _, entry in owned do
	local slot, id, variant, loyalty, timer = entry[1], entry[2], entry[3], entry[4], entry[5]
	local model = Brainrot.create(id, rarityOf(id), variant)
	local top = Builder.pedestalTop(refs, slot)
	local hover = model:GetAttribute("Hover") or 0
	local facing = if timer <= 0 then CFrame.Angles(0, math.rad(150), 0) else CFrame.identity -- restless
	place(model, top * CFrame.new(0, hover, 0) * facing)
	lightning(model)
	local gui = nameplateOf(model)
	OwnerStatus.attach(gui)
	OwnerStatus.set(gui, loyalty, timer)
	model.Parent = refs.brainrots
	local rim = Builder.rim(refs, slot)
	if rim then
		rim.Color = Color3.fromHex(Config.Rarities.byId[rarityOf(id)].color)
	end
end
-- nursery pen: babies and a teen (public stage line + your rows)
local pen = {
	{ "tung_tung_tung_sahur", "Baby", 0.5, 0.55, 1 },
	{ "ballerina_cappuccina", "Teen", 0.75, 0.8, 0.7 },
	{ "cappuccino_assassino", "Baby", 0.5, 0.3, 0.16 },
}
for k, entry in pen do
	local id, stage, scale, loyalty, timer = entry[1], entry[2], entry[3], entry[4], entry[5]
	local model = Brainrot.create(id, rarityOf(id), "Normal", { stage = stage })
	Runtime.scale(model, scale)
	place(model, Builder.penSpot(refs, k + 1) * CFrame.Angles(0, math.rad(k * 25 - 30), 0))
	local gui = nameplateOf(model)
	OwnerStatus.attach(gui)
	OwnerStatus.set(gui, loyalty, timer)
	model.Parent = refs.brainrots
end
-- two eggs incubating
for i, color in { "#B98CFF", "#FFD23F" } do
	local top = refs.nursery.incubatorTops[i]
	local ball =
		Blocks.ball(refs.model, "Egg", 2.2, top * CFrame.new(0, 1.1, 0), color, { canCollide = false })
	Blocks.floating(ball, {
		{
			text = if i == 1 then "Hatching 2:14" else "Ready to hatch!",
			color = if i == 1 then "#FFFFFF" else "#7CFF9B",
		},
	}, 4.6, 1, 3, 60)
end
refs.signLabel.Text = "Your Base"
Builder.setNursery(refs, true, 3, "")
Builder.setNursery(plots[2], false, 3, "Unlock: $250K  or  R$ 99")
plots[2].signLabel.Text = "Brainrotter's Base"
for i = 3, Config.Game.PLOT_COUNT do
	Builder.setNursery(plots[i], i % 3 == 0, 3, "")
end

print(
	Runtime.dump({ plotOrigin = Runtime.comps(refs.origin), neighbourBase = Runtime.comps(plots[2].origin) })
)
