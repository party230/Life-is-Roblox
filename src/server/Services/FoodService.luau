--!strict
-- Food (D39): buy with cash at the hub Food Shop (Robux foods are granted by MonetizationService through `grant`),
-- keep it in your inventory, and feed it to your brainrots (pedestal / incubator prompt or the brainrot card).
-- Each feed stacks timer days (capped), loyalty and growth (Logic/Loyalty.feed). The Food Shop stays open at night:
-- feeding is how you stop a brainrot from leaving.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FoodShop = require(ReplicatedStorage.Shared.Logic.FoodShop)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Growth = require(ReplicatedStorage.Shared.Logic.Growth)
local Loyalty = require(ReplicatedStorage.Shared.Logic.Loyalty)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Builder = require(script.Parent.Parent.World.Builder)
local BrainrotService = require(script.Parent.BrainrotService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local FoodService = {}

local SHOP_RADIUS = 30 -- studs from the Food Shop counter

local function nearShop(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - Builder.hub().foodCounter.Position).Magnitude <= SHOP_RADIUS
end

function FoodService.buy(player: Player, foodId: string, quantity: number): boolean
	local data = DataService.get(player)
	local food = Config.Food.byId[foodId]
	if not data or not food then
		return false
	end
	local price = FoodShop.cashPrice(food, quantity)
	if not price or not FoodShop.isValidCashQuantity(quantity) then
		return false -- Robux-only food, or a quantity the shop doesn't sell
	end
	if not nearShop(player) then
		Remotes.Notify:fireClient(player, "warn", "Visit the Food Shop in the hub to buy food.")
		return false
	end
	if FoodShop.count(data, foodId) + quantity > Config.Food.INVENTORY_CAP then
		Remotes.Notify:fireClient(player, "warn", "You can't carry any more of that.")
		return false
	end
	if not EconomyService.spend(player, price) then
		Remotes.Notify:fireClient(player, "warn", "Not enough cash yet.")
		return false
	end
	FoodShop.add(data, foodId, quantity)
	DataService.sendSnapshot(player)
	Remotes.Notify:fireClient(
		player,
		"good",
		`Bought {quantity}x {food.displayName} for {Format.cash(price)}.`
	)
	return true
end

-- Robux purchases (MonetizationService, after ProcessReceipt).
function FoodService.grant(player: Player, foodId: string, quantity: number): boolean
	local data = DataService.get(player)
	local food = Config.Food.byId[foodId]
	if not data or not food then
		return false
	end
	FoodShop.add(data, foodId, quantity)
	DataService.sendSnapshot(player)
	Remotes.Notify:fireClient(player, "good", `{quantity}x {food.displayName} added to your food!`)
	return true
end

function FoodService.feed(player: Player, brainrotId: string, foodId: string, quantity: number): boolean
	local data = DataService.get(player)
	local food = Config.Food.byId[foodId]
	local b = data and data.brainrots[brainrotId]
	if not data or not food or not b or b.ownerUserId ~= player.UserId then
		return false
	end
	if not FoodShop.take(data, foodId, quantity) then
		Remotes.Notify:fireClient(player, "warn", `You don't have {quantity}x {food.displayName}.`)
		return false
	end
	local stageBefore = Growth.stage(b).id
	local gained = Loyalty.feed(b, food, quantity, os.time())
	BrainrotService.sync(player) -- rebuilds at a new size if it grew; clears the "leaving" fidget if saved
	if Growth.stage(b).id ~= stageBefore then
		Remotes.Notify:fireClient(player, "good", `Your brainrot grew into a {Growth.stage(b).id}!`)
	end
	DataService.sendSnapshot(player)
	local parts = { `+{Loyalty.formatDays(gained.days)} timer` }
	if gained.loyalty > 0 then
		table.insert(parts, `+{math.floor(gained.loyalty + 0.5)} loyalty`)
	end
	if gained.growth > 0 and stageBefore ~= "Adult" then
		table.insert(parts, `+{math.floor(gained.growth + 0.5)} growth`)
	end
	Remotes.Notify:fireClient(
		player,
		"good",
		`Fed {quantity}x {food.displayName}: {table.concat(parts, ", ")}`
	)
	return true
end

function FoodService.init() end

function FoodService.start()
	Remotes.BuyFood:connect(function(player, foodId, quantity)
		FoodService.buy(player, foodId, quantity)
	end)
	Remotes.FeedBrainrot:connect(function(player, brainrotId, foodId, quantity)
		FoodService.feed(player, brainrotId, foodId, quantity)
	end)
end

return FoodService
