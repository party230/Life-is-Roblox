--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Guard = require("../src/shared/Util/Guard")

describe("Guard", function()
	it("rejects NaN, infinity and out-of-range numbers", function()
		local check = Guard.number(0, 10)
		expect(check(5)).to.equal(true)
		expect(check(0 / 0)).to.equal(false)
		expect(check(math.huge)).to.equal(false)
		expect(check(-1)).to.equal(false)
		expect(check(11)).to.equal(false)
		expect(check("5")).to.equal(false)
	end)

	it("checks integers", function()
		expect(Guard.integer(1, 14)(3)).to.equal(true)
		expect(Guard.integer(1, 14)(3.5)).to.equal(false)
	end)

	it("limits string length and requires valid UTF-8", function()
		local check = Guard.string(4)
		expect(check("abcd")).to.equal(true)
		expect(check("abcde")).to.equal(false)
		expect(check("\255\254")).to.equal(false)
		expect(check(nil)).to.equal(false)
	end)

	it("validates GUIDs and literals", function()
		expect(Guard.guid("0A1B2C3D-0000-4000-8000-1234567890AB")).to.equal(true)
		expect(Guard.guid("not-a-guid")).to.equal(false)
		expect(Guard.literal("feed", "pet")("pet")).to.equal(true)
		expect(Guard.literal("feed", "pet")("eat")).to.equal(false)
	end)

	it("validates whole argument lists, rejecting extras", function()
		local check = Guard.args(Guard.guid, Guard.optional(Guard.boolean))
		local id = "0A1B2C3D-0000-4000-8000-1234567890AB"
		expect(check(id)).to.equal(true)
		expect(check(id, true)).to.equal(true)
		expect(check(id, "yes")).to.equal(false)
		expect(check(id, true, "extra")).to.equal(false)
		expect(check()).to.equal(false)
		expect(Guard.args()()).to.equal(true)
		expect(Guard.args()(1)).to.equal(false)
	end)
end)

return nil
