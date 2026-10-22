--!strict
-- World geometry in studs. The plaza is at the world origin; plots sit in a ring facing it.
-- Plot-local coordinates: X = right, Z = back. The plot's front (gate) faces the plaza = local -Z (LookVector).
-- Base layout (vertical slice): spawn portal at the back, red carpet down the middle to the front,
-- pedestals either side, collector by the gate, escape-lane exit in the right wall.

export type Vec2 = { x: number, z: number }

export type SlotDef = {
	x: number,
	z: number,
	tier: number, -- 0 = starting slot, 1..3 = unlocked by Extra Slots I/II/III
}

local Layout = {
	MAP_SIZE = 720,
	PLAZA_RADIUS = 60,
	RING_ROAD_RADIUS = 80,
	RING_ROAD_WIDTH = 16,
	PLOT_RING_RADIUS = 210, -- plaza centre -> plot centre
	PLOT_FIRST_ANGLE_DEG = 22.5, -- plots at 22.5 + 45 * k degrees
	PLOT_WIDTH = 56, -- local X
	PLOT_DEPTH = 60, -- local Z
	FLOOR_TOP = 1, -- plot floor surface height
	WALL_HEIGHT = 4,

	PEDESTAL_SIZE = 5,
	PEDESTAL_HEIGHT = 1.6,
	SLOTS = table.freeze({
		-- inner columns: the 8 starting slots
		table.freeze({ x = -11, z = 18, tier = 0 }),
		table.freeze({ x = -11, z = 9, tier = 0 }),
		table.freeze({ x = -11, z = 0, tier = 0 }),
		table.freeze({ x = -11, z = -9, tier = 0 }),
		table.freeze({ x = 11, z = 18, tier = 0 }),
		table.freeze({ x = 11, z = 9, tier = 0 }),
		table.freeze({ x = 11, z = 0, tier = 0 }),
		table.freeze({ x = 11, z = -9, tier = 0 }),
		-- outer columns: Extra Slots I, II, III (+2 each)
		table.freeze({ x = -20, z = 18, tier = 1 }),
		table.freeze({ x = 20, z = 18, tier = 1 }),
		table.freeze({ x = -20, z = 9, tier = 2 }),
		table.freeze({ x = 20, z = 9, tier = 2 }),
		table.freeze({ x = -20, z = 0, tier = 3 }),
		table.freeze({ x = 20, z = 0, tier = 3 }),
	}) :: { SlotDef },

	CARPET = table.freeze({ x = 0, width = 6, zStart = 25, zEnd = -24 }),
	PORTAL = table.freeze({ x = 0, z = 27 }),
	COLLECTOR = table.freeze({ x = -19, z = -19, width = 8, depth = 6 }),
	GATE = table.freeze({ z = -30, width = 14 }),
	SPAWN = table.freeze({ x = 9, z = -20 }) :: Vec2,
	LANE_EXIT = table.freeze({ zMin = -18, zMax = -10 }),
	LANE_BLOCKS = 6, -- floating obby blocks from the exit

	-- Plaza
	PLAZA_DROP_BELT = table.freeze({ x = -32, z = -24 }) :: Vec2,
	PLAZA_SPAWN = table.freeze({ x = 0, z = 30 }) :: Vec2,
	STALL_ANGLE_OFFSET_DEG = 28, -- egg stall sits on the plaza edge, this far round from plot 1's spoke
	STALL_RADIUS = 46,
}

return table.freeze(Layout)
