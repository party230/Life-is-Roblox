--!strict
-- Cappuccino Assassino: a cappuccino cup with a black ninja mask over the eyes, a dark ninja outfit and two
-- katanas. PROVISIONAL: built from the commonly known version; the reference image could not be loaded yet.

local Kit = require("../Kit")

local CUP = "#FFFFFF"
local COFFEE = "#6E3F1E"
local FOAM = "#F3E2C3"
local NINJA = "#1C1C22"
local NINJA_LIGHT = "#2E2E38"
local SASH = "#C8242C"
local BLADE = "#D9DEE6"
local HILT = "#141418"
local GUARD = "#C9A227"

return function(): Model
	local k = Kit.new("Cappuccino Assassino", 5.6, 3)
	local V = Vector3.new

	-- torso and the cup head
	k:box("Torso", V(1.3, 1.5, 0.8), V(0, 2.75, 0), NINJA)
	k:box("Sash", V(1.36, 0.3, 0.86), V(0, 2.15, 0), SASH)
	k:box("SashTail", V(0.3, 0.7, 0.1), V(0.45, 1.85, 0.45), SASH, nil, V(0, 0, 15))
	k:post("Cup", 1.8, 2.1, V(0, 4.45, 0), CUP)
	k:post("CupRim", 0.12, 2.2, V(0, 5.36, 0), CUP)
	k:post("Coffee", 0.08, 1.95, V(0, 5.35, 0), COFFEE)
	k:post("Foam", 0.1, 1.2, V(0, 5.38, 0), FOAM, nil, { role = "detail" })
	-- handle on the right
	k:box("HandleTop", V(0.5, 0.18, 0.22), V(1.25, 4.85, 0), CUP)
	k:box("HandleSide", V(0.18, 0.75, 0.22), V(1.45, 4.5, 0), CUP)
	k:box("HandleBottom", V(0.5, 0.18, 0.22), V(1.25, 4.15, 0), CUP)
	-- ninja mask: a black band around the cup with an eye slit, tails flowing at the back
	k:post("MaskBand", 0.7, 2.18, V(0, 4.6, 0), NINJA)
	k:box("MaskTailL", V(0.18, 0.9, 0.12), V(-0.25, 4.2, 1.15), NINJA, nil, V(20, 0, 10))
	k:box("MaskTailR", V(0.18, 0.9, 0.12), V(0.25, 4.15, 1.2), NINJA, nil, V(28, 0, -12))
	k:box("EyeSlit", V(1.3, 0.38, 0.1), V(0, 4.62, -1.08), "#EDE3D0", { role = "detail" })
	k:eyes(4.62, 0.34, -1.12, 0.3)
	for side = -1, 1, 2 do
		k:box(
			`Brow{side}`,
			V(0.42, 0.1, 0.08),
			V(side * 0.34, 4.83, -1.15),
			"#0A0A0E",
			{ role = "detail" },
			V(0, 0, side * 18)
		)
	end
	-- arms holding a katana in each hand, blades angled outward
	for side = -1, 1, 2 do
		local shoulder = V(side * 0.7, 3.35, 0)
		local hand = V(side * 1.45, 2.55, -0.55)
		k:limb(`Arm{side}`, shoulder, hand, 0.38, NINJA_LIGHT)
		k:blob(`Hand{side}`, V(0.38, 0.38, 0.38), hand, NINJA)
		local tip = hand + V(side * 0.9, 2.4, -0.6)
		local dir = (tip - hand).Unit
		k:limb(`Hilt{side}`, hand - dir * 0.45, hand + dir * 0.25, 0.16, HILT)
		k:limb(`Guard{side}`, hand + dir * 0.25, hand + dir * 0.33, 0.42, GUARD)
		k:limb(`Blade{side}`, hand + dir * 0.33, tip, 0.12, BLADE, { material = Enum.Material.Metal })
	end
	-- legs in a ready stance
	for side = -1, 1, 2 do
		k:limb(`Leg{side}`, V(side * 0.35, 2.05, 0), V(side * 0.62, 0.35, -0.1), 0.42, NINJA_LIGHT)
		k:box(`Foot{side}`, V(0.45, 0.3, 0.75), V(side * 0.62, 0.15, -0.25), NINJA)
	end

	return k:finish({ idle = "sway" })
end
