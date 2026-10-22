--!strict
-- Brr Brr Patapim: a tree-trunk creature with a monkey face and long drooping nose, a leafy mossy top,
-- branch arms and big bare feet. Built from the commonly known meme image (no reference yet).

local Kit = require("../Kit")

local BARK = "#6E4A2A"
local BARK_DARK = "#523519"
local FACE = "#D9AE84"
local NOSE = "#D08B6E"
local LEAF = "#4E9A3C"
local LEAF_LIGHT = "#6CBF4D"
local FOOT = "#E2B58C"

return function(): Model
	local k = Kit.new("Brr Brr Patapim", 5.8, 3.2)
	local V = Vector3.new

	k:blob("Trunk", V(2.3, 3.4, 2.0), V(0, 3.0, 0), BARK, nil, { material = Enum.Material.Wood })
	k:blob("Head", V(2.0, 1.9, 1.8), V(0, 4.45, 0), BARK, nil, { material = Enum.Material.Wood })
	-- bark grooves
	for i = -1, 1 do
		k:box(`Groove{i}`, V(0.1, 1.6, 0.1), V(i * 0.55, 2.7, -0.95), BARK_DARK, { role = "detail" })
	end
	-- monkey face with a long drooping nose
	k:blob("Face", V(1.55, 1.3, 0.5), V(0, 4.35, -0.8), FACE)
	k:eyes(4.6, 0.38, -1.05, 0.38)
	k:blob("Nose", V(0.6, 1.25, 0.6), V(0, 3.75, -1.15), NOSE, V(-15, 0, 0))
	k:box("Mouth", V(0.5, 0.1, 0.1), V(0, 3.95, -1.0), "#5A2E1E", { role = "detail" })
	-- leafy, mossy top
	local tufts =
		{ V(0, 5.6, 0), V(-0.7, 5.35, 0.2), V(0.7, 5.35, 0.1), V(0.1, 5.3, 0.75), V(-0.2, 5.4, -0.5) }
	for i, at in tufts do
		k:blob(
			`Leaves{i}`,
			V(1.1, 0.9, 1.1),
			at,
			if i % 2 == 0 then LEAF_LIGHT else LEAF,
			nil,
			{ material = Enum.Material.Grass }
		)
	end
	-- long branch arms reaching down and out, each with a twig and a leaf
	local wood = { material = Enum.Material.Wood }
	for side = -1, 1, 2 do
		local shoulder = V(side * 0.95, 3.7, 0)
		local elbow = V(side * 1.9, 3.3, -0.2)
		local hand = V(side * 2.35, 2.25, -0.35)
		k:limb(`UpperArm{side}`, shoulder, elbow, 0.48, BARK, wood)
		k:limb(`Forearm{side}`, elbow, hand, 0.4, BARK, wood)
		k:blob(`Elbow{side}`, V(0.5, 0.5, 0.5), elbow, BARK)
		for f = -1, 1 do
			k:limb(
				`Finger{side}{f}`,
				hand,
				hand + V(side * 0.2 + f * 0.12, -0.55, -0.15 + f * 0.15),
				0.14,
				BARK_DARK,
				wood
			)
		end
		local twigTip = elbow + V(side * 0.35, 1.0, 0.1)
		k:limb(`Twig{side}`, elbow, twigTip, 0.18, BARK, wood)
		k:blob(`ArmLeaf{side}`, V(0.65, 0.45, 0.65), twigTip + V(0, 0.15, 0), LEAF)
	end
	-- short legs and big bare feet
	for side = -1, 1, 2 do
		k:post(`Leg{side}`, 1.1, 0.6, V(side * 0.6, 0.85, 0), BARK, nil, { material = Enum.Material.Wood })
		k:blob(`Foot{side}`, V(1.15, 0.55, 1.9), V(side * 0.7, 0.28, -0.45), FOOT)
		for t = -1, 1 do
			k:blob(
				`Toe{side}{t}`,
				V(0.28, 0.25, 0.3),
				V(side * 0.7 + t * 0.3, 0.38, -1.38),
				FOOT,
				nil,
				{ role = "detail" }
			)
		end
	end

	return k:finish({ idle = "sway" })
end
