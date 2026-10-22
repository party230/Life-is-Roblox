--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Config = require("../src/shared/Config")
local Cycle = require("../src/shared/Logic/Cycle")
local Incubator = require("../src/shared/Logic/Incubator")
local Plots = require("../src/shared/Logic/Plots")

describe("Cycle", function()
	local g = Config.Game

	it("walks Day -> Dusk -> Night -> DawnVote and wraps", function()
		expect(Cycle.at(0).phase).to.equal("Day")
		expect(Cycle.at(g.DAY_LENGTH - 1).phase).to.equal("Day")
		expect(Cycle.at(g.DAY_LENGTH).phase).to.equal("Dusk")
		expect(Cycle.at(g.DAY_LENGTH + g.DUSK).phase).to.equal("Night")
		expect(Cycle.at(g.DAY_LENGTH + g.DUSK + g.NIGHT_LENGTH).phase).to.equal("DawnVote")
		local wrapped = Cycle.at(Cycle.length() + 5)
		expect(wrapped.phase).to.equal("Day")
		expect(wrapped.cycle).to.equal(1)
	end)

	it("reports time remaining in the phase", function()
		expect(Cycle.at(100).remaining).to.be.near(g.DAY_LENGTH - 100)
		expect(Cycle.at(g.DAY_LENGTH + 5).remaining).to.be.near(g.DUSK - 5)
	end)

	it("closes the shop for Night and the vote only", function()
		expect(Cycle.shopOpen("Day")).to.equal(true)
		expect(Cycle.shopOpen("Dusk")).to.equal(true)
		expect(Cycle.shopOpen("Night")).to.equal(false)
		expect(Cycle.shopOpen("DawnVote")).to.equal(false)
	end)
end)

describe("Plots", function()
	it("puts every plot on the ring, facing the plaza", function()
		for i = 1, Config.Game.PLOT_COUNT do
			local pose = Plots.pose(i)
			expect(math.sqrt(pose.x ^ 2 + pose.z ^ 2)).to.be.near(Config.Layout.PLOT_RING_RADIUS, 1e-6)
			-- LookVector = (-sin yaw, -cos yaw) must point at the origin
			local lx, lz = -math.sin(pose.yaw), -math.cos(pose.yaw)
			local tx, tz = -pose.x / Config.Layout.PLOT_RING_RADIUS, -pose.z / Config.Layout.PLOT_RING_RADIUS
			expect(lx).to.be.near(tx, 1e-6)
			expect(lz).to.be.near(tz, 1e-6)
		end
	end)

	it("converts local <-> world consistently", function()
		local pose = Plots.pose(3)
		local wx, wz = Plots.toWorld(pose, 5, -7)
		local lx, lz = Plots.toLocal(pose, wx, wz)
		expect(lx).to.be.near(5, 1e-9)
		expect(lz).to.be.near(-7, 1e-9)
		-- the gate (local -Z) is closer to the plaza than the back wall
		local gx, gz = Plots.toWorld(pose, 0, -20)
		local bx, bz = Plots.toWorld(pose, 0, 20)
		expect(gx ^ 2 + gz ^ 2 < bx ^ 2 + bz ^ 2).to.equal(true)
	end)

	it("finds ring neighbours with wraparound", function()
		local a, b = Plots.neighbours(1)
		expect(a).to.equal(8)
		expect(b).to.equal(2)
		local c, d = Plots.neighbours(8)
		expect(c).to.equal(7)
		expect(d).to.equal(1)
	end)

	it("keeps plots from overlapping", function()
		local p1, p2 = Plots.pose(1), Plots.pose(2)
		local dist = math.sqrt((p1.x - p2.x) ^ 2 + (p1.z - p2.z) ^ 2)
		expect(dist > Config.Layout.PLOT_WIDTH + 10).to.equal(true)
	end)
end)

describe("Incubator", function()
	it("counts down and becomes ready", function()
		local egg = { id = "e", eggId = "basic", startedAt = 100, hatchSeconds = 30 }
		expect(Incubator.timeLeft(egg, 110)).to.equal(20)
		expect(Incubator.isReady(egg, 129)).to.equal(false)
		expect(Incubator.isReady(egg, 130)).to.equal(true)
		local found, index = Incubator.find({ egg }, "e")
		expect(found).to.equal(egg)
		expect(index).to.equal(1)
	end)
end)

return nil
