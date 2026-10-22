--!strict
-- Nursery screen (approved v3 mockup), opened from your nursery door or the Base button. Locked: the unlock dialog
-- (cash price that scales with progress, or the Robux skip). Unlocked: incubators (3 + Extra Incubator passes, up
-- to 6) with progress and HATCH, and the pen: your babies and teens. Tap one to open its card (feed, move to a
-- pedestal).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

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
local PASS_KEYS = { "ExtraIncubator1", "ExtraIncubator2", "ExtraIncubator3" }

local function prompt(store: Store.Store, key: string, isPass: boolean)
	local list = if isPass then Config.Products.passByKey else Config.Products.productByKey
	local def = (list :: any)[key]
	if not def or def.id == 0 then
		store.pushToast("info", "Robux purchases aren't set up yet (product ids are placeholders).")
		return
	end
	if isPass then
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, def.id)
	else
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, def.id)
	end
end

local function IncubatorTile(scope: Scope, store: Store.Store, slot: number): Instance
	local egg = scope:Computed(function(use): Types.PublicEgg?
		return use(store.eggs)[slot]
	end)
	local usable = scope:Computed(function(use)
		return slot <= use(store.incubators)
	end)
	local left = scope:Computed(function(use)
		local e = use(egg)
		use(store.now)
		return if e then math.max(0, e.readyAt - os.time()) else 0
	end)
	local ready = scope:Computed(function(use)
		return use(egg) ~= nil and use(left) <= 0
	end)
	local col = (slot - 1) % 2
	local row = (slot - 1) // 2
	return Pill(scope, {
		size = UDim2.fromOffset(250, 104),
		position = UDim2.fromOffset(26 + col * 262, 96 + row * 116),
		radius = 18,
		color = scope:Computed(function(use)
			return if use(usable) then Theme.white else Color3.fromHex("#ECE7DE")
		end),
		stroke = scope:Computed(function(use)
			return if use(ready) then Theme.moneyGreen else Theme.ink
		end),
		children = {
			Pill(scope, {
				size = UDim2.fromOffset(52, 66),
				position = UDim2.fromOffset(14, 18),
				color = scope:Computed(function(use)
					local e = use(egg)
					return if e then EGG_COLORS[e.eggId] or Theme.white else Color3.fromHex("#E2D9C8")
				end),
				visible = usable,
			}),
			Text(scope, {
				text = scope:Computed(function(use)
					if not use(usable) then
						return `🔒 Incubator {slot}`
					end
					local e = use(egg)
					if not e then
						return "Empty"
					end
					local name = Config.Eggs.byId[e.eggId].displayName
					return if use(ready) then `{name} ready!` else `{name} · {Format.clock(use(left))}`
				end),
				size = 17,
				color = Theme.ink,
				outline = false,
				align = Enum.TextXAlignment.Left,
				position = UDim2.fromOffset(78, 18),
			}),
			Button(scope, {
				size = Vector2.new(150, 44),
				position = UDim2.fromOffset(78, 48),
				color = Theme.yellow,
				text = "HATCH!",
				textSize = 22,
				visible = ready,
				onClick = function()
					local e = Fusion.peek(egg)
					if e then
						Remotes.HatchEgg:fire(e.id)
					end
				end,
			}),
			Button(scope, {
				size = Vector2.new(150, 44),
				position = UDim2.fromOffset(78, 48),
				color = Theme.moneyGreen,
				text = scope:Computed(function()
					local key = PASS_KEYS[slot - Config.Nursery.BASE_INCUBATORS]
					local def = key and Config.Products.passByKey[key]
					return if def then `R$ {def.robux} pass` else "Pass"
				end),
				textSize = 18,
				visible = scope:Computed(function(use)
					return not use(usable)
				end),
				onClick = function()
					local key = PASS_KEYS[slot - Config.Nursery.BASE_INCUBATORS]
					if key then
						prompt(store, key, true)
					end
				end,
			}),
		},
	})
end

local function PenTile(scope: Scope, store: Store.Store, index: number): Instance
	local b = scope:Computed(function(use): Types.PublicBrainrot?
		local pen: { Types.PublicBrainrot } = {}
		for _, x in use(store.brainrots) do
			if x.inNursery then
				table.insert(pen, x)
			end
		end
		table.sort(pen, function(p, q)
			return p.id < q.id
		end)
		return pen[index]
	end)
	local col = (index - 1) % 2
	local row = (index - 1) // 2
	return Button(scope, {
		size = Vector2.new(290, 64),
		position = UDim2.fromOffset(580 + col * 300, 96 + row * 72),
		color = Theme.white,
		visible = scope:Computed(function(use)
			return use(b) ~= nil
		end),
		onClick = function()
			local x = Fusion.peek(b)
			if x then
				store.cardBrainrot:set(x.id)
			end
		end,
		children = {
			Text(scope, {
				text = scope:Computed(function(use)
					local x = use(b)
					local s = x and Config.Species.byId[x.speciesId]
					return if x and s then `{x.stage} · {s.displayName}` else ""
				end),
				size = 17,
				color = Theme.ink,
				outline = false,
				position = UDim2.fromScale(0.5, 0.5),
				anchor = Vector2.new(0.5, 0.5),
				zIndex = 3,
			}),
		},
	})
end

local function NurseryPanel(scope: Scope, store: Store.Store): Instance
	local close = function()
		store.nurseryVisible:set(false)
	end
	local unlocked = store.nurseryUnlocked
	local children: { any } = {
		Pill(scope, {
			size = UDim2.fromOffset(380, 70),
			anchor = Vector2.new(0.5, 0.5),
			position = UDim2.new(0.5, 0, 0, 0),
			radius = 24,
			strokeThickness = 5,
			color = Theme.pink,
			children = {
				Text(scope, {
					text = "NURSERY",
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
		-- unlock dialog
		scope:New("Frame")({
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = scope:Computed(function(use)
				return not use(unlocked)
			end),
			[Fusion.Children] = {
				Text(scope, {
					text = "🔒",
					size = 64,
					outline = false,
					position = UDim2.new(0.5, 0, 0, 70),
					anchor = Vector2.new(0.5, 0),
				}),
				Text(scope, {
					text = "Unlock your Nursery",
					size = 34,
					color = Theme.ink,
					outline = false,
					position = UDim2.new(0.5, 0, 0, 160),
					anchor = Vector2.new(0.5, 0),
				}),
				Text(scope, {
					text = "Hatch eggs from the Egg Shop into Babies and feed them all the way to Adults.\nStarts with 3 incubators.",
					size = 18,
					body = true,
					color = Theme.muted,
					width = 700,
					position = UDim2.new(0.5, 0, 0, 210),
					anchor = Vector2.new(0.5, 0),
				}),
				Button(scope, {
					size = Vector2.new(340, 66),
					position = UDim2.new(0.5, -180, 0, 300),
					anchor = Vector2.new(0.5, 0),
					color = Theme.green,
					text = scope:Computed(function(use)
						return `UNLOCK · {Format.price(use(store.nurseryPrice))}`
					end),
					textSize = 26,
					enabled = scope:Computed(function(use)
						return use(store.cash) >= use(store.nurseryPrice)
					end),
					onClick = function()
						Remotes.UnlockNursery:fire()
					end,
				}),
				Button(scope, {
					size = Vector2.new(220, 66),
					position = UDim2.new(0.5, 150, 0, 300),
					anchor = Vector2.new(0.5, 0),
					color = Theme.moneyGreen,
					text = `R$ {(Config.Products.productByKey[Config.Nursery.UNLOCK_ROBUX_PRODUCT] or {
						robux = 0,
					}).robux} Skip`,
					textSize = 24,
					onClick = function()
						prompt(store, Config.Nursery.UNLOCK_ROBUX_PRODUCT, false)
					end,
				}),
				Text(scope, {
					text = "The price grows with your best income so far.",
					size = 15,
					body = true,
					color = Theme.muted,
					position = UDim2.new(0.5, 0, 0, 384),
					anchor = Vector2.new(0.5, 0),
				}),
			},
		}),
		-- open nursery
		scope:New("Frame")({
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = unlocked,
			[Fusion.Children] = (function()
				local kids: { any } = {
					Text(scope, {
						text = scope:Computed(function(use)
							return `Incubators  {#use(store.eggs)} / {use(store.incubators)}`
						end),
						size = 22,
						color = Theme.ink,
						outline = false,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(28, 56),
					}),
					Text(scope, {
						text = scope:Computed(function(use)
							local n = 0
							for _, x in use(store.brainrots) do
								if x.inNursery then
									n += 1
								end
							end
							return `Babies & teens  {n} / {Config.Nursery.PEN_CAPACITY}`
						end),
						size = 22,
						color = Theme.ink,
						outline = false,
						align = Enum.TextXAlignment.Left,
						position = UDim2.fromOffset(582, 56),
					}),
					Text(scope, {
						text = "Eggs from the hub Egg Shop land here. Tap a baby to feed it or move it to a pedestal.",
						size = 15,
						body = true,
						color = Theme.muted,
						align = Enum.TextXAlignment.Left,
						position = UDim2.new(0, 28, 1, -36),
					}),
				}
				for slot = 1, Config.Nursery.MAX_INCUBATORS do
					table.insert(kids, IncubatorTile(scope, store, slot))
				end
				for i = 1, Config.Nursery.PEN_CAPACITY do
					table.insert(kids, PenTile(scope, store, i))
				end
				return kids
			end)(),
		}),
	}
	return scope:New("Frame")({
		Name = "NurseryPanel",
		BackgroundColor3 = Color3.fromHex("#0B0A1E"),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = store.nurseryVisible,
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

return NurseryPanel
