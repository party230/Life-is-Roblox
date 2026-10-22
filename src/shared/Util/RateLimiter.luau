--!strict
-- Token-bucket rate limiter keyed by anything (usually a Player). Clock is injectable for tests.

export type Options = { burst: number, perSecond: number }

type Bucket = { tokens: number, updatedAt: number }

export type RateLimiter = {
	allow: (self: RateLimiter, key: any) -> boolean,
	forget: (self: RateLimiter, key: any) -> (),
}

local RateLimiter = {}

function RateLimiter.new(options: Options, clock: (() -> number)?): RateLimiter
	local now = clock or os.clock
	local buckets: { [any]: Bucket } = {}

	local self = {}

	function self.allow(_: RateLimiter, key: any): boolean
		local t = now()
		local bucket = buckets[key]
		if not bucket then
			bucket = { tokens = options.burst, updatedAt = t }
			buckets[key] = bucket
		else
			local refill = (t - bucket.updatedAt) * options.perSecond
			bucket.tokens = math.min(options.burst, bucket.tokens + refill)
			bucket.updatedAt = t
		end
		if bucket.tokens >= 1 then
			bucket.tokens -= 1
			return true
		end
		return false
	end

	function self.forget(_: RateLimiter, key: any)
		buckets[key] = nil
	end

	return (self :: any) :: RateLimiter
end

return RateLimiter
