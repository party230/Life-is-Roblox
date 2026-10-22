--!strict
-- Player-facing number and time formatting. Keep every on-screen number going through here.

local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

local function commas(n: number): string
	local s = tostring(math.floor(n))
	local sign = ""
	if string.sub(s, 1, 1) == "-" then
		sign = "-"
		s = string.sub(s, 2)
	end
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return sign .. out
end

-- Abbreviates with a suffix, keeping `sig` significant digits and dropping trailing zeros: 13500 -> "13.5K".
local function suffixed(n: number, sig: number): string
	local tier = 0
	local value = n
	while math.abs(value) >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	local digits = #tostring(math.floor(math.abs(value)))
	local decimals = math.max(0, sig - digits)
	local factor = 10 ^ decimals
	value = math.floor(value * factor + 0.5) / factor
	if value >= 1000 and tier < #SUFFIXES then
		value /= 1000
		tier += 1
	end
	local text = string.format(`%.{decimals}f`, value)
	if string.find(text, "%.") then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text .. (SUFFIXES[tier] or "")
end

-- Cash balance: "$12,480" up to a million, then "$1.25M".
function Format.cash(n: number): string
	if math.abs(n) < 1e6 then
		return "$" .. commas(n)
	end
	return "$" .. suffixed(n, 3)
end

-- Compact price for cards and tags: "$1,050" under 10K, then "$26K", "$13.5K", "$1.5M".
function Format.price(n: number): string
	if math.abs(n) < 1e4 then
		return "$" .. commas(n)
	end
	return "$" .. suffixed(n, 3)
end

-- Income rate: "+$84/s", "+$2.6/s", "+$1.2K/s".
function Format.perSec(n: number): string
	local body
	if n < 10 then
		body = string.format("%.1f", math.floor(n * 10 + 0.5) / 10)
		body = string.gsub(body, "%.0$", "")
	elseif n < 1e4 then
		body = commas(n + 0.5)
	else
		body = suffixed(n, 3)
	end
	return "+$" .. body .. "/s"
end

-- Countdown clock: "0:42", "5:07", "1:02:03".
function Format.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	local h = s // 3600
	local m = (s % 3600) // 60
	local sec = s % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, sec)
	end
	return string.format("%d:%02d", m, sec)
end

-- Rough duration for plain-language text: "45s", "2m", "1h 20m".
function Format.duration(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s < 60 then
		return `{s}s`
	end
	local minutes = math.ceil(s / 60)
	if minutes < 60 then
		return `{minutes}m`
	end
	local h = minutes // 60
	local m = minutes % 60
	return if m == 0 then `{h}h` else `{h}h {m}m`
end

-- Shop card payback line (approved: simple text, no maths). Rounds up to whole minutes.
function Format.payback(price: number, incomePerSec: number): string
	if incomePerSec <= 0 then
		return ""
	end
	local seconds = price / incomePerSec
	if seconds < 60 then
		return "Pays back in under 1m"
	end
	return "Pays back in " .. Format.duration(seconds)
end

return Format
