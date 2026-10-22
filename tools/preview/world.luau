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

-- Your base (plot 1): brainrots on pedestals, nursery unlocked. Plot 2: nursery locked.
local owned = {
	{ 1, "tralalero_tralala", "Rainbow" },
	{ 2, "ballerina_cappuccina", "Normal" },
	{ 3, "brr_brr_patapim", "Normal" },
	{ 4, "bombardiro_crocodilo", "Normal" },
	{ 5, "tung_tung_tung_sahur", "Evil" },
	{ 6, "cappuccino_assassino", "Normal" },
	{ 7, "ballerina_cappuccina", "Rainbow" },
	{ 8, "brr_brr_patapim", "Normal" },
}
for _, entry in owned do
	local slot, id, variant = entry[1], entry[2], entry[3]
	local model = Brainrot.create(id, rarityOf(id), variant)
	local top = Builder.pedestalTop(refs, slot)
	local hover = model:GetAttribute("Hover") or 0
	place(model, top * CFrame.new(0, hover, 0))
	lightning(model)
	model.Parent = refs.brainrots
	local rim = Builder.rim(refs, slot)
	if rim then
		rim.Color = Color3.fromHex(Config.Rarities.byId[rarityOf(id)].color)
	end
end
refs.signLabel.Text = "Your Base"
Builder.setNursery(refs, true, 3, "")
Builder.setNursery(plots[2], false, 3, "Unlock: $250K  or  R$ 99")
for i = 3, Config.Game.PLOT_COUNT do
	Builder.setNursery(plots[i], i % 3 == 0, 3, "")
end

print(
	Runtime.dump({ plotOrigin = Runtime.comps(refs.origin), neighbourBase = Runtime.comps(plots[2].origin) })
)
