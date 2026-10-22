--!strict
-- Placeholder shown for characters without a model yet, and for disabled/removed characters:
-- a rarity-coloured mystery crate with "?" faces.

local Kit = require("./Kit")

return function(rarityColor: string): Model
	local k = Kit.new("Mystery", 3.6, 3)
	local V = Vector3.new
	k:box("Crate", V(2.8, 2.8, 2.8), V(0, 1.6, 0), rarityColor, { material = Enum.Material.WoodPlanks })
	for _, edge in { V(1.4, 1.6, 1.4), V(-1.4, 1.6, 1.4), V(1.4, 1.6, -1.4), V(-1.4, 1.6, -1.4) } do
		k:box("Edge", V(0.3, 2.9, 0.3), edge, "#3A2A1A", { role = "detail" })
	end
	k:eyes(1.9, 0.5, -1.45, 0.5)
	local mark = Instance.new("SurfaceGui")
	mark.Face = Enum.NormalId.Top
	mark.PixelsPerStud = 40
	mark.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "?"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = mark
	mark.Parent = k.body
	return k:finish({ idle = "bob" })
end
