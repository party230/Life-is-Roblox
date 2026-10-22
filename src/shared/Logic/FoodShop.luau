--!strict
-- Food shop pricing (D39): cash for any quantity, Robux in x1 / x5 bundles (x5 is 10% off, owner answer 1),
-- the "Best for you" pick (owner answer 5), and inventory changes.

local Config = require("../Config")
local Types = require("../Types")

local FoodShop = {}

local F = Config.Food

function FoodShop.cashPrice(food: Config.FoodDef, quantity: number): number?
	return if food.cash then food.cash * quantity else nil
end

-- Robux price of a bundle (1 or 5).
function FoodShop.robuxPrice(food: Config.FoodDef, bundle: number): number?
	if not food.robux then
		return nil
	end
	if bundle <= 1 then
		return food.robux
	end
	return math.floor(food.robux * bundle * (1 - F.ROBUX_BUNDLE_DISCOUNT))
end

-- Dev product key for a food bundle (Config/Products lists one per Robux food and bundle size).
function FoodShop.productKey(foodId: string, bundle: number): string
	return `Food_{foodId}_{bundle}`
end

function FoodShop.isValidCashQuantity(q: number): boolean
	return table.find(F.CASH_QUANTITIES, q) ~= nil
end

-- The priciest cash food costing at most BEST_FOR_YOU_INCOME_SECONDS of income; the cheapest if none qualifies.
function FoodShop.bestFor(incomePerSec: number): string
	local budget = incomePerSec * F.BEST_FOR_YOU_INCOME_SECONDS
	local bestId, bestPrice = nil :: string?, -1
	local cheapestId, cheapestPrice = F.list[1].id, math.huge
	for _, food in F.list do
		local price = food.cash
		if price then
			if price < cheapestPrice then
				cheapestId, cheapestPrice = food.id, price
			end
			if price <= budget and price > bestPrice then
				bestId, bestPrice = food.id, price
			end
		end
	end
	return bestId or cheapestId
end

function FoodShop.count(data: Types.PlayerData, foodId: string): number
	return data.food[foodId] or 0
end

-- Adds food to the inventory (capped). Returns how many were actually added.
function FoodShop.add(data: Types.PlayerData, foodId: string, quantity: number): number
	local have = FoodShop.count(data, foodId)
	local added = math.max(0, math.min(quantity, F.INVENTORY_CAP - have))
	if added > 0 then
		data.food[foodId] = have + added
	end
	return added
end

-- Takes food out of the inventory. Returns false (nothing changed) if there isn't enough.
function FoodShop.take(data: Types.PlayerData, foodId: string, quantity: number): boolean
	local have = FoodShop.count(data, foodId)
	if quantity <= 0 or have < quantity then
		return false
	end
	local left = have - quantity
	if left > 0 then
		data.food[foodId] = left
	else
		data.food[foodId] = nil
	end
	return true
end

return FoodShop
