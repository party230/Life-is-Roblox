--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local RateLimiter = require("../src/shared/Util/RateLimiter")

describe("RateLimiter", function()
	it("allows a burst, then refills over time", function()
		local t = 0
		local limiter = RateLimiter.new({ burst = 3, perSecond = 1 }, function()
			return t
		end)
		expect(limiter:allow("p")).to.equal(true)
		expect(limiter:allow("p")).to.equal(true)
		expect(limiter:allow("p")).to.equal(true)
		expect(limiter:allow("p")).to.equal(false)
		t = 1
		expect(limiter:allow("p")).to.equal(true)
		expect(limiter:allow("p")).to.equal(false)
		t = 100
		for _ = 1, 3 do
			expect(limiter:allow("p")).to.equal(true)
		end
		expect(limiter:allow("p")).to.equal(false)
	end)

	it("tracks keys independently and can forget them", function()
		local t = 0
		local limiter = RateLimiter.new({ burst = 1, perSecond = 0 }, function()
			return t
		end)
		expect(limiter:allow("a")).to.equal(true)
		expect(limiter:allow("b")).to.equal(true)
		expect(limiter:allow("a")).to.equal(false)
		limiter:forget("a")
		expect(limiter:allow("a")).to.equal(true)
	end)
end)

return nil
