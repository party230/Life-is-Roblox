--!strict
-- Ballerina Cappuccina: a ballerina in a pink tutu on pointe, arms raised in an arch, with a cappuccino cup
-- for a head. Built from the commonly known meme image (no reference in assets/reference yet).
-- Small eyes on the cup are added so variants (e.g. Dark's red eyes) have something to change.

local Kit = require("../Kit")

local SKIN = "#F2C7A5"
local TUTU = "#FFB3D1"
local TUTU_LIGHT = "#FFD3E5"
local BODICE = "#FF86B5"
local CUP = "#FFFFFF"
local COFFEE = "#7A4A24"
local FOAM = "#F3E2C3"

return function(): Model
	local k = Kit.new("Ballerina Cappuccina", 6.6, 2.8)
	local V = Vector3.new

	k:box("Bodice", V(1.0, 1.3, 0.65), V(0, 3.35, 0), BODICE)
	k:post("Tutu", 0.32, 3.4, V(0, 2.62, 0), TUTU)
	k:post("TutuTop", 0.22, 2.6, V(0, 2.84, 0), TUTU_LIGHT)
	-- legs on pointe
	for side = -1, 1, 2 do
		k:post(`Leg{side}`, 2.25, 0.36, V(side * 0.28, 1.45, 0), SKIN)
		k:box(`Shoe{side}`, V(0.36, 0.45, 0.42), V(side * 0.28, 0.22, 0), TUTU)
		k:box(`Ribbon{side}`, V(0.38, 0.08, 0.44), V(side * 0.28, 0.62, 0), BODICE, { role = "detail" })
	end
	-- arms raised into an arch over the cup (ballet fifth position)
	for side = -1, 1, 2 do
		local shoulder = V(side * 0.55, 3.9, 0)
		local elbow = V(side * 1.25, 5.0, 0)
		local hand = V(side * 0.22, 6.35, 0)
		k:limb(`UpperArm{side}`, shoulder, elbow, 0.3, SKIN)
		k:limb(`Forearm{side}`, elbow, hand, 0.27, SKIN)
		k:blob(`Elbow{side}`, V(0.3, 0.3, 0.3), elbow, SKIN)
		k:blob(`Hand{side}`, V(0.32, 0.32, 0.32), hand, SKIN)
	end
	k:post("Neck", 0.4, 0.42, V(0, 4.15, 0), SKIN)
	-- cappuccino cup head
	k:post("Cup", 1.35, 1.7, V(0, 4.95, 0), CUP)
	k:post("CupRim", 0.1, 1.78, V(0, 5.62, 0), CUP)
	k:post("Coffee", 0.08, 1.55, V(0, 5.6, 0), COFFEE)
	k:post("Foam", 0.1, 1.05, V(0, 5.63, 0), FOAM, nil, { role = "detail" })
	k:box("HandleTop", V(0.45, 0.16, 0.2), V(1.05, 5.2, 0), CUP)
	k:box("HandleSide", V(0.16, 0.6, 0.2), V(1.22, 4.95, 0), CUP)
	k:box("HandleBottom", V(0.45, 0.16, 0.2), V(1.05, 4.7, 0), CUP)
	k:eyes(5.0, 0.32, -0.82, 0.28)
	k:box("Smile", V(0.36, 0.08, 0.06), V(0, 4.68, -0.86), "#C0566E", { role = "detail" })

	return k:finish({ idle = "twirl" })
end
