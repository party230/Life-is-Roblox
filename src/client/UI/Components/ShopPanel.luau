--!strict
-- Conveyor shop panel (approved mockup 02): your 5-card belt with payback text, a NEW sticker, can't-afford /
-- sold / base-full states, odds behind the "i", the plaza drop banner, and a closed-for-the-night state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local WeightedRandom = require(ReplicatedStorage.Shared.Util.WeightedRandom)

local Button = require(script.Parent.Button)
local Pill = require(script.Parent.Pill)
local Preview = require(script.Parent.Preview)
local RarityChip = require(script.Parent.RarityChip)
local Store = require(script.Parent.Parent.Store)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

local PANEL = Vector2.new(1060, 512)
local CARD = Vector2.new(182, 300)

local function oddsLine(): string
	local odds = WeightedRandom.odds(Config.Shop.RARITY_WEIGHTS)
	local parts: { string } = {}
	for _, r in Config.Rarities.list do
		local p = odds[r.id]
		if p and p > 0 then
			local pct = p * 100
			local text = if pct >= 1 then string.format("%.0f", pct) else string.format("%.2g", pct)
			table.insert(parts, `{r.id} {text}%`)
		end
	end
	return table.concat(parts, " · ")
end

local function Card(scope: Scope, store: Store.Store, listing: Types.PublicListing, index: number): Instance
	local species = Config.Species.byId[listing.speciesId]
	local rc = Theme.rarity(listing.rarity)
	local closed = scope:Computed(function(use)
		return not use(store.shopOpen)
	end)
	local full = scope:Computed(function(use)
		return use(store.placedCount) >= use(store.slotsUnlocked)
	end)
	local short = scope:Computed(function(use)
		return math.max(0, listing.price - use(store.cash))
	end)
	local buttonText = scope:Computed(function(use)
		if use(closed) then
			return "Dawn"
		elseif listing.sold then
			return "SOLD"
		elseif use(full) then
			return "Base full"
		elseif use(short) > 0 then
			return "Need " .. Format.price(use(short))
		end
		return Format.price(listing.price)
	end)
	local buyable = scope:Computed(function(use)
		return not use(closed) and not listing.sold and not use(full) and use(short) <= 0
	end)

	local children: { any } = {
		scope:New("UICorner")({ CornerRadius = UDim.new(0, 20) }),
		scope:New("UIStroke")({
			Color = Theme.ink,
			Thickness = 4.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		-- stage
		scope:New("Frame")({
			BackgroundColor3 = Theme.lighten(
				if Theme.isRainbowRim(listing.rarity) then Theme.purple else rc,
				0.7
			),
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(162, 132),
			[Fusion.Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0, 14) }),
				Preview(
					scope,
					listing.speciesId,
					listing.rarity,
					listing.variant,
					Vector2.new(162, 132),
					not Fusion.peek(store.shopOpen)
				),
			},
		}),
		RarityChip(scope, listing.rarity, 13, UDim2.fromOffset(12, 14)),
		Text(scope, {
			text = species.displayName,
			size = 24,
			color = Theme.ink,
			outline = false,
			position = UDim2.fromOffset(91, 160),
			anchor = Vector2.new(0.5, 0.5),
		}),
		Text(scope, {
			text = Format.perSec(listing.incomePerSec),
			size = 21,
			color = Theme.moneyGreen,
			outline = false,
			position = UDim2.fromOffset(91, 186),
			anchor = Vector2.new(0.5, 0.5),
		}),
		Text(scope, {
			text = Format.payback(listing.price, listing.incomePerSec),
			size = 15,
			body = true,
			color = Theme.muted,
			position = UDim2.fromOffset(91, 208),
			anchor = Vector2.new(0.5, 0.5),
		}),
		Button(scope, {
			size = Vector2.new(154, 62),
			position = UDim2.fromOffset(14, 228),
			color = Theme.green,
			enabled = buyable,
			text = buttonText,
			textSize = 21,
			onClick = function()
				Remotes.BuyListing:fire(listing.id)
			end,
		}),
	}
	if listing.sold then
		table.insert(
			children,
			scope:New("Frame")({
				BackgroundColor3 = Theme.white,
				BackgroundTransparency = 0.45,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 5,
				[Fusion.Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(0, 20) }) },
			})
		)
	end
	return scope:New("Frame")({
		Name = `Card{index}`,
		BackgroundColor3 = Theme.white,
		Position = UDim2.fromOffset((index - 1) * 200, 0),
		Size = UDim2.fromOffset(CARD.X, CARD.Y),
		[Fusion.Children] = children,
	})
end

local function ShopPanel(scope: Scope, store: Store.Store): Instance
	local isNight = scope:Computed(function(use)
		return not use(store.shopOpen)
	end)
	local fg = scope:Computed(function(use)
		return if use(isNight) then Theme.white else Theme.ink
	end)
	local showOdds = scope:Value(false)
	local close = function()
		store.shopVisible:set(false)
	end

	return scope:New("Frame")({
		Name = "ShopPanel",
		BackgroundColor3 = Color3.fromHex("#0B0A1E"),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = store.shopVisible,
		ZIndex = 10,
		[Fusion.Children] = {
			scope:New("TextButton")({ -- tap outside to close
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Fusion.OnEvent("Activated")] = close,
			}),
			Pill(scope, {
				size = UDim2.fromOffset(PANEL.X, PANEL.Y),
				anchor = Vector2.new(0.5, 0.5),
				position = UDim2.new(0.5, 0, 0.5, 40),
				radius = 28,
				strokeThickness = 5,
				color = scope:Computed(function(use)
					return if use(isNight) then Theme.panelNight else Theme.panel
				end),
				children = {
					-- header ribbon
					Pill(scope, {
						size = UDim2.fromOffset(460, 70),
						anchor = Vector2.new(0.5, 0.5),
						position = UDim2.new(0.5, 0, 0, 0),
						radius = 24,
						strokeThickness = 5,
						color = scope:Computed(function(use)
							return if use(isNight) then Theme.grey else Theme.pink
						end),
						children = {
							Text(scope, {
								text = "ON YOUR CARPET",
								size = 38,
								position = UDim2.fromScale(0.5, 0.5),
								anchor = Vector2.new(0.5, 0.5),
							}),
						},
					}),
					-- close
					Button(scope, {
						size = Vector2.new(68, 68),
						anchor = Vector2.new(0.5, 0.5),
						position = UDim2.new(1, -10, 0, 4),
						color = Theme.red,
						text = "✕",
						textSize = 34,
						onClick = close,
					}),
					-- top row
					Text(scope, {
						text = scope:Computed(function(use)
							if use(isNight) then
								return "Belt stopped for the night"
							end
							return "Next one in " .. Format.clock(use(store.nextRotationAt) - use(store.now))
						end),
						size = 22,
						body = true,
						color = fg,
						position = UDim2.fromOffset(34, 64),
						anchor = Vector2.new(0, 0.5),
					}),
					Text(scope, {
						text = scope:Computed(function(use)
							return `{use(store.placedCount)} / {use(store.slotsUnlocked)} pedestals used`
						end),
						size = 22,
						body = true,
						color = fg,
						position = UDim2.new(1, -34, 0, 64),
						anchor = Vector2.new(1, 0.5),
					}),
					-- belt
					scope:New("Frame")({
						BackgroundColor3 = Theme.belt,
						Position = UDim2.fromOffset(20, 104 + 18),
						Size = UDim2.new(1, -40, 0, 300),
						[Fusion.Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0, 18) }),
							scope:New("UIStroke")({ Color = Theme.ink, Thickness = 4.5 }),
						},
					}),
					scope:New("Frame")({
						BackgroundColor3 = Theme.beltDark,
						Position = UDim2.fromOffset(20, 104 + 322),
						Size = UDim2.new(1, -40, 0, 36),
						[Fusion.Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0, 12) }),
							scope:New("UIStroke")({ Color = Theme.ink, Thickness = 4 }),
						},
					}),
					scope:New("Frame")({
						Name = "Cards",
						BackgroundTransparency = 1,
						ClipsDescendants = true, -- shows the 5 nearest the end of the carpet
						Position = UDim2.fromOffset(40, 104),
						Size = UDim2.new(1, -80, 0, CARD.Y),
						[Fusion.Children] = scope:ForPairs(
							store.listings,
							function(_, inner, i: number, listing: Types.PublicListing)
								return i, Card(inner, store, listing, i)
							end
						),
					}),
					-- closed overlay (night)
					Pill(scope, {
						size = UDim2.fromOffset(600, 140),
						anchor = Vector2.new(0.5, 0.5),
						position = UDim2.new(0.5, 0, 0, 104 + 150),
						radius = 26,
						strokeThickness = 5,
						visible = isNight,
						zIndex = 8,
						children = {
							Text(scope, {
								text = "Closed for the night",
								size = 34,
								color = Theme.ink,
								outline = false,
								position = UDim2.fromOffset(300, 52),
								anchor = Vector2.new(0.5, 0.5),
								zIndex = 9,
							}),
							Text(scope, {
								text = scope:Computed(function(use)
									return "Opens at dawn in "
										.. Format.clock(use(store.phaseEndsAt) - use(store.now))
										.. " · eggs keep hatching"
								end),
								size = 19,
								body = true,
								color = Theme.muted,
								position = UDim2.fromOffset(300, 92),
								anchor = Vector2.new(0.5, 0.5),
								zIndex = 9,
							}),
						},
					}),
					-- odds footer
					Button(scope, {
						size = Vector2.new(44, 44),
						position = UDim2.new(0, 32, 1, -58),
						color = Theme.blue,
						text = "i",
						textSize = 24,
						onClick = function()
							showOdds:set(not Fusion.peek(showOdds))
						end,
					}),
					Text(scope, {
						text = scope:Computed(function(use)
							return if use(showOdds) or use(isNight) then "Odds: " .. oddsLine() else "Odds"
						end),
						size = 17,
						body = true,
						color = fg,
						position = UDim2.new(0, 86, 1, -38),
						anchor = Vector2.new(0, 0.5),
					}),
					-- plaza drop banner
					Pill(scope, {
						size = UDim2.fromOffset(560, 50),
						anchor = Vector2.new(1, 0.5),
						position = UDim2.new(1, -30, 1, -38),
						color = Theme.yellow,
						visible = scope:Computed(function(use)
							return use(store.plazaDrop) ~= nil and not use(showOdds) and not use(isNight)
						end),
						children = {
							scope:New("TextButton")({
								Text = "",
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(1, 1),
								[Fusion.OnEvent("Activated")] = close, -- the world marker shows the way
							}),
							Text(scope, {
								text = scope:Computed(function(use)
									local drop = use(store.plazaDrop)
									if not drop then
										return ""
									end
									local species = Config.Species.byId[drop.listing.speciesId]
									local left = Format.clock(drop.endsAt - use(store.now))
									return `PLAZA DROP: {drop.listing.rarity} {species.displayName} · first to buy wins · {left}`
								end),
								size = 18,
								color = Theme.ink,
								outline = false,
								position = UDim2.fromScale(0.5, 0.5),
								anchor = Vector2.new(0.5, 0.5),
							}),
						},
					}),
				},
			}),
		},
	})
end

return ShopPanel
