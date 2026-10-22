--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Config = require("../src/shared/Config")
local Migrations = require("../src/shared/Data/Migrations")
local Template = require("../src/shared/Data/Template")

describe("Data template", function()
	it("starts at the current version with starting cash", function()
		local data = Template.create()
		expect(data.version).to.equal(Template.CURRENT_VERSION)
		expect(data.cash).to.equal(Config.Game.START_CASH)
		expect((next(data.brainrots))).to.equal(nil)
	end)

	it("returns independent tables", function()
		local a = Template.create()
		local b = Template.create()
		a.stats.steals = 5
		expect(b.stats.steals).to.equal(0)
	end)

	it("has a migration step for every version below current", function()
		for v = 1, Template.CURRENT_VERSION - 1 do
			expect(Migrations.steps[v]).to.be.ok()
		end
	end)
end)

describe("Migration 1 -> 2 (mutation -> variant)", function()
	it("renames mutation to variant and keeps old species ids", function()
		local data: { [string]: any } = {
			version = 1,
			brainrots = {
				a = { id = "a", speciesId = "mugpup", rarity = "Common", mutation = "Golden" },
				b = { id = "b", speciesId = "fridgehog", rarity = "Rare", mutation = "Mega" },
			},
		}
		expect((Migrations.run(data, 2))).to.equal(true)
		expect(data.brainrots.a.variant).to.equal("Gold")
		expect(data.brainrots.a.mutation).to.equal(nil)
		expect(data.brainrots.b.variant).to.equal("Normal")
		expect(data.brainrots.b.speciesId).to.equal("fridgehog")
	end)
end)

describe("Migration 2 -> 3 (variants: Gold/Diamond -> Normal, Dark -> Evil)", function()
	it("turns Gold and Diamond into Normal and renames Dark to Evil", function()
		local data: { [string]: any } = {
			version = 2,
			brainrots = {
				g = { id = "g", speciesId = "tralalero_tralala", rarity = "Mythic", variant = "Gold" },
				d = { id = "d", speciesId = "brr_brr_patapim", rarity = "Rare", variant = "Diamond" },
				k = { id = "k", speciesId = "tung_tung_tung_sahur", rarity = "Mythic", variant = "Dark" },
				r = { id = "r", speciesId = "ballerina_cappuccina", rarity = "Epic", variant = "Rainbow" },
				n = { id = "n", speciesId = "bombardiro_crocodilo", rarity = "Legendary", variant = "Normal" },
			},
		}
		expect((Migrations.run(data, 3))).to.equal(true)
		expect(data.version).to.equal(3)
		expect(data.brainrots.g.variant).to.equal("Normal")
		expect(data.brainrots.d.variant).to.equal("Normal")
		expect(data.brainrots.k.variant).to.equal("Evil")
		expect(data.brainrots.r.variant).to.equal("Rainbow")
		expect(data.brainrots.n.variant).to.equal("Normal")
		expect(data.brainrots.g.speciesId).to.equal("tralalero_tralala") -- the brainrot itself is kept
	end)

	it("takes a v1 save all the way to v3", function()
		local data: { [string]: any } = {
			version = 1,
			brainrots = { a = { id = "a", speciesId = "mugpup", rarity = "Common", mutation = "Golden" } },
		}
		expect((Migrations.run(data, 3))).to.equal(true)
		expect(data.brainrots.a.variant).to.equal("Normal")
		expect(data.brainrots.a.mutation).to.equal(nil)
	end)

	it("only produces variants that exist", function()
		local data: { [string]: any } = {
			version = 2,
			brainrots = { x = { id = "x", speciesId = "brr_brr_patapim", rarity = "Rare", variant = "Gold" } },
		}
		Migrations.run(data, 3)
		expect(Config.Variants.byId[data.brainrots.x.variant]).to.be.ok()
	end)
end)

describe("Migrations.run", function()
	local steps = {
		function(data: { [string]: any })
			data.gold = data.coins
			data.coins = nil
		end,
		function(data: { [string]: any })
			data.gold *= 2
		end,
	}

	it("applies steps in order from the save's version", function()
		local data: { [string]: any } = { version = 1, coins = 10 }
		local ok = Migrations.run(data, 3, steps)
		expect(ok).to.equal(true)
		expect(data.version).to.equal(3)
		expect(data.gold).to.equal(20)
		expect(data.coins).to.equal(nil)
	end)

	it("is a no-op at the target version", function()
		local data: { [string]: any } = { version = 3, gold = 1 }
		expect((Migrations.run(data, 3, steps))).to.equal(true)
		expect(data.gold).to.equal(1)
	end)

	it("refuses saves from a newer build", function()
		local data: { [string]: any } = { version = 4 }
		local ok, reason = Migrations.run(data, 3, steps)
		expect(ok).to.equal(false)
		expect(reason).to.be.ok()
	end)

	it("reports a missing step", function()
		local data: { [string]: any } = { version = 1, coins = 1 }
		local ok = Migrations.run(data, 4, steps)
		expect(ok).to.equal(false)
	end)
end)

return nil
