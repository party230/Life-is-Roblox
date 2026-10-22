--!strict
-- MonetizationService (D39 subset; the full store is Phase 8): game-pass ownership feeding Entitlements, and an
-- idempotent ProcessReceipt for the v3 dev products (Nursery Unlock skip, Robux food bundles).
-- Rules (owner): nothing purchasable stops stealing, reveals other players' loyalty, or guarantees catching a
-- runaway. Product ids in Config/Products are placeholders (0) until they're created in the Creator Dashboard.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Template = require(ReplicatedStorage.Shared.Data.Template)

local Entitlements = require(script.Parent.Parent.Entitlements)
local DataService = require(script.Parent.DataService)
local FoodService = require(script.Parent.FoodService)
local NurseryService = require(script.Parent.NurseryService)

local MonetizationService = {}

local P = Config.Products
local owned: { [Player]: { [string]: boolean } } = {}

local function owns(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

local function refreshPasses(player: Player)
	local passes: { [string]: boolean } = owned[player] or {}
	owned[player] = passes
	for _, def in P.gamePasses do
		if def.id ~= 0 and not passes[def.key] then
			local ok, has =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, def.id)
			passes[def.key] = ok and has == true
		end
	end
	-- incubators / collar slots may have changed
	NurseryService.refresh(player)
	DataService.sendSnapshot(player)
end

local function countTiers(player: Player, keys: { string }): number
	local n = 0
	for _, key in keys do
		if owns(player, key) then
			n += 1
		end
	end
	return n
end

-- Grants a dev product to a loaded player. Returns false if it can't be granted yet.
local function grant(player: Player, key: string): boolean
	if key == Config.Nursery.UNLOCK_ROBUX_PRODUCT then
		return NurseryService.grantUnlock(player)
	end
	local foodId, bundle = string.match(key, "^Food_(.+)_(%d+)$")
	if foodId and bundle then
		return FoodService.grant(player, foodId, tonumber(bundle) :: number)
	end
	return false -- other products arrive with the full store (Phase 8)
end

local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and DataService.get(player)
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local receiptId = tostring(receipt.PurchaseId)
	if table.find(data.grantedReceipts, receiptId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted (idempotent)
	end
	local key: string? = nil
	for _, def in P.devProducts do
		if def.id ~= 0 and def.id == receipt.ProductId then
			key = def.key
			break
		end
	end
	if not key or not grant(player, key) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.grantedReceipts, receiptId)
	while #data.grantedReceipts > Template.MAX_RECEIPT_HISTORY do
		table.remove(data.grantedReceipts, 1)
	end
	DataService.save(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.init()
	Entitlements.setProvider({
		extraSlotTiers = function(player)
			return countTiers(player, { "ExtraSlots1", "ExtraSlots2", "ExtraSlots3" })
		end,
		incomeMultiplier = function(player)
			return if owns(player, "DoubleIncome") then P.DOUBLE_INCOME_MULT else 1
		end,
		hasAutoCollect = function(player)
			return owns(player, "AutoCollect")
		end,
		luck = function(_)
			return 1
		end,
		incubatorTiers = function(player)
			return countTiers(player, P.INCUBATOR_PASSES)
		end,
		hasBondCollar = function(player)
			return owns(player, "BondCollar")
		end,
	})
end

function MonetizationService.start()
	MarketplaceService.ProcessReceipt = processReceipt
	Players.PlayerAdded:Connect(function(player)
		task.spawn(refreshPasses, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(refreshPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, def in P.gamePasses do
			if def.id == passId then
				local passes = owned[player] or {}
				owned[player] = passes
				passes[def.key] = true
			end
		end
		NurseryService.refresh(player)
		DataService.sendSnapshot(player)
	end)
end

return MonetizationService
