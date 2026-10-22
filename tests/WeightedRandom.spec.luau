--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local WeightedRandom = require("../src/shared/Util/WeightedRandom")

local function fixed(value: number): () -> number
	return function()
		return value
	end
end

describe("WeightedRandom.pickKey", function()
	local weights = { a = 1, b = 3, c = 0 }

	it("is deterministic across key order (sorted a, b)", function()
		expect(WeightedRandom.pickKey(weights, fixed(0))).to.equal("a")
		expect(WeightedRandom.pickKey(weights, fixed(0.24))).to.equal("a")
		expect(WeightedRandom.pickKey(weights, fixed(0.25))).to.equal("b")
		expect(WeightedRandom.pickKey(weights, fixed(0.9999))).to.equal("b")
	end)

	it("never picks zero-weight keys", function()
		for i = 0, 99 do
			expect(WeightedRandom.pickKey(weights, fixed(i / 100))).never.to.equal("c")
		end
	end)

	it("returns nil when nothing can be picked", function()
		expect(WeightedRandom.pickKey({ a = 0 }, fixed(0.5))).to.equal(nil)
		expect(WeightedRandom.pickKey({}, fixed(0.5))).to.equal(nil)
	end)

	it("matches the weights over many seeded rolls", function()
		-- Seeded LCG (Lune has no Roblox Random).
		local state = 42
		local function rng(): number
			state = (state * 1103515245 + 12345) % 2147483648
			return state / 2147483648
		end
		local counts = { a = 0, b = 0 }
		local n = 20000
		for _ = 1, n do
			local key = WeightedRandom.pickKey(weights, rng) :: string
			counts[key] += 1
		end
		expect(counts.a / n).to.be.near(0.25, 0.02)
	end)
end)

describe("WeightedRandom.pickItem", function()
	it("reads weights through the getter", function()
		local items = { { id = "x", w = 0 }, { id = "y", w = 2 }, { id = "z", w = 2 } }
		local function getW(item: { id: string, w: number }): number
			return item.w
		end
		expect((WeightedRandom.pickItem(items, getW, fixed(0.1)) :: any).id).to.equal("y")
		expect((WeightedRandom.pickItem(items, getW, fixed(0.6)) :: any).id).to.equal("z")
	end)
end)

describe("WeightedRandom.odds", function()
	it("normalises to 1", function()
		local odds = WeightedRandom.odds({ a = 1, b = 3, c = 0 })
		expect(odds.a).to.be.near(0.25)
		expect(odds.b).to.be.near(0.75)
		expect(odds.c).to.equal(nil)
	end)
end)

return nil
