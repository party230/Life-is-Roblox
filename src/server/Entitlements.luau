--!strict
-- What a player owns that changes gameplay numbers. Defaults until MonetizationService (Phase 8) fills these in,
-- so economy code never has to know about game passes directly.

local Entitlements = {}

type Provider = {
	extraSlotTiers: (Player) -> number,
	incomeMultiplier: (Player) -> number,
	hasAutoCollect: (Player) -> boolean,
	luck: (Player) -> number,
	incubatorTiers: (Player) -> number,
	hasBondCollar: (Player) -> boolean,
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
	incubatorTiers = function(_)
		return 0
	end,
	hasBondCollar = function(_)
		return false
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

-- Extra Incubator passes owned (0..3).
function Entitlements.incubatorTiers(player: Player): number
	return provider.incubatorTiers(player)
end

function Entitlements.hasBondCollar(player: Player): boolean
	return provider.hasBondCollar(player)
end

return Entitlements
