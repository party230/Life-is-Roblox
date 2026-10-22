--!strict
-- World geometry in studs (approved map + base layout mockups). The plaza is at the world origin; 8 plots sit
-- in a ring facing it. Plot-local coordinates: X = right, Z = back. The plot's front (gate) faces the plaza,
-- which is local -Z (Roblox LookVector).

export type Vec2 = { x: number, z: number }

export type SlotDef = {
	x: number,
	z: number,
	tier: number, -- 0 = starting slot, 1..3 = unlocked by Extra Slots I/II/III
}

local Layout = {
	MAP_SIZE = 640,
	PLAZA_RADIUS = 60,
	RING_ROAD_RADIUS = 80,
	RING_ROAD_WIDTH = 16,
	PLOT_RING_RADIUS = 180, -- plaza centre -> plot centre
	PLOT_FIRST_ANGLE_DEG = 22.5, -- plots at 22.5 + 45 * k degrees
	PLOT_WIDTH = 48, -- local X
	PLOT_DEPTH = 40, -- local Z
	WALL_HEIGHT = 3,

	PEDESTAL_SIZE = 4,
	PEDESTAL_HEIGHT = 1.4,
	-- Slot 1..14. Rows from the back wall forward. Tiers follow the base layout mockup.
	SLOTS = table.freeze({
		table.freeze({ x = -13.5, z = 6.5, tier = 0 }),
		table.freeze({ x = -4.5, z = 6.5, tier = 0 }),
		table.freeze({ x = 4.5, z = 6.5, tier = 0 }),
		table.freeze({ x = 13.5, z = 6.5, tier = 0 }),
		table.freeze({ x = -13.5, z = -0.5, tier = 0 }),
		table.freeze({ x = -4.5, z = -0.5, tier = 0 }),
		table.freeze({ x = 4.5, z = -0.5, tier = 0 }),
		table.freeze({ x = 13.5, z = -0.5, tier = 0 }),
		table.freeze({ x = -13.5, z = -7.5, tier = 1 }),
		table.freeze({ x = -4.5, z = -7.5, tier = 1 }),
		table.freeze({ x = 4.5, z = -7.5, tier = 2 }),
		table.freeze({ x = 13.5, z = -7.5, tier = 2 }),
		table.freeze({ x = -13.5, z = -13.5, tier = 3 }),
		table.freeze({ x = 13.5, z = -13.5, tier = 3 }),
	}) :: { SlotDef },

	COLLECTOR = table.freeze({ x = 0, z = -15, width = 10, depth = 5 }),
	GATE = table.freeze({ z = -20, width = 12 }),
	CONVEYOR = table.freeze({ z = 16, length = 38, depth = 4.5 }),
	SPAWN = table.freeze({ x = 0, z = -10 }) :: Vec2,
	-- Temporary egg stand (in-world prompts) until the Eggs screen is approved and built.
	EGG_STAND = table.freeze({ x = -19, z = -15 }) :: Vec2,
	LANE_EXIT = table.freeze({ zMin = -6, zMax = 2 }), -- gap in the right (+X) wall, Phase 3

	-- Plaza
	PLAZA_DROP_BELT = table.freeze({ x = -32, z = -24 }) :: Vec2,
	PLAZA_SPAWN = table.freeze({ x = 0, z = 30 }) :: Vec2,
}

return table.freeze(Layout)
