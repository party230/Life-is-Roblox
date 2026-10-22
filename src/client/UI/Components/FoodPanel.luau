--!strict
-- Food Shop screen (approved v3 mockup), opened from the hub Food Shop stall. Tabs Snacks / Meals / Feasts / Premium,
-- a quantity toggle (x1/x5/x10 cash, x1/x5 Robux), one card per food with its timer / loyalty / growth gains,
-- a "Best for you" badge (owner answer 5) and your inventory along the bottom. Robux foods prompt a dev product
-- (MonetizationService grants them).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FoodShop = require(ReplicatedStorage.Shared.Logic.FoodShop)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Button = require(script.Parent.Button)
local Pill = require(script.Parent.Pill)
local Store = require(script.Parent.Parent.Store)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

-- Placeholder glyphs until food art is uploaded.
local GLYPHS: { [string]: string } = {
	breadstick = "🥖",
	olive = "🫒",
	crust = "🍕",
	slice = "🍕",
	knots = "🧄",
	spaghetti = "🍝",
	sub = "🥪",
	lasagna = "🍲",
	risotto = "🍚",
	gelato = "🍨",
	tiramisu = "🍰",
	cannolo = "🥐",
	truffle = "🍝",
	banquet = "🍗",
	crate = "📦",
	royal = "👑",
	espresso = "☕",
	nonna = "📜",
}

local CARD = Vector2.new(206, 300)

local function chip(scope: Scope, text: string, color: Color3, x: number, y: number): Instance
	return Pill(scope, {
		size = UDim2.fromOffset(0, 24),
		automaticSize = Enum.AutomaticSize.X,
		position = UDim2.fromOffset(x, y),
		color = color,
		strokeThickness = 2,
		radius = 10,
		children = {
			scope:New("UIPadding")({ PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
			Text(
				scope,
				{ text = text, size = 14, body = true, color = Theme.ink, position = UDim2.fromOffset(0, 1) }
			),
		},
	})
end

local function gains(food: Config.FoodDef): (string, string, string)
	local days = if food.fillsTimer then "Fills timer" else `+{food.days}d`
	local loyalty = if food.maxLoyalty then "Max" else `+{food.loyalty}`
	local growth = if food.instantAdult then "Adult!" else `+{food.growth}`
	return `⏱ {days}`, `♥ {loyalty}`, `▲ {growth}`
end

local function promptRobux(store: Store.Store, foodId: string, bundle: number)
	local key = FoodShop.productKey(foodId, bundle)
	local product = Config.Products.productByKey[key]
	if not product or product.id == 0 then
		store.pushToast("info", "Robux food isn't set up yet (dev product ids are placeholders).")
		return
	end
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.id)
end

local function Card(
	scope: Scope,
	store: Store.Store,
	food: Config.FoodDef,
	slot: number,
	tab: any,
	qty: any
): Instance
	local t1, t2, t3 = gains(food)
	local best = scope:Computed(function(use)
		return FoodShop.bestFor(use(store.perSec)) == food.id
	end)
	local cashText = scope:Computed(function(use)
		return Format.price((food.cash or 0) * use(qty))
	end)
	local robuxText = scope:Computed(function(use)
		local bundle = if use(qty) >= 5 then 5 else 1
		return `R$ {FoodShop.robuxPrice(food, bundle) or 0}`
	end)
	local children: { any } = {
		scope:New("UICorner")({ CornerRadius = UDim.new(0, 20) }),
		scope:New("UIStroke")({
			Color = Theme.ink,
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Text(scope, {
			text = GLYPHS[food.id] or "🍽",
			size = 56,
			outline = false,
			position = UDim2.new(0.5, 0, 0, 14),
			anchor = Vector2.new(0.5, 0),
		}),
		Text(scope, {
			text = food.displayName,
			size = 20,
			color = Theme.ink,
			outline = false,
			width = CARD.X - 16,
			position = UDim2.new(0.5, 0, 0, 96),
			anchor = Vector2.new(0.5, 0),
		}),
		chip(scope, t1, Color3.fromHex("#E1F0FF"), 10, 130),
		chip(scope, t2, Color3.fromHex("#FFE1EA"), 82, 130),
		chip(scope, t3, Color3.fromHex("#E7FCEF"), 10, 160),
		-- Best for you
		Pill(scope, {
			size = UDim2.fromOffset(130, 26),
			anchor = Vector2.new(0.5, 0.5),
			position = UDim2.new(0.5, 0, 0, 0),
			color = Theme.yellow,
			strokeThickness = 3,
			visible = best,
			zIndex = 3,
			children = {
				Text(scope, {
					text = "BEST FOR YOU",
					size = 15,
					color = Theme.ink,
					outline = false,
					position = UDim2.fromScale(0.5, 0.5),
					anchor = Vector2.new(0.5, 0.5),
					zIndex = 3,
				}),
			},
		}),
	}
	local buttonY = CARD.Y - 64
	if food.robux and food.cash then
		buttonY = CARD.Y - 116
	end
	if food.cash then
		table.insert(
			children,
			Button(scope, {
				size = Vector2.new(CARD.X - 20, 50),
				position = UDim2.fromOffset(10, buttonY),
				color = Theme.green,
				text = cashText,
				textSize = 24,
				enabled = scope:Computed(function(use)
					return use(store.cash) >= (food.cash or 0) * use(qty)
				end),
				onClick = function()
					Remotes.BuyFood:fire(food.id, Fusion.peek(qty))
				end,
			})
		)
		buttonY += 54
	end
	if food.robux then
		table.insert(
			children,
			Button(scope, {
				size = Vector2.new(CARD.X - 20, 50),
				position = UDim2.fromOffset(10, buttonY),
				color = Theme.moneyGreen,
				text = robuxText,
				textSize = 24,
				onClick = function()
					promptRobux(store, food.id, if Fusion.peek(qty) >= 5 then 5 else 1)
				end,
			})
		)
	end
	return scope:New("Frame")({
		Name = food.id,
		BackgroundColor3 = Theme.white,
		Position = UDim2.fromOffset(26 + (slot - 1) * (CARD.X + 12), 112),
		Size = UDim2.fromOffset(CARD.X, CARD.Y),
		Visible = scope:Computed(function(use)
			return use(tab) == food.tab
		end),
		[Fusion.Children] = children,
	})
end

local function FoodPanel(scope: Scope, store: Store.Store): Instance
	local tab = scope:Value("Snacks")
	local qty = scope:Value(1)
	local close = function()
		store.foodVisible:set(false)
	end
	local children: { any } = {
		Pill(scope, {
			size = UDim2.fromOffset(380, 70),
			anchor = Vector2.new(0.5, 0.5),
			position = UDim2.new(0.5, 0, 0, 0),
			radius = 24,
			strokeThickness = 5,
			color = Theme.orange,
			children = {
				Text(scope, {
					text = "FOOD SHOP",
					size = 38,
					position = UDim2.fromScale(0.5, 0.5),
					anchor = Vector2.new(0.5, 0.5),
				}),
			},
		}),
		Button(scope, {
			size = Vector2.new(68, 68),
			anchor = Vector2.new(0.5, 0.5),
			position = UDim2.new(1, -10, 0, 4),
			color = Theme.red,
			text = "✕",
			textSize = 32,
			onClick = close,
		}),
	}
	-- tabs
	for i, name in Config.Food.TABS do
		table.insert(
			children,
			Button(scope, {
				size = Vector2.new(if name == "Premium" then 150 else 124, 48),
				position = UDim2.fromOffset(26 + (i - 1) * 134, 50),
				color = scope:Computed(function(use)
					if use(tab) == name then
						return if name == "Premium" then Theme.moneyGreen else Theme.yellow
					end
					return Theme.white
				end),
				text = if name == "Premium" then "R$ Premium" else name,
				textSize = 20,
				onClick = function()
					tab:set(name)
					if name == "Premium" and Fusion.peek(qty) > 5 then
						qty:set(5)
					end
				end,
			})
		)
	end
	-- quantity toggle
	for i, q in Config.Food.CASH_QUANTITIES do
		table.insert(
			children,
			Button(scope, {
				size = Vector2.new(70, 48),
				position = UDim2.new(1, -26 - (#Config.Food.CASH_QUANTITIES - i + 1) * 76, 0, 50),
				color = scope:Computed(function(use)
					return if use(qty) == q then Theme.blue else Theme.white
				end),
				text = `x{q}`,
				textSize = 20,
				visible = scope:Computed(function(use)
					return use(tab) ~= "Premium" or table.find(Config.Food.ROBUX_QUANTITIES, q) ~= nil
				end),
				onClick = function()
					qty:set(q)
				end,
			})
		)
	end
	-- cards (one per food, shown on its tab)
	local slotInTab: { [string]: number } = {}
	for _, food in Config.Food.list do
		slotInTab[food.tab] = (slotInTab[food.tab] or 0) + 1
		table.insert(children, Card(scope, store, food, slotInTab[food.tab], tab, qty))
	end
	-- inventory strip
	table.insert(
		children,
		Pill(scope, {
			size = UDim2.new(1, -52, 0, 44),
			position = UDim2.new(0, 26, 1, -60),
			color = Color3.fromHex("#F4ECDD"),
			strokeThickness = 0,
			radius = 16,
			children = {
				Text(scope, {
					text = scope:Computed(function(use)
						local parts: { string } = {}
						for _, food in Config.Food.list do
							local n = use(store.food)[food.id]
							if n and n > 0 then
								table.insert(parts, `{GLYPHS[food.id] or ""} {food.displayName} x{n}`)
							end
						end
						if #parts == 0 then
							return "Your food: nothing yet. Feed brainrots from their pedestal, the nursery or Inspect."
						end
						return "Your food: " .. table.concat(parts, "  ·  ")
					end),
					size = 17,
					body = true,
					color = Theme.ink,
					align = Enum.TextXAlignment.Left,
					position = UDim2.fromOffset(16, 10),
				}),
			},
		})
	)
	return scope:New("Frame")({
		Name = "FoodPanel",
		BackgroundColor3 = Color3.fromHex("#0B0A1E"),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = store.foodVisible,
		ZIndex = 10,
		[Fusion.Children] = {
			scope:New("TextButton")({
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Fusion.OnEvent("Activated")] = close,
			}),
			Pill(scope, {
				size = UDim2.fromOffset(1180, 512),
				anchor = Vector2.new(0.5, 0.5),
				position = UDim2.new(0.5, 0, 0.5, 30),
				color = Theme.panel,
				radius = 30,
				strokeThickness = 5,
				children = children,
			}),
		},
	})
end

return FoodPanel
