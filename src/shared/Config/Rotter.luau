--!strict
-- The Rotter (§4.6). Penalty and minimum players live in Game.luau with the other §8 values.

return table.freeze({
	ABILITIES = table.freeze({
		disableDefence = table.freeze({ cooldown = 45, duration = 20, range = 12 }),
		openGate = table.freeze({ cooldown = 60, duration = 10, range = 10 }),
		lureFeral = table.freeze({ cooldown = 30, range = 40 }),
	}),
	CLUE_FOOTPRINT_LIFETIME = 25, -- purple footprints fade after this many seconds
	CLUE_FOOTPRINT_INTERVAL = 0.5,
	CORRECT_VOTE_BONUS = 150,
	ROTTER_ESCAPE_BONUS = 400, -- paid when the vote is wrong or has no majority
})
