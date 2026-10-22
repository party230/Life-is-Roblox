--!strict
-- Visual tokens from the approved mockups. UI is laid out in "design px" on a 1440x664 landscape phone canvas
-- and scaled to the real screen by App (see DESIGN_HEIGHT).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Theme = {
	DESIGN_HEIGHT = 664,
	DESIGN_WIDTH = 1440,

	ink = Color3.fromHex("#1B1530"),
	white = Color3.fromHex("#FFFFFF"),
	yellow = Color3.fromHex("#FFD23F"),
	green = Color3.fromHex("#3DDC84"),
	moneyGreen = Color3.fromHex("#2BB673"),
	blue = Color3.fromHex("#4DA3FF"),
	pink = Color3.fromHex("#FF5C8A"),
	purple = Color3.fromHex("#8B5CF6"),
	orange = Color3.fromHex("#FF8A3D"),
	red = Color3.fromHex("#FF4D4D"),
	grey = Color3.fromHex("#A8AFBF"),
	muted = Color3.fromHex("#6B7285"),
	panel = Color3.fromHex("#FFF8EC"),
	panelNight = Color3.fromHex("#2A2752"),
	belt = Color3.fromHex("#3A3F55"),
	beltDark = Color3.fromHex("#2B2F42"),

	display = Font.fromEnum(Enum.Font.FredokaOne),
	body = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold),

	-- Cycle bar segment colours: Day, Dusk, Night, DawnVote
	cycleColors = {
		Day = Color3.fromHex("#FFD23F"),
		Dusk = Color3.fromHex("#FF8A3D"),
		Night = Color3.fromHex("#5B5FC7"),
		DawnVote = Color3.fromHex("#FF5C8A"),
	},
}

function Theme.darken(c: Color3, t: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), t)
end

function Theme.lighten(c: Color3, t: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), t)
end

function Theme.rarity(rarity: string): Color3
	local def = Config.Rarities.byId[rarity]
	return if def then Color3.fromHex(def.color) else Theme.grey
end

function Theme.isRainbowRim(rarity: string): boolean
	local def = Config.Rarities.byId[rarity]
	return def ~= nil and def.style == "rainbowRim"
end

return Theme
