--!strict
-- Weighted picks with an injectable RNG so results are testable and seedable.
-- `rng` must return a float in [0, 1). In Roblox: `function() return random:NextNumber() end`.

export type Rng = () -> number

local WeightedRandom = {}

-- Picks a key from a { [key]: weight } map. Iterates keys in sorted order so a given rng sequence is
-- deterministic regardless of hash order. Returns nil if all weights are zero.
function WeightedRandom.pickKey<K>(weights: { [K]: number }, rng: Rng): K?
	local keys: { K } = {}
	local total = 0
	for key, weight in weights do
		if weight > 0 then
			table.insert(keys, key)
			total += weight
		end
	end
	if total <= 0 then
		return nil
	end
	table.sort(keys, function(a: any, b: any)
		return tostring(a) < tostring(b)
	end)
	local roll = rng() * total
	for _, key in keys do
		roll -= weights[key]
		if roll < 0 then
			return key
		end
	end
	return keys[#keys] -- float rounding fallback
end

-- Picks an item from an array, reading each item's weight with `getWeight`.
function WeightedRandom.pickItem<T>(items: { T }, getWeight: (T) -> number, rng: Rng): T?
	local total = 0
	for _, item in items do
		total += math.max(0, getWeight(item))
	end
	if total <= 0 then
		return nil
	end
	local roll = rng() * total
	local last: T? = nil
	for _, item in items do
		local w = math.max(0, getWeight(item))
		if w > 0 then
			last = item
			roll -= w
			if roll < 0 then
				return item
			end
		end
	end
	return last
end

-- Probability of each key, for showing odds in the UI. Values sum to 1 (or the map is empty).
function WeightedRandom.odds<K>(weights: { [K]: number }): { [K]: number }
	local total = 0
	for _, w in weights do
		total += math.max(0, w)
	end
	local result: { [K]: number } = {}
	if total <= 0 then
		return result
	end
	for key, w in weights do
		if w > 0 then
			result[key] = w / total
		end
	end
	return result
end

return WeightedRandom
