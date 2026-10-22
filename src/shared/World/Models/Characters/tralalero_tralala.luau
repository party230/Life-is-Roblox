--!strict
-- Tralalero Tralala: a blue-grey shark with a white belly standing on three legs in blue sneakers.
-- Built from the commonly known meme image (no reference in assets/reference yet). No brand logos on the shoes.

local Kit = require("../Kit")

local SKIN = "#6F8FB2"
local BELLY = "#EEF3F6"
local LEG = "#DCE6EE"
local SHOE = "#2667E0"
local SOLE = "#FFFFFF"

return function(): Model
	local k = Kit.new("Tralalero Tralala", 5.0, 3.4)
	local V = Vector3.new

	-- body (first part = Body)
	k:blob("Torso", V(2.5, 2.5, 6.4), V(0, 3.15, 0), SKIN)
	k:blob("Belly", V(2.25, 1.7, 5.6), V(0, 2.72, -0.1), BELLY)
	k:blob("Snout", V(2.0, 1.75, 2.0), V(0, 3.0, -2.95), SKIN)
	k:blob("Chin", V(1.7, 0.9, 1.6), V(0, 2.5, -2.8), BELLY)
	-- mouth with a row of little teeth
	k:box("Mouth", V(1.45, 0.14, 0.12), V(0, 2.62, -3.72), "#3A2526", { role = "detail" }, V(0, 0, 0))
	for i = -2, 2 do
		k:wedge(
			`Tooth{i}`,
			V(0.16, 0.18, 0.1),
			V(i * 0.26, 2.52, -3.75),
			"#FFFFFF",
			V(180, 0, 0),
			{ role = "detail" }
		)
	end
	k:eyes(3.45, 0.86, -2.55, 0.42)
	-- gills
	for side = -1, 1, 2 do
		for i = 0, 2 do
			k:box(
				`Gill{side}{i}`,
				V(0.06, 0.75, 0.08),
				V(side * 1.22, 3.05, -1.65 + i * 0.32),
				"#4E6A88",
				{ role = "detail" }
			)
		end
	end
	-- fins
	k:wedge("DorsalFin", V(0.3, 1.7, 1.7), V(0, 4.85, 0.35), SKIN)
	for side = -1, 1, 2 do
		k:wedge(`PectoralFin{side}`, V(0.25, 0.9, 1.5), V(side * 1.45, 2.6, -0.9), SKIN, V(0, 0, side * 60))
	end
	-- tail: stem + upper and lower lobes
	k:blob("TailStem", V(0.9, 1.0, 1.8), V(0, 3.2, 3.25), SKIN)
	k:wedge("TailTop", V(0.28, 1.9, 1.3), V(0, 4.15, 4.0), SKIN, V(-20, 0, 0))
	k:wedge("TailBottom", V(0.28, 1.2, 1.0), V(0, 2.45, 3.9), SKIN, V(200, 0, 0))

	-- three legs in blue sneakers
	local legs = { V(-0.85, 0, -1.25), V(0.85, 0, -1.25), V(0, 0, 1.45) }
	for i, at in legs do
		k:post(`Leg{i}`, 1.9, 0.7, at + V(0, 1.45, 0), LEG)
		k:box(`Shoe{i}`, V(0.95, 0.55, 1.45), at + V(0, 0.42, -0.22), SHOE)
		k:box(`Sole{i}`, V(1.0, 0.18, 1.5), at + V(0, 0.09, -0.22), SOLE)
		k:box(`Laces{i}`, V(0.5, 0.08, 0.5), at + V(0, 0.72, -0.4), SOLE, { role = "detail" })
	end

	return k:finish({ idle = "bob" })
end
