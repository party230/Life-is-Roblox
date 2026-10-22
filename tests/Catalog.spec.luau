--!strict
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Catalog = require("../src/shared/Logic/Catalog")
local Config = require("../src/shared/Config")

describe("Catalog", function()
	it("resolves enabled characters to themselves", function()
		local def = Catalog.resolve("tralalero_tralala", "Mythic")
		expect(def.id).to.equal("tralalero_tralala")
		expect(Catalog.isPlaceholder(def)).to.equal(false)
	end)

	it("resolves unknown (removed) ids to the stored rarity's placeholder", function()
		local def = Catalog.resolve("mugpup", "Common")
		expect(def.id).to.equal("placeholder_common")
		expect(def.rarity).to.equal("Common")
		expect(Catalog.isPlaceholder(def)).to.equal(true)
		expect(Catalog.resolve("gone", "Secret").rarity).to.equal("Secret")
	end)

	it("treats disabled characters as placeholders and never spawns them", function()
		local disabled = table.clone(Config.Species.byId.tung_tung_tung_sahur) :: any
		disabled.disabled = true
		expect(Catalog.isSpawnable(disabled)).to.equal(false)
	end)

	it("only spawns modelled characters while REQUIRE_BUILT_MODELS is on", function()
		local spawnable = Catalog.spawnable()
		if Config.Game.REQUIRE_BUILT_MODELS then
			for _, def in spawnable do
				expect(def.model).to.be.ok()
			end
			expect(#Catalog.spawnable("Common")).to.equal(0)
		end
		expect(#spawnable > 0).to.equal(true)
	end)

	it("drops empty rarities from roll weights", function()
		local w = Catalog.filterWeights(Config.Shop.RARITY_WEIGHTS)
		for rarity in w do
			expect(#Catalog.spawnable(rarity) > 0).to.equal(true)
		end
	end)
end)

return nil
