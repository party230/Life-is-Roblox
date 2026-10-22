--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Signal = require("../src/shared/Util/Signal")

describe("Signal", function()
	it("passes arguments and supports disconnect", function()
		local signal = Signal.new() :: Signal.Signal<number, string>
		local got = {}
		local conn = signal:connect(function(n, s)
			table.insert(got, `{n}{s}`)
		end)
		signal:fire(1, "a")
		conn:disconnect()
		signal:fire(2, "b")
		expect(#got).to.equal(1)
		expect(got[1]).to.equal("1a")
	end)

	it("once fires a single time", function()
		local signal = Signal.new() :: Signal.Signal<>
		local count = 0
		signal:once(function()
			count += 1
		end)
		signal:fire()
		signal:fire()
		expect(count).to.equal(1)
	end)

	it("tolerates disconnecting another handler mid-fire", function()
		local signal = Signal.new() :: Signal.Signal<>
		local secondRan = false
		local second
		signal:connect(function()
			second:disconnect()
		end)
		second = signal:connect(function()
			secondRan = true
		end)
		signal:fire()
		expect(secondRan).to.equal(false)
	end)
end)

return nil
