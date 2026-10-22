--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Catalog = require("../src/shared/Logic/Catalog")
local Config = require("../src/shared/Config")
local Income = require("../src/shared/Logic/Income")
local Roll = require("../src/shared/Logic/Roll")
local ShopStock = require("../src/shared/Logic/ShopStock")
local Slots = require("../src/shared/Logic/Slots")
local Template = require("../src/shared/Data/Template")

local function lcg(seed: number): () -> number
	local state = seed
	return function()
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
end

local function fixed(v: number): () -> number
	return function()
		return v
	end
end

describe("Income", function()
	it("multiplies base x character x rarity x variant", function()
		-- brr_brr_patapim: Rare (x6), factor 1.0
		expect(Income.perSec("brr_brr_patapim", "Normal")).to.be.near(6)
		expect(Income.perSec("brr_brr_patapim", "Evil")).to.be.near(36)
		expect(Income.perSec("tralalero_tralala", "Rainbow")).to.be.near(120 * 4)
	end)

	it("pays a removed character at its stored rarity (placeholder)", function()
		expect(Income.perSec("brr_brr_patapim", "Normal", "Rare")).to.be.near(6)
	end)

	it("only counts brainrots on pedestals", function()
		local data = Template.create()
		data.brainrots.a = Roll.newBrainrot("a", "brr_brr_patapim", "Normal", 1, 0)
		data.brainrots.b = Roll.newBrainrot("b", "tralalero_tralala", "Normal", 1, 0)
		data.pedestals["1"] = "a"
		expect(Income.basePerSec(data)).to.be.near(6)
	end)

	it("pays offline income at the reduced rate, capped", function()
		local perSec = 10
		local hour = 3600
		expect(Income.offline(perSec, hour, false)).to.equal(math.floor(10 * Config.Game.OFFLINE_RATE * hour))
		local cap = Config.Game.OFFLINE_CAP_HOURS * hour
		expect(Income.offline(perSec, cap * 10, false)).to.equal(
			math.floor(10 * Config.Game.OFFLINE_RATE * cap)
		)
		expect(Income.offline(perSec, cap * 10, true)).to.equal(
			math.floor(10 * Config.Game.OFFLINE_RATE * cap * 2)
		)
		expect(Income.offline(perSec, -5, false)).to.equal(0)
	end)

	it("refreshes cached income after balance changes", function()
		local data = Template.create()
		local a = Roll.newBrainrot("a", "brr_brr_patapim", "Normal", 1, 0)
		a.incomePerSec = 999
		data.brainrots.a = a
		expect(Income.refresh(data)).to.equal(true)
		expect(a.incomePerSec).to.be.near(6)
		expect(Income.refresh(data)).to.equal(false)
	end)
end)

describe("Roll", function()
	it("only rolls spawnable characters of the rolled rarity", function()
		local rng = lcg(7)
		for _ = 1, 200 do
			local rarity = Roll.rarity(Config.Shop.RARITY_WEIGHTS, rng) :: string
			local species = Roll.species(rarity, rng) :: string
			expect(Config.Species.byId[species].rarity).to.equal(rarity)
			expect(Catalog.isSpawnable(Config.Species.byId[species])).to.equal(true)
		end
	end)

	it("never rolls a zero-weight rarity, even with luck", function()
		local rng = lcg(3)
		for _ = 1, 500 do
			expect(Roll.rarity(Config.Shop.RARITY_WEIGHTS, rng, 50)).never.to.equal("Secret")
		end
	end)

	it("rolls Normal most of the time and only known variants", function()
		expect(Roll.variant(fixed(0.5))).to.equal("Normal")
		local rng = lcg(5)
		for _ = 1, 300 do
			expect(Config.Variants.byId[Roll.variant(rng)]).to.be.ok()
		end
	end)

	it("builds a fresh brainrot record", function()
		local b = Roll.newBrainrot("id1", "ballerina_cappuccina", "Rainbow", 42, 1000)
		expect(b.rarity).to.equal("Epic")
		expect(b.variant).to.equal("Rainbow")
		expect(b.ownerUserId).to.equal(42)
		expect(b.isStolen).to.equal(false)
		expect(b.incomePerSec).to.be.near(15 * 4)
	end)
end)

describe("ShopStock", function()
	it("rounds prices to friendly numbers", function()
		expect(ShopStock.nicePrice(1043)).to.equal(1050)
		expect(ShopStock.nicePrice(26180)).to.equal(26000)
		expect(ShopStock.nicePrice(52)).to.equal(50)
		expect(ShopStock.nicePrice(3)).to.equal(5)
	end)

	it("carpet listings are spawnable, priced by rarity x variant", function()
		local rng = lcg(9)
		for i = 1, 100 do
			local l = ShopStock.carpetListing(rng, `c{i}`) :: any
			expect(l).to.be.ok()
			expect(Catalog.isSpawnable(Config.Species.byId[l.speciesId])).to.equal(true)
			local base = Config.Rarities.byId[l.rarity].shopPrice * Config.Variants.byId[l.variant].priceMult
			expect(l.price >= base * (1 - Config.Shop.PRICE_JITTER) * 0.9).to.equal(true)
			expect(l.price <= base * (1 + Config.Shop.PRICE_JITTER) * 1.1).to.equal(true)
		end
	end)

	it("plaza drops are always Rare or better", function()
		local rng = lcg(21)
		for i = 1, 200 do
			local drop = ShopStock.plazaDrop(rng, `d{i}`)
			expect(drop).to.be.ok()
			expect(Config.Rarities.byId[(drop :: any).rarity].order >= 3).to.equal(true)
		end
	end)
end)

describe("Slots", function()
	it("unlocks 8 slots at start and +2 per Extra Slots tier", function()
		expect(Slots.unlockedCount(0)).to.equal(8)
		expect(Slots.unlockedCount(1)).to.equal(10)
		expect(Slots.unlockedCount(3)).to.equal(14)
		expect(Slots.count()).to.equal(Config.Game.MAX_SLOTS)
	end)

	it("fills pedestals first, then storage, then refuses", function()
		local data = Template.create()
		for i = 1, 8 do
			expect(Slots.add(data, Roll.newBrainrot(`p{i}`, "brr_brr_patapim", "Normal", 1, 0), 0)).to.equal(
				"pedestal"
			)
		end
		expect(Slots.add(data, Roll.newBrainrot("s1", "brr_brr_patapim", "Normal", 1, 0), 0)).to.equal(
			"storage"
		)
		expect(Slots.storageCount(data)).to.equal(1)
		for i = 2, Config.Game.STORAGE_SLOTS do
			Slots.add(data, Roll.newBrainrot(`s{i}`, "brr_brr_patapim", "Normal", 1, 0), 0)
		end
		expect(Slots.add(data, Roll.newBrainrot("x", "brr_brr_patapim", "Normal", 1, 0), 0)).to.equal(nil)
		expect(data.brainrots.x).to.equal(nil)
	end)

	it("sanitize moves brainrots off locked or dangling slots", function()
		local data = Template.create()
		data.brainrots.a = Roll.newBrainrot("a", "brr_brr_patapim", "Normal", 1, 0)
		data.pedestals["9"] = "a" -- tier I slot
		data.pedestals["2"] = "ghost"
		expect(Slots.sanitize(data, 0)).to.equal(true)
		expect(data.pedestals["9"]).to.equal(nil)
		expect(data.pedestals["2"]).to.equal(nil)
		expect(data.brainrots.a).to.be.ok()
		expect(Slots.storageCount(data)).to.equal(1)
	end)
end)

return nil
