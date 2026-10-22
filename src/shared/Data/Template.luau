--!strict
-- Default save for a new player. ProfileStore:Reconcile() fills missing keys from this on load.
-- Lives in shared (not server) so the unit tests can load it; it holds no secrets.

local Config = require("../Config")
local Types = require("../Types")

local CURRENT_VERSION = 1

local function create(): Types.PlayerData
	return {
		version = CURRENT_VERSION,
		cash = Config.Game.START_CASH,
		uncollectedCash = 0,
		brainrots = {},
		pedestals = {},
		eggs = {},
		treats = 0,
		lastOnlineAt = 0,
		streak = { count = 0, lastClaimDay = 0 },
		stats = {
			steals = 0,
			timesStolenFrom = 0,
			rottersCaught = 0,
			timesRotter = 0,
			rotterWins = 0,
			nightsSurvived = 0,
			defectionsWon = 0,
			totalEarned = 0,
		},
		settings = { musicVolume = 0.6, sfxVolume = 0.8, reducedMotion = false },
		baseName = "",
		grantedReceipts = {},
		activeBoosts = {},
	}
end

return table.freeze({
	CURRENT_VERSION = CURRENT_VERSION,
	create = create,
	MAX_RECEIPT_HISTORY = 100,
})
