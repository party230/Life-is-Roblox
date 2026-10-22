--!strict
-- Core tunables from the design spec (§8). All balance numbers live in Config; never hard-code them in logic.
-- Times are in seconds unless the name says otherwise.

local Game = {
	-- Cycle
	DAY_LENGTH = 480,
	DUSK = 20,
	NIGHT_LENGTH = 240,
	DAWN_VOTE = 30,

	-- Economy
	START_CASH = 100,
	START_SLOTS = 8,
	MAX_SLOTS = 14, -- START_SLOTS + 3 Extra Slot passes x 2
	BASE_INCOME_PER_SEC = 1, -- multiplied by species factor, rarity and mutation
	OFFLINE_RATE = 0.25,
	OFFLINE_CAP_HOURS = 4,

	-- Escape run
	ESCAPE_BASE_SPEED = 10,
	ESCAPE_SPEED_PER_SEC = 1,
	ESCAPE_SPEED_CAP = 32,

	-- Loyalty
	LOYALTY_MAX = 100,
	LOYALTY_PER_MIN = 0.5,
	LOYALTY_DAILY_TIME_CAP = 30,
	LOYALTY_FEED = 5,
	LOYALTY_PET = 2,
	LOYALTY_PET_COOLDOWN = 60,
	NIGHT_DEFENCE_LOYALTY = 10,
	NEGLECT_AFTER_MIN = 60,
	NEGLECT_DECAY_PER_10MIN = 2,
	LOYALTY_SPEED_DIVISOR = 200,
	CARRY_SPEED_FLOOR = 0.5,
	DEFECT_SCALAR = 0.004,
	OLD_LOYALTY_DECAY_PER_NIGHT = 10,
	ROGUE_THRESHOLD = 10,
	ROGUE_TIME_MIN = 30,

	-- Rotter
	ROTTER_MIN_PLAYERS = 5,
	ROTTER_CASH_PENALTY = 0.15,

	-- Gate / shield
	GATE_CLOSE_SECONDS = 15,
	GATE_COOLDOWN = 90,
	SHIELD_POST_COOLDOWN = 120,

	-- Server
	MAX_PLAYERS = 8,

	-- Vertical slice (Phase 1 redo): one base, plaza stall, carpet spawns only characters that have models,
	-- and the world builds a single plot. Set false once the slice is approved.
	VERTICAL_SLICE = true,
	REQUIRE_BUILT_MODELS = true, -- only characters with a model can spawn (others wait for art)
	STUDIO_DEV_CASH = 1_000_000, -- Studio only (separate DataStore): top cash up to this on join

	-- Joining / plots
	PLOT_COUNT = 8,
	PLOT_PICK_SECONDS = 10, -- auto-assign (next to a friend if possible) if the player hasn't picked
	NIGHT_JOIN_SHIELD = true, -- PROPOSED (Q11): a base claimed at night is shielded until dawn

	-- Camera: third-person follow cam with a zoom-out cap so players can't scout the whole map
	CAMERA_MIN_ZOOM = 6,
	CAMERA_MAX_ZOOM = 38,

	-- Storage for brainrots that don't fit on a pedestal (hatched while the base is full)
	STORAGE_SLOTS = 20,

	-- Collecting cash: how close (studs, horizontal) the player must be to their collector pad
	COLLECT_RADIUS = 7,
	INCOME_TICK_SECONDS = 1,

	-- Escape run (Phase 3)
	PLAZA_SHORTCUT_RESETS_SPEED = true, -- cutting through the plaza resets the +1 stack to base speed
	PLAZA_SHORTCUT_ALERTS_OWNER = true, -- the carried brainrot glows and its owner is told
	LANE_EXITS_SEAL_AT_DUSK = true, -- and ferals only walk on open ground
}

return table.freeze(Game)
