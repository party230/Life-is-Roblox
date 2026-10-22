--!strict
-- Runtime argument validators for remote payloads. Clients can send anything, so every remote declares
-- a Guard and the server drops calls that fail it before any handler runs.

export type Check = (value: any) -> boolean

local Guard = {}

function Guard.string(maxLength: number?): Check
	local limit = maxLength or 200
	return function(value)
		return type(value) == "string" and #value <= limit and utf8.len(value) ~= nil
	end
end

-- Finite number (rejects NaN and +/-inf), optionally within [min, max].
function Guard.number(min: number?, max: number?): Check
	return function(value)
		if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
			return false
		end
		if min and value < min then
			return false
		end
		if max and value > max then
			return false
		end
		return true
	end
end

function Guard.integer(min: number?, max: number?): Check
	local isNumber = Guard.number(min, max)
	return function(value)
		return isNumber(value) and math.floor(value) == value
	end
end

Guard.boolean = function(value: any): boolean
	return type(value) == "boolean"
end :: Check

-- GUID as produced by HttpService:GenerateGUID(false): 36 chars, hex and dashes.
Guard.guid = function(value: any): boolean
	return type(value) == "string" and #value == 36 and string.match(value, "^[%x%-]+$") ~= nil
end :: Check

function Guard.literal(...: string): Check
	local allowed: { [string]: boolean } = {}
	for _, v in { ... } do
		allowed[v] = true
	end
	return function(value)
		return type(value) == "string" and allowed[value] == true
	end
end

function Guard.optional(check: Check): Check
	return function(value)
		return value == nil or check(value)
	end
end

-- Validates a full argument list: exact count (trailing nils allowed for optional checks) and each check.
function Guard.args(...: Check): (...any) -> boolean
	local checks = { ... }
	local count = #checks
	return function(...)
		if select("#", ...) > count then
			return false
		end
		for i = 1, count do
			if not checks[i]((select(i, ...))) then
				return false
			end
		end
		return true
	end
end

return Guard
