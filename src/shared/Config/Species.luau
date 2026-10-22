--!strict
-- Character roster. THE ONLY PLACE character names live: game logic and saves use the stable `id`, so any
-- character can be renamed, re-modelled or swapped by editing its row here (D21, LEGAL_REVIEW.md).
--
-- Fields:
--   id           stable save key; never change it once players own copies (rename displayName instead)
--   displayName  shown on nameplates / UI
--   rarity       Common .. Secret
--   incomeFactor small per-character variation on top of rarity (and variant) multipliers
--   model        key into shared/World/Models (builder or mesh asset); nil = not built yet (placeholder)
--   reference    expected reference image path (assets/reference/<id>.png)
--   disabled     true = removed from spawns, shop and eggs; owned copies show as their rarity's placeholder
--                (saves are untouched, so re-enabling restores them)

local Rarities = require("./Rarities")

export type SpeciesDef = {
	id: string,
	displayName: string,
	rarity: Rarities.RarityId,
	incomeFactor: number,
	model: string?,
	reference: string,
	disabled: boolean,
}

type Row = { id: string, displayName: string, incomeFactor: number, model: string? }

local function R(id: string, displayName: string, incomeFactor: number, model: string?): Row
	return { id = id, displayName = displayName, incomeFactor = incomeFactor, model = model }
end

local ROSTER: { [string]: { Row } } = {
	Common = {
		R("bobrito_bandito", "Bobrito Bandito", 1.00),
		R("trulimero_trulichina", "Trulimero Trulichina", 0.90),
		R("frulli_frulla", "Frulli Frulla", 0.95),
		R("talpa_di_ferro", "Talpa Di Ferro", 1.10),
		R("pipi_kiwi", "Pipi Kiwi", 0.85),
		R("pipi_corni", "Pipi Corni", 0.90),
		R("penguino_cocosino", "Penguino Cocosino", 1.00),
		R("salamino_pinguino", "Salamino Pinguino", 1.05),
		R("agarrini_la_palini", "Agarrini La Palini", 1.10),
		R("svinino_bombondino", "Svinino Bombondino", 1.15),
	},
	Uncommon = {
		R("lirili_larila", "Lirili Larila", 0.90),
		R("boneca_ambalabu", "Boneca Ambalabu", 0.95),
		R("burbaloni_luliloli", "Burbaloni Luliloli", 1.00),
		R("orangutini_ananasini", "Orangutini Ananasini", 1.00),
		R("spioniro_golubiro", "Spioniro Golubiro", 1.05),
		R("zibra_zubra_zibralini", "Zibra Zubra Zibralini", 1.05),
		R("bananita_dolphinita", "Bananita Dolphinita", 1.10),
		R("tigroligre_frutonni", "Tigroligre Frutonni", 1.10),
		R("rhino_toasterino", "Rhino Toasterino", 1.15),
	},
	Rare = {
		R("brr_brr_patapim", "Brr Brr Patapim", 1.00, "brr_brr_patapim"),
		R("trippi_troppi", "Trippi Troppi", 0.90),
		R("chimpanzini_bananini", "Chimpanzini Bananini", 1.05),
		R("bombombini_gusini", "Bombombini Gusini", 1.00),
		R("cappuccino_assassino", "Cappuccino Assassino", 1.10),
		R("frigo_camelo", "Frigo Camelo", 0.95),
		R("glorbo_fruttodrillo", "Glorbo Fruttodrillo", 1.00),
		R("tric_trac_baraboom", "Tric Trac Baraboom", 1.05),
		R("cavallo_virtuoso", "Cavallo Virtuoso", 1.15),
	},
	Epic = {
		R("ballerina_cappuccina", "Ballerina Cappuccina", 1.00, "ballerina_cappuccina"),
		R("girafa_celeste", "Girafa Celeste", 0.95),
		R("cocofanto_elefanto", "Cocofanto Elefanto", 1.05),
		R("graipuss_medussi", "Graipuss Medussi", 1.00),
		R("chef_crabracadabra", "Chef Crabracadabra", 1.10),
		R("elefantino_frigorifero", "Elefantino Frigorifero", 0.95),
		R("orcalero_orcala", "Orcalero Orcala", 1.05),
		R("tigrullini_watermelini", "Tigrullini Watermelini", 1.10),
	},
	Legendary = {
		R("bombardiro_crocodilo", "Bombardiro Crocodilo", 1.00, "bombardiro_crocodilo"),
		R("bombardino_gusini", "Bombardino Gusini", 0.95),
		R("tralalita_tralala", "Tralalita Tralala", 1.00),
		R("chicleteira_bicicleteira", "Chicleteira Bicicleteira", 1.05),
		R("trenostruzzo_turbo_3000", "Trenostruzzo Turbo 3000", 1.10),
		R("los_orcalitos", "Los Orcalitos", 1.10),
	},
	Mythic = {
		R("tralalero_tralala", "Tralalero Tralala", 1.00, "tralalero_tralala"),
		R("tung_tung_tung_sahur", "Tung Tung Tung Sahur", 1.00, "tung_tung_tung_sahur"),
		R("la_vaca_saturno_saturnita", "La Vaca Saturno Saturnita", 1.05),
		R("nuclearo_dinossauro", "Nuclearo Dinossauro", 1.10),
		R("los_bombinitos", "Los Bombinitos", 1.10),
	},
	Secret = {
		R("los_tralaleritos", "Los Tralaleritos", 1.00),
		R("las_tralaleritas", "Las Tralaleritas", 1.00),
		R("la_grande_combinasion", "La Grande Combinasion", 1.20),
	},
} :: any

-- Ids disabled for legal or quality reasons. Put an id here (or set disabled = true below) to pull it.
local DISABLED: { [string]: boolean } = {}

local list: { SpeciesDef } = {}
for _, rarity in Rarities.list do
	local rows: { Row } = ROSTER[rarity.id] or {}
	for _, row in rows do
		local id = row.id
		table.insert(
			list,
			table.freeze({
				id = id,
				displayName = row.displayName,
				rarity = rarity.id,
				incomeFactor = row.incomeFactor,
				model = row.model,
				reference = `assets/reference/{id}.png`,
				disabled = DISABLED[id] == true,
			})
		)
	end
end

local byId: { [string]: SpeciesDef } = {}
for _, def in list do
	byId[def.id] = def
end

-- One placeholder per rarity: shown for disabled/removed characters and for characters without a model yet.
local placeholders: { [string]: SpeciesDef } = {}
for _, rarity in Rarities.list do
	placeholders[rarity.id] = table.freeze({
		id = `placeholder_{string.lower(rarity.id)}`,
		displayName = `Mystery {rarity.id}`,
		rarity = rarity.id,
		incomeFactor = 1,
		model = "placeholder",
		reference = "",
		disabled = false,
	})
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	placeholders = table.freeze(placeholders),
})
