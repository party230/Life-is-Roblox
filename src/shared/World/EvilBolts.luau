--!strict
-- Red lightning for the Evil variant (D36): pure geometry, no Instances. The client re-strikes bolts every
-- few frames around each Evil brainrot (BrainrotAnimator); the headless preview draws one strike.
-- Segments are in the Root's local space (Root is centred on the model, `size` = Root.Size).

local EvilBolts = {}

export type Segment = { cframe: CFrame, length: number }

local SEGMENTS_PER_BOLT = 7
local FORK_SEGMENTS = 3

-- Thin-part CFrame from a to b (explicit basis: Lune's CFrame.lookAt disagrees with Roblox, D29).
local function segment(a: Vector3, b: Vector3): Segment
	local d = b - a
	local len = d.Magnitude
	local z = d.Unit
	local ref = if math.abs(z.Y) < 0.95 then Vector3.yAxis else Vector3.xAxis
	local x = ref:Cross(z).Unit
	local y = z:Cross(x)
	return { cframe = CFrame.fromMatrix((a + b) / 2, x, y, z), length = len }
end

-- One strike: `count` jagged bolts that start on an ellipsoid around the model and crawl around it,
-- each with a short fork. `rng` returns numbers in [0, 1).
function EvilBolts.strike(rng: () -> number, size: Vector3, count: number): { Segment }
	local out: { Segment } = {}
	local half = size / 2 + Vector3.new(0.6, 0.4, 0.6)
	local step = math.max(0.35, math.max(size.X, size.Y, size.Z) * 0.11)
	for _ = 1, count do
		local theta = rng() * math.pi * 2
		local y = (rng() * 2 - 1) * 0.8
		local r = math.sqrt(1 - y * y)
		local p = Vector3.new(math.cos(theta) * r * half.X, y * half.Y, math.sin(theta) * r * half.Z)
		-- crawl roughly along the surface (tangent) with jitter
		local dir = Vector3.new(-math.sin(theta), (rng() * 2 - 1) * 1.2, math.cos(theta)).Unit
		local points = { p }
		for _ = 1, SEGMENTS_PER_BOLT do
			local jitter = Vector3.new(rng() * 2 - 1, rng() * 2 - 1, rng() * 2 - 1) * 0.9
			dir = (dir + jitter).Unit
			p += dir * step
			table.insert(points, p)
		end
		for i = 1, #points - 1 do
			table.insert(out, segment(points[i], points[i + 1]))
		end
		local f = points[math.floor(#points / 2)]
		local fdir = (dir + Vector3.new(rng() * 2 - 1, rng() * 2 - 1, rng() * 2 - 1)).Unit
		for _ = 1, FORK_SEGMENTS do
			local nextPoint = f + fdir * step * 0.7
			table.insert(out, segment(f, nextPoint))
			f = nextPoint
			fdir = (fdir + Vector3.new(rng() * 2 - 1, rng() * 2 - 1, rng() * 2 - 1) * 0.8).Unit
		end
	end
	return out
end

-- Max segments one strike can return (for pooling parts).
function EvilBolts.maxSegments(count: number): number
	return count * (SEGMENTS_PER_BOLT + FORK_SEGMENTS)
end

return EvilBolts
