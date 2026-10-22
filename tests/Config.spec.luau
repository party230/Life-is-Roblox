--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Config = require("../src/shared/Config")
local Validate = require("../src/shared/Config/Validate")

-- Deep copy without freezing so tests can break values.
local function thaw(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = thaw(v)
	end
	return copy
end

describe("Config", function()
	it("passes validation with no errors", function()
		local result = Validate.run(Config)
		if #result.errors > 0 then
			error(table.concat(result.errors, "\n"))
		end
	end)

	it("matches the spec's starting values", function()
		local g = Config.Game
		expect(g.DAY_LENGTH).to.equal(480)
		expect(g.DUSK).to.equal(20)
		expect(g.NIGHT_LENGTH).to.equal(240)
		expect(g.DAWN_VOTE).to.equal(30)
		expect(g.START_CASH).to.equal(100)
		expect(g.START_SLOTS).to.equal(8)
		expect(g.ESCAPE_SPEED_CAP).to.equal(32)
		expect(g.LOYALTY_SPEED_DIVISOR).to.equal(200)
		expect(g.DEFECT_SCALAR).to.equal(0.004)
		expect(g.ROTTER_MIN_PLAYERS).to.equal(5)
		expect(g.SHIELD_POST_COOLDOWN).to.equal(120)
	end)

	it("is frozen", function()
		expect(function()
			(Config.Game :: any).START_CASH = 1e9
		end).to.throw()
	end)

	it("has 12 species with unique ids and a species for every rarity", function()
		expect(#Config.Species.list).to.equal(12)
		local rarities: { [string]: boolean } = {}
		for _, s in Config.Species.list do
			rarities[s.rarity] = true
		end
		for _, r in Config.Rarities.list do
			expect(rarities[r.id]).to.equal(true)
		end
	end)

	it("lists every product from the monetisation table", function()
		expect(#Config.Products.gamePasses).to.equal(7)
		expect(#Config.Products.devProducts).to.equal(14)
		expect(Config.Products.passByKey.BondCollar.robux).to.equal(199)
		expect(Config.Products.BOND_COLLAR_MAX_BRAINROTS).to.equal(2)
	end)

	it("warns about placeholder product ids", function()
		local result = Validate.run(Config)
		expect(#result.warnings > 0).to.equal(true)
	end)

	describe("Validate catches", function()
		it("an unknown species rarity", function()
			local broken = thaw(Config)
			broken.Species.list[1].rarity = "Ultra"
			expect(#Validate.run(broken).errors > 0).to.equal(true)
		end)

		it("a rollable rarity with no species", function()
			local broken = thaw(Config)
			local kept = {}
			for _, s in broken.Species.list do
				if s.rarity ~= "Secret" then
					table.insert(kept, s)
				end
			end
			broken.Species.list = kept
			expect(#Validate.run(broken).errors > 0).to.equal(true)
		end)

		it("a carry speed divisor that could stop a carrier", function()
			local broken = thaw(Config)
			broken.Game.LOYALTY_SPEED_DIVISOR = 50
			expect(#Validate.run(broken).errors > 0).to.equal(true)
		end)

		it("a wave outside the night", function()
			local broken = thaw(Config)
			broken.Waves.waves[1].at = 9999
			expect(#Validate.run(broken).errors > 0).to.equal(true)
		end)

		it("duplicate real product ids", function()
			local broken = thaw(Config)
			broken.Products.gamePasses[1].id = 123
			broken.Products.devProducts[1].id = 123
			expect(#Validate.run(broken).errors > 0).to.equal(true)
		end)
	end)
end)

return nil
