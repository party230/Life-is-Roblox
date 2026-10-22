--!nocheck
-- Runs the real world builder (src/server/World/Builder.luau) headless in Lune, places a few brainrots on the
-- carpet and pedestals with the real Brainrot.create, and dumps every part, light and text label as JSON for
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

-- Carpet: a stream of brainrots walking toward the gate (front), with prices.
local carpet = {
	{ "tralalero_tralala", "Normal" },
	{ "cappuccino_assassino", "Rainbow" },
	{ "brr_brr_patapim", "Normal" },
	{ "ballerina_cappuccina", "Evil" },
	{ "tung_tung_tung_sahur", "Normal" },
	{ "bombardiro_crocodilo", "Rainbow" },
}
local a, b = Builder.carpetStart(refs), Builder.carpetEnd(refs)
for i, entry in carpet do
	local id, variant = entry[1], entry[2]
	local rarity = rarityOf(id)
	local price = ShopStock.priceFor(rarity, variant, roll)
	local model = Brainrot.create(id, rarity, variant, { price = price })
	local t = (i - 0.6) / #carpet
	local pos = a.Position:Lerp(b.Position, t)
	local hover = model:GetAttribute("Hover") or 0
	place(model, CFrame.new(pos + Vector3.new(0, hover, 0)) * (a - a.Position))
	lightning(model)
	model.Parent = refs.carpetItems
end

-- Pedestals: a few already-owned brainrots.
local owned = {
	{ 1, "tung_tung_tung_sahur", "Evil" },
	{ 2, "ballerina_cappuccina", "Normal" },
	{ 3, "tralalero_tralala", "Rainbow" },
	{ 4, "brr_brr_patapim", "Normal" },
	{ 5, "bombardiro_crocodilo", "Normal" },
	{ 6, "cappuccino_assassino", "Normal" },
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
		rim.Material = Enum.Material.Neon
	end
end

-- Dump -------------------------------------------------------------------------------------------------------

print(Runtime.dump({ plotOrigin = Runtime.comps(refs.origin) }))
