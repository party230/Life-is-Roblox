--!strict
-- Food shop pricing, inventory and the nursery unlock price (D39).
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Config = require("../src/shared/Config")
local FoodShop = require("../src/shared/Logic/FoodShop")
local Nursery = require("../src/shared/Logic/Nursery")
local Template = require("../src/shared/Data/Template")

local F = Config.Food

describe("Food config", function()
	it("has the owner's 18 foods with their prices and effects", function()
		expect(#F.list).to.equal(18)
		local slice = F.byId.slice
		expect(slice.cash).to.equal(1_000)
		expect(slice.days).to.equal(1)
		expect(slice.loyalty).to.equal(4)
		local banquet = F.byId.banquet
		expect(banquet.cash).to.equal(2_500_000)
		expect(banquet.robux).to.equal(10)
		expect(banquet.days).to.equal(20)
		expect(F.byId.nonna.robux).to.equal(2_985)
		expect(F.byId.nonna.fillsTimer).to.equal(true)
		expect(F.byId.espresso.maxLoyalty).to.equal(true)
		for i = 1, 9 do
			expect(F.list[i].robux).to.equal(nil) -- cash only
		end
		for i = 15, 18 do
			expect(F.list[i].cash).to.equal(nil) -- Robux only
		end
	end)
end)

describe("Food prices", function()
	it("multiplies cash prices by quantity", function()
		expect(FoodShop.cashPrice(F.byId.slice, 10)).to.equal(10_000)
		expect(FoodShop.cashPrice(F.byId.crate, 1)).to.equal(nil)
		expect(FoodShop.isValidCashQuantity(5)).to.equal(true)
		expect(FoodShop.isValidCashQuantity(7)).to.equal(false)
	end)

	it("gives the x5 Robux bundle a 10% discount", function()
		expect(FoodShop.robuxPrice(F.byId.gelato, 1)).to.equal(2)
		expect(FoodShop.robuxPrice(F.byId.gelato, 5)).to.equal(9) -- 10 -> 9
		expect(FoodShop.robuxPrice(F.byId.banquet, 5)).to.equal(45) -- 50 -> 45
		expect(FoodShop.robuxPrice(F.byId.crate, 5)).to.equal(1282)
		expect(FoodShop.robuxPrice(F.byId.slice, 1)).to.equal(nil)
	end)

	it("picks the priciest food costing at most ~10 minutes of income as 'Best for you'", function()
		expect(FoodShop.bestFor(0)).to.equal("breadstick") -- nothing affordable: cheapest
		expect(FoodShop.bestFor(10)).to.equal("spaghetti") -- budget $6,000: Spaghetti Bowl is exactly $6,000
		expect(FoodShop.bestFor(1_000_000)).to.equal("banquet")
	end)
end)

describe("Food inventory", function()
	it("adds, caps and takes food", function()
		local data = Template.create()
		expect(FoodShop.add(data, "slice", 5)).to.equal(5)
		expect(FoodShop.count(data, "slice")).to.equal(5)
		expect(FoodShop.take(data, "slice", 6)).to.equal(false)
		expect(FoodShop.take(data, "slice", 5)).to.equal(true)
		expect(data.food.slice).to.equal(nil)
		data.food.slice = F.INVENTORY_CAP - 1
		expect(FoodShop.add(data, "slice", 10)).to.equal(1)
	end)
end)

describe("Nursery", function()
	it("prices the unlock from progress (best-ever income), clamped", function()
		expect(Nursery.unlockPrice(0)).to.equal(Config.Nursery.UNLOCK_MIN)
		expect(Nursery.unlockPrice(1_000)).to.equal(300_000) -- 5 minutes of $1,000/s
		expect(Nursery.unlockPrice(1e9)).to.equal(Config.Nursery.UNLOCK_MAX)
		expect(Nursery.unlockPrice(1_234) >= 1_234 * 300).to.equal(true) -- rounded up to a nice number
	end)

	it("has 3 incubators plus one per pass tier, up to 6", function()
		expect(Nursery.incubators(0)).to.equal(3)
		expect(Nursery.incubators(2)).to.equal(5)
		expect(Nursery.incubators(9)).to.equal(6)
	end)
end)

return nil
