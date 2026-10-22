--!strict
-- The owner's view of a brainrot, sent only in that player's own DataSnapshot / HatchResult. It carries the
-- owner-private fields (loyalty, runaway timer, collar), so never send it to anyone else (D39).

local Growth = require("../Logic/Growth")
local Income = require("../Logic/Income")
local Types = require("../Types")

local Public = {}

function Public.brainrot(b: Types.Brainrot, slot: number?): Types.PublicBrainrot
	return {
		id = b.id,
		speciesId = b.speciesId,
		rarity = b.rarity,
		variant = b.variant,
		incomePerSec = Income.effective(b),
		isStolen = b.isStolen,
		slot = slot,
		stage = Growth.stage(b).id,
		growth = b.growth,
		inNursery = b.inNursery,
		loyalty = b.loyalty,
		timerDays = b.timerDays,
		timerFullDays = b.timerFullDays,
		leaving = b.leaving,
		bondCollared = b.bondCollared,
	}
end

return Public
