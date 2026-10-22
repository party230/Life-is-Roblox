--!strict
-- Tung Tung Tung Sahur: a standing wooden log with a wide-eyed face, thin arms and legs, holding a wooden bat.
-- Built from the commonly known meme image (no reference in assets/reference yet).

local Kit = require("../Kit")

local WOOD = "#C99560"
local WOOD_DARK = "#9C6B3C"
local BAT = "#8A5A2E"

return function(): Model
	local k = Kit.new("Tung Tung Tung Sahur", 5.8, 3)
	local V = Vector3.new

	k:post("Log", 4.4, 2.5, V(0, 3.4, 0), WOOD, nil, { material = Enum.Material.Wood })
	k:post("TopRing", 0.12, 2.3, V(0, 5.62, 0), WOOD_DARK, nil, { material = Enum.Material.Wood })
	k:post("BottomRing", 0.18, 2.55, V(0, 1.25, 0), WOOD_DARK, nil, { material = Enum.Material.Wood })
	-- face
	k:eyes(4.45, 0.55, -1.12, 0.95)
	for side = -1, 1, 2 do
		k:box(
			`Brow{side}`,
			V(0.8, 0.18, 0.2),
			V(side * 0.55, 5.12, -1.18),
			"#4A2E16",
			{ role = "detail" },
			V(0, 0, side * -8)
		)
	end
	k:blob("Nose", V(0.38, 0.55, 0.35), V(0, 3.95, -1.28), WOOD_DARK)
	k:box("Mouth", V(0.7, 0.14, 0.12), V(0, 3.45, -1.22), "#3A2414", { role = "detail" })
	-- arms (left hangs, right grips the bat in front)
	local wood = { material = Enum.Material.Wood }
	k:limb("ArmL", V(-1.2, 4.0, 0), V(-1.75, 2.5, -0.15), 0.42, WOOD, wood)
	k:blob("HandL", V(0.5, 0.5, 0.5), V(-1.8, 2.35, -0.15), WOOD)
	local handR = V(1.75, 3.0, -1.0)
	k:limb("ArmR", V(1.2, 4.0, -0.2), handR, 0.42, WOOD, wood)
	k:blob("HandR", V(0.52, 0.52, 0.52), handR, WOOD)
	-- wooden bat raised from the right hand: thin handle then a thick barrel
	local batTip = V(2.7, 6.6, 0.4)
	local dir = (batTip - handR).Unit
	local grip = handR - dir * 0.35
	local barrelStart = handR + dir * 1.2
	k:limb("BatHandle", grip, barrelStart, 0.28, BAT, wood)
	k:limb("BatBarrel", barrelStart, batTip, 0.62, BAT, wood)
	k:blob("BatEnd", V(0.62, 0.62, 0.62), batTip, BAT, nil, wood)
	-- legs and feet
	for side = -1, 1, 2 do
		k:post(`Leg{side}`, 1.25, 0.45, V(side * 0.6, 0.62, 0), WOOD, nil, { material = Enum.Material.Wood })
		k:box(
			`Foot{side}`,
			V(0.6, 0.3, 0.9),
			V(side * 0.6, 0.15, -0.18),
			WOOD_DARK,
			{ material = Enum.Material.Wood }
		)
	end

	return k:finish({ idle = "bob" })
end
