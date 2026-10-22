--!strict
-- Loyalty + runaway timer maths (D39). Pure functions on Brainrot records so they can be unit-tested.
-- Times are in in-game days (1 in-game day = Cycle.length() seconds); timers only advance while the owner is
-- online, which the server enforces by only calling `tick` for brainrots of players in the server.

local Config = require("../Config")
local Types = require("../Types")
local Growth = require("./Growth")

local Loyalty = {}

local C = Config.Loyalty

local function clampLoyalty(v: number): number
	return math.clamp(v, 0, C.MAX)
end

-- Income multiplier for a loyalty value (piecewise linear through INCOME_CURVE).
function Loyalty.incomeMult(loyalty: number): number
	local curve = C.INCOME_CURVE
	local v = clampLoyalty(loyalty)
	for i = 2, #curve do
		local a, b = curve[i - 1], curve[i]
		if v <= b[1] then
			local t = (v - a[1]) / (b[1] - a[1])
			return a[2] + (b[2] - a[2]) * t
		end
	end
	return curve[#curve][2]
end

-- Fraction of the runaway timer left since it was last filled (drives the owner's timer bar).
function Loyalty.timerFraction(b: Types.Brainrot): number
	if b.timerFullDays <= 0 then
		return 0
	end
	return math.clamp(b.timerDays / b.timerFullDays, 0, 1)
end

export type BarColor = "green" | "yellow" | "red"
function Loyalty.barColor(fraction: number): BarColor
	if fraction <= C.TIMER_RED then
		return "red"
	elseif fraction <= C.TIMER_YELLOW then
		return "yellow"
	end
	return "green"
end

local function resetTimer(b: Types.Brainrot)
	b.timerDays = C.TIMER_MIN_DAYS
	b.timerFullDays = C.TIMER_MIN_DAYS
	b.leaving = false
	b.sinceFedDays = 0
end

-- A brainrot is acquired by `ownerUserId` (bought from the carpet, including a runaway someone else lost).
-- Every acquisition starts the timer at the minimum and loyalty at START.
function Loyalty.acquire(b: Types.Brainrot, ownerUserId: number, now: number)
	b.ownerUserId = ownerUserId
	b.loyalty = C.START
	b.isStolen = false
	b.originalOwnerUserId = nil
	b.oldLoyalty = nil
	b.acquiredAt = now
	b.lastInteractedAt = now
	b.bondCollared = false
	resetTimer(b)
end

-- Stolen by `thiefUserId`: remembers its loyalty to the owner it was taken from, starts low with the thief.
function Loyalty.steal(b: Types.Brainrot, thiefUserId: number, now: number)
	b.originalOwnerUserId = b.ownerUserId
	b.oldLoyalty = b.loyalty
	b.ownerUserId = thiefUserId
	b.loyalty = C.STOLEN_START
	b.isStolen = true
	b.acquiredAt = now
	b.lastInteractedAt = now
	b.bondCollared = false
	resetTimer(b)
end

-- Ran home to its original owner (stolen-return rule): back to its old loyalty, a fresh minimum timer.
function Loyalty.returnHome(b: Types.Brainrot, now: number)
	local home = b.originalOwnerUserId
	if home then
		b.ownerUserId = home
	end
	b.loyalty = clampLoyalty(b.oldLoyalty or C.START)
	b.isStolen = false
	b.originalOwnerUserId = nil
	b.oldLoyalty = nil
	b.acquiredAt = now
	b.lastInteractedAt = now
	resetTimer(b)
end

-- The owner caught it on the way out (runaway) or a thief caught it running home: it stays, with a penalty.
function Loyalty.caught(b: Types.Brainrot, now: number)
	b.loyalty = clampLoyalty(b.loyalty - C.CATCH_PENALTY)
	b.lastInteractedAt = now
	resetTimer(b)
end

export type FeedResult = { days: number, loyalty: number, growth: number }

-- Feeds `quantity` of a food. Timer days stack (capped), loyalty and growth stack. Feeding a "leaving tonight"
-- brainrot puts time back on the clock, so it stays. The timer bar refills (its reference becomes the new value).
function Loyalty.feed(b: Types.Brainrot, food: Config.FoodDef, quantity: number, now: number): FeedResult
	local before = { days = b.timerDays, loyalty = b.loyalty, growth = b.growth }
	if food.fillsTimer then
		b.timerDays = C.MAX_TIMER_DAYS
	else
		b.timerDays = math.min(C.MAX_TIMER_DAYS, b.timerDays + food.days * quantity)
	end
	b.timerFullDays = b.timerDays
	if b.timerDays > 0 then
		b.leaving = false
	end
	b.loyalty = if food.maxLoyalty then C.MAX else clampLoyalty(b.loyalty + food.loyalty * quantity)
	b.growth = if food.instantAdult
		then math.max(b.growth, Config.Nursery.ADULT_GROWTH)
		else b.growth + food.growth * quantity
	b.sinceFedDays = 0
	b.lastInteractedAt = now
	return {
		days = b.timerDays - before.days,
		loyalty = b.loyalty - before.loyalty,
		growth = b.growth - before.growth,
	}
end

-- Advances one brainrot by `days` of in-game time while its owner is online. Returns true if it just became
-- "leaving tonight". Bond Collar: the timer is paused and loyalty doesn't grow (it can still decay).
function Loyalty.tick(b: Types.Brainrot, days: number): boolean
	if days <= 0 then
		return false
	end
	local becameLeaving = false
	b.sinceFedDays += days
	local neglected = b.sinceFedDays > C.NEGLECT_AFTER_DAYS
	if neglected then
		b.loyalty = clampLoyalty(b.loyalty - C.NEGLECT_DECAY_PER_DAY * days)
	elseif not b.bondCollared then
		b.loyalty = clampLoyalty(b.loyalty + C.TRICKLE_PER_DAY * days)
	end
	if not b.bondCollared then
		local wasPositive = b.timerDays > 0
		b.timerDays = math.max(0, b.timerDays - days)
		if b.timerDays <= 0 and not b.leaving then
			b.leaving = true
			becameLeaving = wasPositive
		end
	end
	Growth.tick(b, days)
	return becameLeaving
end

export type NightDecision = "stay" | "runaway" | "returnHome"

-- At the middle of the night: what does this brainrot do?
-- A stolen brainrot still loyal enough to its original owner runs home (if that owner is in the server);
-- otherwise a brainrot whose timer ran out runs away to the carpet.
function Loyalty.nightDecision(b: Types.Brainrot, originalOwnerPresent: boolean): NightDecision
	if
		b.isStolen
		and b.originalOwnerUserId ~= nil
		and (b.oldLoyalty or 0) >= C.RETURN_HOME_THRESHOLD
		and originalOwnerPresent
	then
		return "returnHome"
	end
	if b.leaving then
		return "runaway"
	end
	return "stay"
end

-- Once per night (after decisions): a stolen brainrot's memory of its original owner fades.
function Loyalty.nightPassed(b: Types.Brainrot)
	if b.isStolen and b.oldLoyalty then
		b.oldLoyalty = math.max(0, b.oldLoyalty - C.OLD_LOYALTY_DECAY_PER_NIGHT)
	end
end

-- Effective income multiplier from loyalty and growth stage.
function Loyalty.incomeFactor(b: Types.Brainrot): number
	return Loyalty.incomeMult(b.loyalty) * Growth.stage(b).incomeMult
end

-- "3d 6h" style text for in-game days (panels; the overlay itself is a bar).
function Loyalty.formatDays(days: number): string
	local hours = math.floor(math.max(0, days) * 24 + 0.5)
	return `{hours // 24}d {hours % 24}h`
end

return Loyalty
