--!strict
-- What a player owns that changes gameplay numbers. Defaults until MonetizationService (Phase 8) fills these in,
-- so economy code never has to know about game passes directly.

local Entitlements = {}

type Provider = {
	extraSlotTiers: (Player) -> number,
	incomeMultiplier: (Player) -> number,
	hasAutoCollect: (Player) -> boolean,
	luck: (Player) -> number,
}

local provider: Provider = {
	extraSlotTiers = function(_)
		return 0
	end,
	incomeMultiplier = function(_)
		return 1
	end,
	hasAutoCollect = function(_)
		return false
	end,
	luck = function(_)
		return 1
	end,
}

function Entitlements.setProvider(p: Provider)
	provider = p
end

function Entitlements.extraSlotTiers(player: Player): number
	return provider.extraSlotTiers(player)
end

function Entitlements.incomeMultiplier(player: Player): number
	return provider.incomeMultiplier(player)
end

function Entitlements.hasAutoCollect(player: Player): boolean
	return provider.hasAutoCollect(player)
end

function Entitlements.luck(player: Player): number
	return provider.luck(player)
end

return Entitlements
