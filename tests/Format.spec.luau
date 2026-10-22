--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Format = require("../src/shared/Util/Format")

describe("Format", function()
	it("formats cash with commas, then suffixes from a million", function()
		expect(Format.cash(0)).to.equal("$0")
		expect(Format.cash(12480)).to.equal("$12,480")
		expect(Format.cash(999999)).to.equal("$999,999")
		expect(Format.cash(1250000)).to.equal("$1.25M")
		expect(Format.cash(2e9)).to.equal("$2B")
	end)

	it("formats compact prices like the shop mockup", function()
		expect(Format.price(55)).to.equal("$55")
		expect(Format.price(1050)).to.equal("$1,050")
		expect(Format.price(5200)).to.equal("$5,200")
		expect(Format.price(26000)).to.equal("$26K")
		expect(Format.price(13500)).to.equal("$13.5K")
		expect(Format.price(999999)).to.equal("$1M")
	end)

	it("formats income rates", function()
		expect(Format.perSec(84)).to.equal("+$84/s")
		expect(Format.perSec(2.6)).to.equal("+$2.6/s")
		expect(Format.perSec(6)).to.equal("+$6/s")
		expect(Format.perSec(12500)).to.equal("+$12.5K/s")
	end)

	it("formats clocks and durations", function()
		expect(Format.clock(42)).to.equal("0:42")
		expect(Format.clock(342)).to.equal("5:42")
		expect(Format.clock(3723)).to.equal("1:02:03")
		expect(Format.clock(-5)).to.equal("0:00")
		expect(Format.duration(45)).to.equal("45s")
		expect(Format.duration(61)).to.equal("2m")
		expect(Format.duration(80 * 60)).to.equal("1h 20m")
	end)

	it("writes payback in plain words, rounding up", function()
		expect(Format.payback(210, 2.6)).to.equal("Pays back in 2m")
		expect(Format.payback(55, 1)).to.equal("Pays back in under 1m")
		expect(Format.payback(26000, 40)).to.equal("Pays back in 11m")
		expect(Format.payback(100, 0)).to.equal("")
	end)
end)

return nil
