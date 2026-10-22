--!strict
-- Bombardiro Crocodilo: a crocodile fused with a military bomber plane: croc head and tail on a fuselage,
-- olive wings with propeller engines, bombs underneath. Hovers instead of walking.
-- Built from the commonly known meme image (no reference in assets/reference yet). No real military insignia.

local Kit = require("../Kit")

local CROC = "#5E8C3C"
local CROC_BELLY = "#BFCF8C"
local OLIVE = "#6E7B4C"
local METAL = "#4A4F57"
local BOMB = "#3B3F45"

return function(): Model
	local k = Kit.new("Bombardiro Crocodilo", 4.4, 4)
	local V = Vector3.new

	k:blob("Fuselage", V(1.9, 1.7, 6.6), V(0, 2.75, 0.3), CROC)
	k:blob("Belly", V(1.6, 1.0, 5.6), V(0, 2.3, 0.3), CROC_BELLY)
	-- back scales
	for i = 0, 4 do
		k:wedge(`Scale{i}`, V(0.35, 0.35, 0.5), V(0, 3.6, -1.2 + i * 0.85), CROC, nil, { role = "detail" })
	end
	-- head: long snout with teeth
	k:blob("Head", V(1.7, 1.2, 1.8), V(0, 2.9, -2.9), CROC)
	k:box("UpperJaw", V(1.3, 0.45, 2.4), V(0, 2.85, -4.6), CROC)
	k:box("LowerJaw", V(1.2, 0.35, 2.3), V(0, 2.3, -4.5), CROC_BELLY)
	k:box("Gum", V(1.1, 0.2, 2.2), V(0, 2.56, -4.5), "#B2453A", { role = "detail" })
	for side = -1, 1, 2 do
		for i = 0, 4 do
			k:wedge(
				`Tooth{side}{i}`,
				V(0.14, 0.22, 0.14),
				V(side * 0.6, 2.5, -3.7 - i * 0.42),
				"#FFFFFF",
				V(180, 0, 0),
				{ role = "detail" }
			)
		end
		k:blob(
			`Nostril{side}`,
			V(0.14, 0.1, 0.14),
			V(side * 0.3, 3.1, -5.65),
			"#2B3A20",
			nil,
			{ role = "detail" }
		)
	end
	-- eyes on top bumps (croc eyes are yellow)
	for side = -1, 1, 2 do
		k:blob(`EyeBump{side}`, V(0.65, 0.55, 0.65), V(side * 0.48, 3.5, -2.85), CROC)
	end
	k:eyes(3.62, 0.48, -3.15, 0.45, "#F2D33A")
	-- tail
	k:blob("Tail", V(0.9, 0.8, 2.6), V(0, 2.8, 4.1), CROC)
	k:wedge("TailFin", V(0.22, 1.5, 1.3), V(0, 3.75, 3.85), OLIVE)
	k:box("Stabilizer", V(3.2, 0.18, 1.0), V(0, 2.9, 4.0), OLIVE)
	-- wings with a little dihedral
	for side = -1, 1, 2 do
		k:box(`Wing{side}`, V(4.2, 0.22, 1.9), V(side * 2.75, 2.85, -0.1), OLIVE, nil, V(0, 0, side * 4))
		k:box(`WingTip{side}`, V(0.5, 0.24, 1.6), V(side * 4.95, 3.0, -0.1), OLIVE, nil, V(0, 0, side * 4))
		-- engine + propeller
		k:rod(`Engine{side}`, 1.6, 0.85, V(side * 2.3, 2.75, -0.9), METAL)
		local hub = k:blob(`PropHub{side}`, V(0.4, 0.4, 0.4), V(side * 2.3, 2.75, -1.8), "#2A2C31")
		local bladeA = k:box(`BladeA{side}`, V(0.14, 1.8, 0.08), V(side * 2.3, 2.75, -1.85), "#22252A")
		local bladeB = k:box(`BladeB{side}`, V(1.8, 0.14, 0.08), V(side * 2.3, 2.75, -1.85), "#22252A")
		k:spinner(hub, 6)
		k:weldTo(bladeA, hub)
		k:weldTo(bladeB, hub)
		-- bomb under the wing
		k:blob(`Bomb{side}`, V(0.55, 0.55, 1.5), V(side * 1.3, 1.9, 0.1), BOMB)
		k:wedge(
			`BombFin{side}`,
			V(0.08, 0.4, 0.35),
			V(side * 1.3, 2.05, 0.95),
			BOMB,
			nil,
			{ role = "detail" }
		)
	end

	return k:finish({ hover = 1.2, idle = "fly" })
end
