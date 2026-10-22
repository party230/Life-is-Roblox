--!strict
-- Remote rate limits (token bucket): `burst` requests, refilling at `perSecond`.

return table.freeze({
	DEFAULT_RATE = table.freeze({ burst = 10, perSecond = 5 }),
	-- Kick after this many rejected (invalid or rate-limited) requests in one session window.
	ABUSE_KICK_THRESHOLD = 200,
	ABUSE_WINDOW_SECONDS = 60,
})
