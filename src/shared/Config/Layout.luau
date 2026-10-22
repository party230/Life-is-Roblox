--!strict
-- World geometry in studs (D38, from the approved v3 design). The hub is at the world origin; 12 bases sit in a
-- ring around it with their gates facing it. Plot-local coordinates: X = right, Z = back; the gate is at local -Z
-- (LookVector, toward the hub).
--
-- Base layout: 14 pedestals in a 4-column grid (12 studs apart so nameplates never touch), the collector by the
-- gate, escape exits in both side walls, and the nursery walled off across the back.

export type Vec2 = { x: number, z: number }

export type SlotDef = {
	x: number,
	z: number,
	tier: number, -- 0 = starting slot, 1..3 = unlocked by Extra Slots I/II/III
}

local Layout = {
	-- Ring
	BASE_COUNT = 12,
	PLOT_FIRST_ANGLE_DEG = 15, -- bases at 15 + 30 * k degrees
	GATE_RADIUS = 230, -- hub centre -> gate: gate to the nearest carpet edge is ~191 studs = ~12 s at WalkSpeed 16
	PLOT_WIDTH = 64, -- local X
	PLOT_DEPTH = 84, -- local Z
	PLOT_RING_RADIUS = 272, -- hub centre -> plot centre (GATE_RADIUS + PLOT_DEPTH / 2)
	MAP_RADIUS = 374,
	FLOOR_TOP = 1, -- plot floor surface height
	WALL_HEIGHT = 12,

	-- Hub (plaza, shared conveyor, stalls)
	HUB_RADIUS = 84,
	HUB_TOP = 0.6, -- plaza floor surface height
	ISLAND_RADIUS = 27, -- grass island inside the carpet loop, with the central portal
	CARPET = table.freeze({
		radius = 34, -- loop centreline
		width = 10,
		startDeg = 8, -- the loop starts just past the ramp from the portal...
		sweepDeg = 330, -- ...and runs counter-clockwise this far, to the exit vortex
		segments = 44,
		rampStart = 8, -- ramp from the portal (x) out to the loop
	}),
	-- Hub features: angle (degrees, 0 = +X) and distance from the centre. Stalls face the centre.
	EGG_SHOP = table.freeze({ deg = -30, radius = 62 }),
	FOOD_SHOP = table.freeze({ deg = 30, radius = 62 }),
	LEADERBOARDS = table.freeze({ deg = 90, radius = 66 }),
	EVENT_STAGE = table.freeze({ deg = 150, radius = 64 }),
	TRADE_ZONE = table.freeze({ deg = 210, radius = 62 }),
	HANGOUT = table.freeze({ deg = 270, radius = 62 }),
	SPOKE_WIDTH = 12,
	RING_ROAD_RADIUS = 214, -- road along the gates
	LANE_INSET = 6, -- escape lanes run at PLOT_RING_RADIUS - LANE_INSET between neighbouring side exits

	-- Base interior
	PEDESTAL_SIZE = 5,
	PEDESTAL_HEIGHT = 1.6,
	SLOTS = table.freeze({
		-- starting 8: the two front corners, the middle row, the inner pair of the third row
		table.freeze({ x = -23, z = -26, tier = 0 }),
		table.freeze({ x = 23, z = -26, tier = 0 }),
		table.freeze({ x = -23, z = -15, tier = 0 }),
		table.freeze({ x = -11, z = -15, tier = 0 }),
		table.freeze({ x = 11, z = -15, tier = 0 }),
		table.freeze({ x = 23, z = -15, tier = 0 }),
		table.freeze({ x = -11, z = -4, tier = 0 }),
		table.freeze({ x = 11, z = -4, tier = 0 }),
		-- Extra Slots I, II, III (+2 each)
		table.freeze({ x = -23, z = -4, tier = 1 }),
		table.freeze({ x = 23, z = -4, tier = 1 }),
		table.freeze({ x = -11, z = 7, tier = 2 }),
		table.freeze({ x = 11, z = 7, tier = 2 }),
		table.freeze({ x = -23, z = 7, tier = 3 }),
		table.freeze({ x = 23, z = 7, tier = 3 }),
	}) :: { SlotDef },
	COLLECTOR = table.freeze({ x = -19, z = -35, width = 8, depth = 5 }),
	GATE = table.freeze({ z = -42, width = 14 }),
	SPAWN = table.freeze({ x = 9, z = -30 }) :: Vec2,
	LANE_EXIT = table.freeze({ zMin = -14, zMax = -4 }), -- in both side walls
	-- Nursery: walled room across the back of the base (door in the middle of its front wall)
	NURSERY = table.freeze({
		zFront = 16,
		doorHalfWidth = 4,
		incubatorZ = 35, -- incubators along the back wall
		incubatorSpacing = 9,
		penZ = 26, -- where babies and teens wander
	}),

	-- Nameplates (§1.4): narrower plates, hidden beyond NAMEPLATE_MAX_DISTANCE (your own stay visible further)
	NAMEPLATE_WIDTH = 5.6,
	NAMEPLATE_LINE = 0.72,
	NAMEPLATE_MAX_DISTANCE = 60,
	NAMEPLATE_OWN_MAX_DISTANCE = 140,
}

return table.freeze(Layout)
