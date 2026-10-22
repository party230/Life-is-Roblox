--!strict
-- Loyalty, runaway timer, growth and the stolen-return rule (D39).
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Config = require("../src/shared/Config")
local Growth = require("../src/shared/Logic/Growth")
local Income = require("../src/shared/Logic/Income")
local Loyalty = require("../src/shared/Logic/Loyalty")
local Roll = require("../src/shared/Logic/Roll")

local C = Config.Loyalty
local food = Config.Food.byId

local function fresh()
	return Roll.newBrainrot("id1", "brr_brr_patapim", "Normal", 42, 1000)
end

describe("Runaway timer", function()
	it("starts every acquired brainrot at the 2-day minimum", function()
		local b = fresh()
		expect(b.timerDays).to.equal(C.TIMER_MIN_DAYS)
		expect(C.TIMER_MIN_DAYS).to.equal(2)
		b.timerDays = 0.1
		Loyalty.acquire(b, 7, 2000) -- bought by someone else off the carpet
		expect(b.timerDays).to.equal(2)
		expect(b.ownerUserId).to.equal(7)
		b.timerDays = 0
		b.leaving = true
		Loyalty.caught(b, 3000) -- caught back
		expect(b.timerDays).to.equal(2)
		expect(b.leaving).to.equal(false)
	end)

	it("stacks food on whatever is left (1 day + two +2-day foods = 5 days)", function()
		local b = fresh()
		b.timerDays = 1
		Loyalty.feed(b, food.spaghetti, 2, 0) -- Spaghetti Bowl: +2 days each
		expect(b.timerDays).to.be.near(5)
		expect(b.timerFullDays).to.be.near(5) -- the bar refills
		expect(Loyalty.timerFraction(b)).to.be.near(1)
	end)

	it("caps the timer at MAX_TIMER_DAYS (60)", function()
		local b = fresh()
		Loyalty.feed(b, food.banquet, 10, 0) -- +200 days
		expect(b.timerDays).to.equal(C.MAX_TIMER_DAYS)
		expect(C.MAX_TIMER_DAYS).to.equal(60)
		local c = fresh()
		Loyalty.feed(c, food.nonna, 1, 0) -- fills to the cap
		expect(c.timerDays).to.equal(60)
	end)

	it("only counts down by the in-game time it's given (online only), then marks it leaving", function()
		local b = fresh()
		expect(Loyalty.tick(b, 0)).to.equal(false) -- owner offline: the server doesn't tick it
		expect(b.timerDays).to.equal(2)
		expect(Loyalty.tick(b, 1.5)).to.equal(false)
		expect(b.timerDays).to.be.near(0.5)
		expect(Loyalty.tick(b, 1)).to.equal(true) -- just ran out
		expect(b.timerDays).to.equal(0)
		expect(b.leaving).to.equal(true)
		expect(Loyalty.tick(b, 1)).to.equal(false) -- already leaving
	end)

	it("lets food save a 'leaving tonight' brainrot", function()
		local b = fresh()
		Loyalty.tick(b, 3)
		expect(b.leaving).to.equal(true)
		Loyalty.feed(b, food.slice, 1, 0)
		expect(b.leaving).to.equal(false)
		expect(b.timerDays).to.be.near(1)
	end)

	it("turns the bar yellow at 25% and red at 10%", function()
		expect(Loyalty.barColor(0.8)).to.equal("green")
		expect(Loyalty.barColor(0.26)).to.equal("green")
		expect(Loyalty.barColor(0.25)).to.equal("yellow")
		expect(Loyalty.barColor(0.11)).to.equal("yellow")
		expect(Loyalty.barColor(0.1)).to.equal("red")
		expect(Loyalty.barColor(0)).to.equal("red")
	end)

	it("pauses under a Bond Collar (no timer, no loyalty growth)", function()
		local b = fresh()
		b.bondCollared = true
		local before = b.loyalty
		Loyalty.tick(b, 0.5)
		expect(b.timerDays).to.equal(2)
		expect(b.loyalty).to.equal(before)
	end)

	it("formats in-game days and hours", function()
		expect(Loyalty.formatDays(3.25)).to.equal("3d 6h")
		expect(Loyalty.formatDays(0)).to.equal("0d 0h")
	end)
end)

describe("Loyalty", function()
	it("maps loyalty to income: x0.5 at 0, x1 at 50, x2 at 100", function()
		expect(Loyalty.incomeMult(0)).to.be.near(0.5)
		expect(Loyalty.incomeMult(25)).to.be.near(0.75)
		expect(Loyalty.incomeMult(50)).to.be.near(1)
		expect(Loyalty.incomeMult(75)).to.be.near(1.5)
		expect(Loyalty.incomeMult(100)).to.be.near(2)
		expect(Loyalty.incomeMult(250)).to.be.near(2) -- clamped
	end)

	it("applies loyalty and growth stage to a brainrot's income", function()
		local b = fresh() -- Rare x6, factor 1, loyalty 50, Adult
		expect(Income.effective(b)).to.be.near(6)
		b.loyalty = 100
		expect(Income.effective(b)).to.be.near(12)
		b.growth = 0 -- Baby x0.4
		expect(Income.effective(b)).to.be.near(12 * 0.4)
	end)

	it("stacks loyalty from feeding, up to the max", function()
		local b = fresh()
		Loyalty.feed(b, food.slice, 3, 0) -- +4 each
		expect(b.loyalty).to.equal(C.START + 12)
		Loyalty.feed(b, food.espresso, 1, 0) -- Max loyalty
		expect(b.loyalty).to.equal(C.MAX)
	end)

	it("trickles up while fed and decays when neglected", function()
		local b = fresh()
		Loyalty.tick(b, 0.5)
		expect(b.loyalty).to.be.near(C.START + C.TRICKLE_PER_DAY * 0.5)
		b.loyalty = 50
		b.sinceFedDays = C.NEGLECT_AFTER_DAYS + 0.1
		Loyalty.tick(b, 1)
		expect(b.loyalty).to.be.near(50 - C.NEGLECT_DECAY_PER_DAY)
	end)

	it("costs a little loyalty when a runaway is caught", function()
		local b = fresh()
		b.loyalty = 40
		Loyalty.caught(b, 0)
		expect(b.loyalty).to.equal(40 - C.CATCH_PENALTY)
	end)
end)

describe("Runaway / return decision", function()
	it("stays while its timer has time left", function()
		expect(Loyalty.nightDecision(fresh(), false)).to.equal("stay")
	end)

	it("runs away once it's leaving tonight", function()
		local b = fresh()
		Loyalty.tick(b, 5)
		expect(Loyalty.nightDecision(b, false)).to.equal("runaway")
	end)

	it("runs home when stolen and still loyal to its original owner", function()
		local b = fresh()
		b.loyalty = 80
		Loyalty.steal(b, 99, 0)
		expect(b.ownerUserId).to.equal(99)
		expect(b.originalOwnerUserId).to.equal(42)
		expect(b.oldLoyalty).to.equal(80)
		expect(b.loyalty).to.equal(C.STOLEN_START)
		expect(b.timerDays).to.equal(C.TIMER_MIN_DAYS)
		expect(Loyalty.nightDecision(b, true)).to.equal("returnHome")
		-- the original owner isn't in this server: it can't go home tonight
		expect(Loyalty.nightDecision(b, false)).to.equal("stay")
		Loyalty.returnHome(b, 0)
		expect(b.ownerUserId).to.equal(42)
		expect(b.loyalty).to.equal(80)
		expect(b.isStolen).to.equal(false)
	end)

	it("stays with the thief when its old loyalty is below the threshold", function()
		local b = fresh()
		b.loyalty = C.RETURN_HOME_THRESHOLD - 1
		Loyalty.steal(b, 99, 0)
		expect(Loyalty.nightDecision(b, true)).to.equal("stay")
		-- and from then on follows the normal rule
		Loyalty.tick(b, 5)
		expect(Loyalty.nightDecision(b, true)).to.equal("runaway")
	end)

	it("forgets its original owner a little every night", function()
		local b = fresh()
		b.loyalty = 75
		Loyalty.steal(b, 99, 0)
		Loyalty.nightPassed(b)
		expect(b.oldLoyalty).to.equal(75 - C.OLD_LOYALTY_DECAY_PER_NIGHT)
		expect(Loyalty.nightDecision(b, true)).to.equal("stay") -- 65 < 70
	end)
end)

describe("Growth", function()
	it("grows Baby -> Teen -> Adult by points", function()
		expect(Growth.stageFor(0).id).to.equal("Baby")
		expect(Growth.stageFor(39).id).to.equal("Baby")
		expect(Growth.stageFor(40).id).to.equal("Teen")
		expect(Growth.stageFor(140).id).to.equal("Adult")
		local nextStage, need = Growth.toNext(30)
		expect((nextStage :: any).id).to.equal("Teen")
		expect(need).to.equal(10)
	end)

	it("grows from food and slowly over time (passive trickle)", function()
		local b = fresh()
		b.growth = 0
		Loyalty.feed(b, food.lasagna, 2, 0) -- +13 each
		expect(b.growth).to.equal(26)
		Growth.tick(b, 1) -- +1 per in-game hour
		expect(b.growth).to.be.near(26 + 24)
		expect(Growth.stage(b).id).to.equal("Teen")
	end)

	it("makes it an Adult instantly with Nonna's Secret Recipe, wherever it is", function()
		local b = fresh()
		b.growth = 3
		Loyalty.feed(b, food.nonna, 1, 0)
		expect(Growth.stage(b).id).to.equal("Adult")
		expect(b.loyalty).to.equal(C.MAX)
	end)
end)

return nil
