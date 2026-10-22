--!strict
-- Brainrot card (owner view, approved v3 nursery mockup's right side): opened from the "Feed" prompt on your own
-- brainrots or from the Nursery screen. Shows the growth stage track, the loyalty bar (with its income multiplier),
-- the runaway timer as one long bar (green -> yellow at 25% -> red at 10%), and feeding: pick a food you own,
-- feed xN, preview the gains. Plus Move to pedestal (nursery / storage) and the Bond Collar toggle (pass).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Growth = require(ReplicatedStorage.Shared.Logic.Growth)
local Loyalty = require(ReplicatedStorage.Shared.Logic.Loyalty)
local OwnerStatus = require(ReplicatedStorage.Shared.World.OwnerStatus)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local Button = require(script.Parent.Button)
local Pill = require(script.Parent.Pill)
local Store = require(script.Parent.Parent.Store)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

local WIDTH, HEIGHT = 760, 480

local function bar(scope: Scope, y: number, fill: any, color: any, track: Color3): Instance
	return scope:New("Frame")({
		BackgroundColor3 = track,
		Position = UDim2.fromOffset(190, y),
		Size = UDim2.fromOffset(WIDTH - 230, 22),
		[Fusion.Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			scope:New("UIStroke")({ Color = Theme.ink, Thickness = 3 }),
			scope:New("Frame")({
				BackgroundColor3 = color,
				Size = scope:Computed(function(use)
					return UDim2.fromScale(math.clamp(use(fill), 0, 1), 1)
				end),
				Visible = scope:Computed(function(use)
					return use(fill) > 0
				end),
				[Fusion.Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
			}),
		},
	})
end

local function BrainrotCard(scope: Scope, store: Store.Store): Instance
	local selected = scope:Computed(function(use): Types.PublicBrainrot?
		local id = use(store.cardBrainrot)
		if not id then
			return nil
		end
		for _, b in use(store.brainrots) do
			if b.id == id then
				return b
			end
		end
		return nil
	end)
	local foodPick = scope:Value("" :: string)
	local qty = scope:Value(1)
	local owned = scope:Computed(function(use): { string }
		local list: { string } = {}
		for _, food in Config.Food.list do
			if (use(store.food)[food.id] or 0) > 0 then
				table.insert(list, food.id)
			end
		end
		return list
	end)
	local currentFood = scope:Computed(function(use): Config.FoodDef?
		local list = use(owned)
		local pick = use(foodPick)
		if table.find(list, pick) then
			return Config.Food.byId[pick]
		end
		return if list[1] then Config.Food.byId[list[1]] else nil
	end)
	local have = scope:Computed(function(use)
		local f = use(currentFood)
		return if f then use(store.food)[f.id] or 0 else 0
	end)
	local function cycleFood(dir: number)
		local list = Fusion.peek(owned)
		if #list == 0 then
			return
		end
		local f = Fusion.peek(currentFood)
		local i = if f then table.find(list, f.id) or 1 else 1
		foodPick:set(list[((i - 1 + dir) % #list) + 1])
		qty:set(1)
	end
	local timerFraction = scope:Computed(function(use)
		local b = use(selected)
		use(store.now)
		if not b or b.timerFullDays <= 0 then
			return 0
		end
		return Store.timerNow(b, use(store.snapshotAt), use(store.dayLength)) / b.timerFullDays
	end)
	local close = function()
		store.cardBrainrot:set(nil)
	end
	local textColor = Theme.ink

	return scope:New("Frame")({
		Name = "BrainrotCard",
		BackgroundColor3 = Color3.fromHex("#0B0A1E"),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = scope:Computed(function(use)
			return use(selected) ~= nil
		end),
		ZIndex = 20,
		[Fusion.Children] = {
			scope:New("TextButton")({
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Fusion.OnEvent("Activated")] = close,
			}),
			Pill(scope, {
				size = UDim2.fromOffset(WIDTH, HEIGHT),
				anchor = Vector2.new(0.5, 0.5),
				position = UDim2.new(0.5, 0, 0.5, 20),
				color = Theme.panel,
				radius = 28,
				strokeThickness = 5,
				children = {
					Button(scope, {
						size = Vector2.new(60, 60),
						anchor = Vector2.new(0.5, 0.5),
						position = UDim2.new(1, -8, 0, 8),
						color = Theme.red,
						text = "✕",
						textSize = 28,
						onClick = close,
					}),
					-- header
					Text(scope, {
						text = scope:Computed(function(use)
							local b = use(selected)
							local s = b and Config.Species.byId[b.speciesId]
							return if s then s.displayName else ""
						end),
						size = 34,
						color = textColor,
						outline = false,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(30, 22),
					}),
					Text(scope, {
						text = scope:Computed(function(use)
							local b = use(selected)
							if not b then
								return ""
							end
							local variant = if b.variant ~= "Normal" then `{b.variant} · ` else ""
							return `{variant}{b.rarity} · {b.stage} · {Format.perSec(b.incomePerSec)}`
						end),
						size = 20,
						body = true,
						color = Theme.muted,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(32, 66),
					}),
					-- growth
					Text(scope, {
						text = "Growth",
						size = 20,
						color = textColor,
						outline = false,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(30, 108),
					}),
					bar(
						scope,
						112,
						scope:Computed(function(use)
							local b = use(selected)
							if not b then
								return 0
							end
							return b.growth / Config.Nursery.ADULT_GROWTH
						end),
						Theme.green,
						Color3.fromHex("#E8E1D3")
					),
					Text(scope, {
						text = scope:Computed(function(use)
							local b = use(selected)
							if not b then
								return ""
							end
							local nextStage, need = Growth.toNext(b.growth)
							if not nextStage then
								return "Adult (x1 $/s)"
							end
							local stage = Growth.stageFor(b.growth)
							return `{stage.id} x{stage.incomeMult} $/s · {math.ceil(need)} growth to {nextStage.id}`
						end),
						size = 15,
						body = true,
						color = textColor,
						position = UDim2.fromOffset(190 + (WIDTH - 230) / 2, 112),
						anchor = Vector2.new(0.5, 0),
					}),
					-- loyalty (owner only)
					Text(scope, {
						text = "♥ Loyalty",
						size = 20,
						color = Theme.pink,
						outline = false,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(30, 152),
					}),
					bar(
						scope,
						156,
						scope:Computed(function(use)
							local b = use(selected)
							return if b then b.loyalty / Config.Loyalty.MAX else 0
						end),
						Theme.pink,
						Color3.fromHex("#3A1630")
					),
					Text(scope, {
						text = scope:Computed(function(use)
							local b = use(selected)
							if not b then
								return ""
							end
							return `{math.floor(b.loyalty + 0.5)} · x{string.format(
								"%.2g",
								Loyalty.incomeMult(b.loyalty)
							)} $/s`
						end),
						size = 15,
						body = true,
						color = Theme.white,
						position = UDim2.fromOffset(190 + (WIDTH - 230) / 2, 156),
						anchor = Vector2.new(0.5, 0),
					}),
					-- runaway timer (owner only): one long bar, no numbers
					Text(scope, {
						text = "Runaway timer",
						size = 20,
						color = textColor,
						outline = false,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(30, 196),
					}),
					bar(
						scope,
						200,
						timerFraction,
						scope:Computed(function(use)
							return OwnerStatus.timerColor(use(timerFraction))
						end),
						Color3.fromHex("#1E2A22")
					),
					Text(scope, {
						text = scope:Computed(function(use)
							local b = use(selected)
							if b and b.leaving then
								return "Leaving tonight! Feed it to make it stay."
							end
							if b and b.bondCollared then
								return "Bond Collar: timer paused"
							end
							return "Only you can see these bars. Feeding refills the timer."
						end),
						size = 15,
						body = true,
						color = Theme.muted,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(190, 228),
					}),
					-- feeding
					Pill(scope, {
						size = UDim2.fromOffset(WIDTH - 60, 110),
						position = UDim2.fromOffset(30, 262),
						color = Theme.white,
						radius = 20,
						children = {
							Button(scope, {
								size = Vector2.new(44, 50),
								position = UDim2.fromOffset(10, 28),
								color = Theme.blue,
								text = "◀",
								textSize = 22,
								onClick = function()
									cycleFood(-1)
								end,
							}),
							Text(scope, {
								text = scope:Computed(function(use)
									local f = use(currentFood)
									return if f then f.displayName else "No food yet: visit the Food Shop"
								end),
								size = 22,
								color = textColor,
								outline = false,
								position = UDim2.fromOffset(186, 26),
								anchor = Vector2.new(0.5, 0),
							}),
							Text(scope, {
								text = scope:Computed(function(use)
									local f = use(currentFood)
									return if f then `You have {use(have)}` else ""
								end),
								size = 15,
								body = true,
								color = Theme.muted,
								position = UDim2.fromOffset(186, 60),
								anchor = Vector2.new(0.5, 0),
							}),
							Button(scope, {
								size = Vector2.new(44, 50),
								position = UDim2.fromOffset(318, 28),
								color = Theme.blue,
								text = "▶",
								textSize = 22,
								onClick = function()
									cycleFood(1)
								end,
							}),
							Button(scope, {
								size = Vector2.new(44, 50),
								position = UDim2.fromOffset(380, 28),
								color = Theme.white,
								text = "−",
								textSize = 26,
								onClick = function()
									qty:set(math.max(1, Fusion.peek(qty) - 1))
								end,
							}),
							Text(scope, {
								text = scope:Computed(function(use)
									return `x{use(qty)}`
								end),
								size = 26,
								color = textColor,
								outline = false,
								position = UDim2.fromOffset(458, 34),
								anchor = Vector2.new(0.5, 0),
							}),
							Button(scope, {
								size = Vector2.new(44, 50),
								position = UDim2.fromOffset(494, 28),
								color = Theme.white,
								text = "+",
								textSize = 26,
								onClick = function()
									local max = math.min(Fusion.peek(have), Config.Food.FEED_MAX_QUANTITY)
									qty:set(math.clamp(Fusion.peek(qty) + 1, 1, math.max(1, max)))
								end,
							}),
							Text(scope, {
								text = scope:Computed(function(use)
									local f = use(currentFood)
									if not f then
										return ""
									end
									local n = use(qty)
									local days = if f.fillsTimer then "fill" else `+{f.days * n}d`
									local loyalty = if f.maxLoyalty then "max" else `+{f.loyalty * n}`
									local growth = if f.instantAdult then "Adult" else `+{f.growth * n}`
									return `⏱ {days}\n♥ {loyalty}\n▲ {growth}`
								end),
								size = 15,
								body = true,
								color = textColor,
								align = Enum.TextXAlignment.Left,
								position = UDim2.fromOffset(570, 22),
							}),
						},
					}),
					-- actions
					Button(scope, {
						size = Vector2.new(300, 62),
						position = UDim2.fromOffset(30, HEIGHT - 86),
						color = Theme.green,
						text = scope:Computed(function(use)
							return `FEED x{use(qty)}`
						end),
						textSize = 28,
						enabled = scope:Computed(function(use)
							return use(currentFood) ~= nil and use(have) >= use(qty)
						end),
						onClick = function()
							local b = Fusion.peek(selected)
							local f = Fusion.peek(currentFood)
							if b and f then
								Remotes.FeedBrainrot:fire(b.id, f.id, Fusion.peek(qty))
								qty:set(1)
							end
						end,
					}),
					Button(scope, {
						size = Vector2.new(230, 62),
						position = UDim2.fromOffset(344, HEIGHT - 86),
						color = Theme.blue,
						text = "To a pedestal",
						textSize = 22,
						visible = scope:Computed(function(use)
							local b = use(selected)
							return b ~= nil and b.slot == nil
						end),
						onClick = function()
							local b = Fusion.peek(selected)
							if b then
								Remotes.MoveToPedestal:fire(b.id)
							end
						end,
					}),
					Button(scope, {
						size = Vector2.new(150, 62),
						position = UDim2.fromOffset(WIDTH - 180, HEIGHT - 86),
						color = Theme.purple,
						text = scope:Computed(function(use)
							local b = use(selected)
							return if b and b.bondCollared then "Uncollar" else "Collar"
						end),
						textSize = 22,
						visible = scope:Computed(function(use)
							return use(store.collarSlots) > 0
						end),
						onClick = function()
							local b = Fusion.peek(selected)
							if b then
								Remotes.SetCollar:fire(b.id, not b.bondCollared)
							end
						end,
					}),
				},
			}),
		},
	})
end

return BrainrotCard
