--!strict
-- Loyalty and the runaway timer (D39, rework of SPEC §4.4). All timers run in in-game time:
-- 1 in-game day = one full Day -> Dusk -> Night -> DawnVote cycle (Logic/Cycle.length()), and they only tick
-- while the owner is in a server. Loyalty and timers are owner-private: the server never sends them to anyone else.

return table.freeze({
	MAX = 100,
	START = 50, -- loyalty of a brainrot you buy or hatch (x1 income)
	STOLEN_START = 15, -- loyalty toward a thief

	-- Income multiplier from loyalty: piecewise linear through these points (loyalty -> multiplier)
	INCOME_CURVE = table.freeze({
		table.freeze({ 0, 0.5 }),
		table.freeze({ 50, 1 }),
		table.freeze({ 100, 2 }),
	}),

	-- Over time (in-game days, while the owner is online)
	TRICKLE_PER_DAY = 6, -- loyalty gained per in-game day while fed recently
	NEGLECT_AFTER_DAYS = 1, -- not fed for longer than this -> neglected
	NEGLECT_DECAY_PER_DAY = 3, -- loyalty lost per in-game day while neglected

	-- Runaway timer (in-game days)
	TIMER_MIN_DAYS = 2, -- every brainrot gets this the moment it's acquired (bought, hatched, stolen, caught back)
	MAX_TIMER_DAYS = 60, -- feeding stacks up to this cap
	TIMER_YELLOW = 0.25, -- the owner's timer bar turns yellow at or below this fraction of its last fill...
	TIMER_RED = 0.10, -- ...and red at or below this
	RUNAWAY_AT_NIGHT_FRACTION = 0.5, -- "leaving tonight" brainrots run at the middle of the night

	-- Catching a runaway (touch or BONK before it reaches the carpet)
	CATCH_PENALTY = 10,
	CATCH_RADIUS = 5, -- studs, touching
	BONK_RANGE = 8, -- studs, in front of the bat
	RUN_SPEED = 14, -- studs per second (a little slower than a player, so it can be caught)

	-- Stolen brainrots: they remember their loyalty to the original owner
	RETURN_HOME_THRESHOLD = 70, -- at or above, it runs home at the middle of the next night
	OLD_LOYALTY_DECAY_PER_NIGHT = 10,

	-- Bond Collar (game pass): pauses the runaway timer on up to this many brainrots (loyalty doesn't grow)
	COLLAR_MAX = 2,
})
