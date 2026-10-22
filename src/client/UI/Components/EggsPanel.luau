--!strict
-- Eggs screen (mockup 08), opened from the hub Egg Shop or the Eggs button. Left: cash eggs with odds always
-- visible (colour bar + list). Right: your nursery's incubators with progress and a HATCH button when ready
-- (eggs need an unlocked nursery, D39; the Nursery screen shows every incubator).
-- Buying closes at night; incubators keep running and can still hatch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local WeightedRandom = require(ReplicatedStorage.Shared.Util.WeightedRandom)

local Button = require(script.Parent.Button)
local Pill = require(script.Parent.Pill)
local Store = require(script.Parent.Parent.Store)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

type Scope = Fusion.Scope<typeof(Fusion)>

local EGG_COLORS: { [string]: Color3 } = {
	basic = Color3.fromHex("#FFF4E0"),
	fancy = Color3.fromHex("#B98CFF"),
	streak = Color3.fromHex("#FFD23F"),
	streak7 = Color3.fromHex("#FFD23F"),
}

local function pct(p: number): string
	local v = p * 100
	return if v >= 1 then string.format("%.0f%%", v) else string.format("%.2g%%", v)
end

local function EggCard(
	scope: Scope,
	store: Store.Store,
	def: typeof(Config.Eggs.list[1]),
	index: number,
	isNight: any
): Instance
	local odds = WeightedRandom.odds(def.rarityWeights :: any)
	local bar: { Instance } = {}
	local list: { Instance } = {}
	local x = 0
	local shown = 0
	for _, r in Config.Rarities.list do
		local p = odds[r.id]
		if p and p > 0 then
			local w = math.max(3, p * 240)
			table.insert(
				bar,
				scope:New("Frame")({
					BackgroundColor3 = if Theme.isRainbowRim(r.id) then Theme.purple else Theme.rarity(r.id),
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(x, 0),
					Size = UDim2.fromOffset(w, 14),
				})
			)
			x += w
			shown += 1
			table.insert(
				list,
				Text(scope, {
					text = `{r.id} {pct(p)}`,
					size = 13,
					body = true,
					color = Theme.ink,
					align = Enum.TextXAlignment.Left,
					position = UDim2.fromOffset(
						((shown - 1) % 2) * 128 + 18,
						262 + math.floor((shown - 1) / 2) * 20
					),
				})
			)
			table.insert(
				list,
				scope:New("Frame")({
					BackgroundColor3 = Theme.rarity(r.id),
					Position = UDim2.fromOffset(
						((shown - 1) % 2) * 128 + 4,
						266 + math.floor((shown - 1) / 2) * 20
					),
					Size = UDim2.fromOffset(11, 11),
					[Fusion.Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
				})
			)
		end
	end
	local price = def.cashPrice or 0
	local children: { any } = {
		scope:New("UICorner")({ CornerRadius = UDim.new(0, 22) }),
		scope:New("UIStroke")({
			Color = Theme.ink,
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		-- egg (placeholder shape until egg art lands)
		Pill(scope, {
			size = UDim2.fromOffset(96, 120),
			anchor = Vector2.new(0.5, 0),
			position = UDim2.new(0.5, 0, 0, 24),
			color = EGG_COLORS[def.id] or Theme.white,
		}),
		Text(scope, {
			text = def.displayName,
			size = 28,
			color = Theme.ink,
			outline = false,
			position = UDim2.new(0.5, 0, 0, 178),
			anchor = Vector2.new(0.5, 0.5),
		}),
		Text(scope, {
			text = `Hatches in {Format.duration(def.hatchSeconds)}`,
			size = 16,
			body = true,
			color = Theme.muted,
			position = UDim2.new(0.5, 0, 0, 204),
			anchor = Vector2.new(0.5, 0.5),
		}),
		scope:New("Frame")({
			BackgroundColor3 = Theme.ink,
			Position = UDim2.fromOffset(20, 222),
			Size = UDim2.fromOffset(240, 14),
			ClipsDescendants = true,
			[Fusion.Children] = bar,
		}),
		Button(scope, {
			size = Vector2.new(240, 62),
			position = UDim2.new(0, 20, 1, -76),
			color = Theme.green,
			enabled = scope:Computed(function(use)
				return not use(isNight)
					and use(store.nurseryUnlocked)
					and use(store.cash) >= price
					and #use(store.eggs) < use(store.incubators)
			end),
			text = scope:Computed(function(use)
				if not use(store.nurseryUnlocked) then
					return "Nursery locked"
				end
				return if use(isNight) then "Dawn" else Format.price(price)
			end),
			textSize = 28,
			onClick = function()
				Remotes.BuyEgg:fire(def.id)
			end,
		}),
	}
	for _, item in list do
		table.insert(children, item)
	end
	return scope:New("Frame")({
		Name = `Egg{index}`,
		BackgroundColor3 = Theme.white,
		Position = UDim2.fromOffset(30 + (index - 1) * 300, 100),
		Size = UDim2.fromOffset(280, 380),
		[Fusion.Children] = children,
	})
end

local function Incubator(scope: Scope, store: Store.Store, slot: number): Instance
	local egg = scope:Computed(function(use): Types.PublicEgg?
		return use(store.eggs)[slot]
	end)
	local left = scope:Computed(function(use)
		local e = use(egg)
		if not e then
			return 0
		end
		use(store.now) -- re-evaluate every tick
		return math.max(0, e.readyAt - os.time())
	end)
	local ready = scope:Computed(function(use)
		return use(egg) ~= nil and use(left) <= 0
	end)
	return Pill(scope, {
		size = UDim2.fromOffset(470, 112),
		position = UDim2.fromOffset(640, 100 + (slot - 1) * 128),
		radius = 20,
		stroke = scope:Computed(function(use)
			return if use(ready) then Theme.moneyGreen else Theme.ink
		end),
		children = {
			Pill(scope, {
				size = UDim2.fromOffset(64, 80),
				position = UDim2.fromOffset(24, 16),
				color = scope:Computed(function(use)
					local e = use(egg)
					return if e then EGG_COLORS[e.eggId] or Theme.white else Theme.panel
				end),
			}),
			Text(scope, {
				text = scope:Computed(function(use)
					local e = use(egg)
					if not e then
						return "Free slot · buy an egg"
					end
					local name = Config.Eggs.byId[e.eggId].displayName
					return if use(ready) then `{name} is ready!` else name
				end),
				size = 22,
				color = Theme.ink,
				outline = false,
				align = Enum.TextXAlignment.Left,
				position = UDim2.fromOffset(118, 36),
				anchor = Vector2.new(0, 0.5),
			}),
			-- progress
			scope:New("Frame")({
				BackgroundColor3 = Color3.fromHex("#E2D9C8"),
				Position = UDim2.fromOffset(118, 62),
				Size = UDim2.fromOffset(250, 26),
				Visible = scope:Computed(function(use)
					return use(egg) ~= nil and not use(ready)
				end),
				[Fusion.Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
					scope:New("Frame")({
						BackgroundColor3 = Theme.blue,
						Size = scope:Computed(function(use)
							local e = use(egg)
							if not e then
								return UDim2.fromScale(0, 1)
							end
							local def = Config.Eggs.byId[e.eggId]
							return UDim2.fromScale(math.clamp(1 - use(left) / def.hatchSeconds, 0, 1), 1)
						end),
						[Fusion.Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
					}),
				},
			}),
			Text(scope, {
				text = scope:Computed(function(use)
					return Format.clock(use(left))
				end),
				size = 22,
				color = Theme.ink,
				outline = false,
				visible = scope:Computed(function(use)
					return use(egg) ~= nil and not use(ready)
				end),
				position = UDim2.fromOffset(384, 75),
				anchor = Vector2.new(0, 0.5),
			}),
			Button(scope, {
				size = Vector2.new(330, 50),
				position = UDim2.fromOffset(118, 54),
				color = Theme.yellow,
				text = "HATCH!",
				textSize = 26,
				visible = ready,
				onClick = function()
					local e = Fusion.peek(egg)
					if e then
						Remotes.HatchEgg:fire(e.id)
					end
				end,
			}),
		},
	})
end

local function EggsPanel(scope: Scope, store: Store.Store): Instance
	local isNight = scope:Computed(function(use)
		local p = use(store.phase)
		return p == "Night" or p == "DawnVote"
	end)
	local close = function()
		store.eggsVisible:set(false)
	end
	local cards: { Instance } = {}
	local i = 0
	for _, def in Config.Eggs.list do
		if def.cashPrice then
			i += 1
			table.insert(cards, EggCard(scope, store, def, i, isNight))
		end
	end
	local children: { any } = {
		Pill(scope, {
			size = UDim2.fromOffset(380, 70),
			anchor = Vector2.new(0.5, 0.5),
			position = UDim2.new(0.5, 0, 0, 0),
			radius = 24,
			strokeThickness = 5,
			color = scope:Computed(function(use)
				return if use(isNight) then Theme.grey else Theme.yellow
			end),
			children = {
				Text(scope, {
					text = "EGGS",
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
			textSize = 34,
			onClick = close,
		}),
		Text(scope, {
			text = scope:Computed(function(use)
				return if use(isNight) then "Egg shop closed at night" else "Buy an egg"
			end),
			size = 24,
			color = scope:Computed(function(use)
				return if use(isNight) then Theme.white else Theme.ink
			end),
			outline = false,
			position = UDim2.fromOffset(34, 64),
			anchor = Vector2.new(0, 0.5),
		}),
		Text(scope, {
			text = scope:Computed(function(use)
				if not use(store.nurseryUnlocked) then
					return "Unlock your nursery to hatch eggs"
				end
				return `Nursery incubators  {#use(store.eggs)} / {use(store.incubators)}`
			end),
			size = 24,
			color = scope:Computed(function(use)
				return if use(isNight) then Theme.white else Theme.ink
			end),
			outline = false,
			position = UDim2.fromOffset(640, 64),
			anchor = Vector2.new(0, 0.5),
		}),
	}
	for _, c in cards do
		table.insert(children, c)
	end
	for slot = 1, Config.Nursery.BASE_INCUBATORS do -- the first three here; all of them in the Nursery screen
		table.insert(children, Incubator(scope, store, slot))
	end
	return scope:New("Frame")({
		Name = "EggsPanel",
		BackgroundColor3 = Color3.fromHex("#0B0A1E"),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = store.eggsVisible,
		ZIndex = 10,
		[Fusion.Children] = {
			scope:New("TextButton")({
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Fusion.OnEvent("Activated")] = close,
			}),
			Pill(scope, {
				size = UDim2.fromOffset(1140, 512),
				anchor = Vector2.new(0.5, 0.5),
				position = UDim2.new(0.5, 0, 0.5, 40),
				radius = 28,
				strokeThickness = 5,
				color = scope:Computed(function(use)
					return if use(isNight) then Theme.panelNight else Theme.panel
				end),
				children = children,
			}),
		},
	})
end

return EggsPanel
