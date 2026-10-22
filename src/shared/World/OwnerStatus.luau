--!strict
-- Owner-only rows on top of a brainrot's nameplate (D39, approved mockup): a loyalty bar with a heart, and the
-- runaway timer as one long bar with no text (green, yellow at <= 25%, red at <= 10%, empty = leaving tonight).
-- The owner's client adds these rows locally to the replicated nameplate, so they never replicate and other players
-- never get the data. Pure UI building (no services) so the headless preview draws exactly the same rows.

local Config = require("../Config")

local OwnerStatus = {}

local ROW_LOYALTY = 0.62 -- studs
local ROW_TIMER = 0.5
local ROWS = ROW_LOYALTY + ROW_TIMER

local TRACK_LOYALTY = Color3.fromHex("#3A1630")
local TRACK_TIMER = Color3.fromHex("#1E2A22")
local TRACK_EMPTY = Color3.fromHex("#5A1010")
local GREEN = Color3.fromHex("#3DDC84")
local YELLOW = Color3.fromHex("#FFD23F")
local RED = Color3.fromHex("#FF3B3B")
local HEART = Color3.fromHex("#FF4F7B")

local function loyaltyColor(v: number): Color3
	return Color3.fromHex(if v >= 0.6 then "#FF4F7B" elseif v >= 0.3 then "#FF8FA8" else "#C9A0AE")
end

function OwnerStatus.timerColor(fraction: number): Color3
	if fraction <= Config.Loyalty.TIMER_RED then
		return RED
	elseif fraction <= Config.Loyalty.TIMER_YELLOW then
		return YELLOW
	end
	return GREEN
end

-- A row: transparent container (the nameplate's UIListLayout stacks it) holding a rounded track and its fill.
local function row(
	name: string,
	order: number,
	width: number,
	height: number,
	total: number,
	track: Color3
): Frame
	local container = Instance.new("Frame")
	container.Name = name
	container.LayoutOrder = order
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromScale(width, height / total)
	container:SetAttribute("OwnerOnly", true)
	container:SetAttribute("Bar", 1)
	local trackFrame = Instance.new("Frame")
	trackFrame.Name = "Track"
	trackFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	trackFrame.Position = UDim2.fromScale(0.5, 0.5)
	trackFrame.Size = UDim2.fromScale(1, 0.72)
	trackFrame.BackgroundColor3 = track
	trackFrame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = trackFrame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = trackFrame
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill
	fill.Parent = trackFrame
	trackFrame.Parent = container
	return container
end

-- Adds the rows to a nameplate BillboardGui (idempotent). Rows sit above the existing lines.
function OwnerStatus.attach(gui: BillboardGui)
	if gui:FindFirstChild("OwnerLoyalty") then
		return
	end
	local plate = gui.Size.Y.Scale
	local total = plate + ROWS
	for _, child in gui:GetChildren() do
		if child:IsA("GuiObject") then
			child.Size = UDim2.fromScale(child.Size.X.Scale, child.Size.Y.Scale * plate / total)
		end
	end
	local loyalty = row("OwnerLoyalty", -2, 0.7, ROW_LOYALTY, total, TRACK_LOYALTY)
	loyalty:SetAttribute("Icon", "♥")
	loyalty:SetAttribute("IconColor", HEART)
	local heart = Instance.new("TextLabel")
	heart.Name = "Heart"
	heart.BackgroundTransparency = 1
	heart.AnchorPoint = Vector2.new(1, 0.5)
	heart.Position = UDim2.new(0, -2, 0.5, 0)
	heart.Size = UDim2.fromScale(1, 1.1)
	heart.SizeConstraint = Enum.SizeConstraint.RelativeYY
	heart.Text = "♥"
	heart.TextScaled = true
	heart.TextColor3 = HEART
	heart.Font = Enum.Font.FredokaOne
	heart.Parent = loyalty
	loyalty.Parent = gui
	row("OwnerTimer", -1, 1, ROW_TIMER, total, TRACK_TIMER).Parent = gui
	gui.Size = UDim2.fromScale(gui.Size.X.Scale, total)
	gui.MaxDistance = Config.Layout.NAMEPLATE_OWN_MAX_DISTANCE
end

-- loyalty in 0..1, timerFraction in 0..1 (time left since the last fill).
function OwnerStatus.set(gui: BillboardGui, loyalty: number, timerFraction: number)
	local l = gui:FindFirstChild("OwnerLoyalty") :: Frame?
	local t = gui:FindFirstChild("OwnerTimer") :: Frame?
	if not l or not t then
		return
	end
	local lv = math.clamp(loyalty, 0, 1)
	local tv = math.clamp(timerFraction, 0, 1)
	local lTrack = l:FindFirstChild("Track") :: Frame
	local lf = lTrack:FindFirstChild("Fill") :: Frame
	lf.Size = UDim2.fromScale(lv, 1)
	lf.BackgroundColor3 = loyaltyColor(lv)
	l:SetAttribute("Bar", lv)
	local tTrack = t:FindFirstChild("Track") :: Frame
	local tf = tTrack:FindFirstChild("Fill") :: Frame
	tf.Size = UDim2.fromScale(tv, 1)
	tf.Visible = tv > 0
	tf.BackgroundColor3 = OwnerStatus.timerColor(tv)
	tTrack.BackgroundColor3 = if tv <= 0 then TRACK_EMPTY else TRACK_TIMER
	t:SetAttribute("Bar", tv)
end

return OwnerStatus
