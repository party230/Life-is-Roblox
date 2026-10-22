--!strict
-- Plot placement maths (pure numbers so it's testable outside the engine). Plots face the plaza at the origin.
-- yaw follows Roblox's CFrame.Angles(0, yaw, 0): LookVector = (-sin yaw, 0, -cos yaw).

local Config = require("../Config")

export type Pose = { x: number, z: number, yaw: number }

local Plots = {}

function Plots.pose(index: number): Pose
	local L = Config.Layout
	local theta = math.rad(L.PLOT_FIRST_ANGLE_DEG + (index - 1) * (360 / Config.Game.PLOT_COUNT))
	return {
		x = math.cos(theta) * L.PLOT_RING_RADIUS,
		z = math.sin(theta) * L.PLOT_RING_RADIUS,
		yaw = math.pi / 2 - theta,
	}
end

-- Plot-local (x, z) -> world (x, z).
function Plots.toWorld(pose: Pose, lx: number, lz: number): (number, number)
	local c = math.cos(pose.yaw)
	local s = math.sin(pose.yaw)
	return pose.x + lx * c + lz * s, pose.z - lx * s + lz * c
end

-- World (x, z) -> plot-local (x, z).
function Plots.toLocal(pose: Pose, wx: number, wz: number): (number, number)
	local dx = wx - pose.x
	local dz = wz - pose.z
	local c = math.cos(pose.yaw)
	local s = math.sin(pose.yaw)
	return dx * c - dz * s, dx * s + dz * c
end

-- Indices adjacent in the ring (for "next to a friend").
function Plots.neighbours(index: number): (number, number)
	local n = Config.Game.PLOT_COUNT
	return ((index - 2) % n) + 1, (index % n) + 1
end

return Plots
