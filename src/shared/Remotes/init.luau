--!strict
-- Every remote in the game is declared here, with its argument Guard (client -> server) and payload type.
-- Server: `Remotes.X:connect(function(player, ...) end)`. Client: `Remotes.X:fire(...)`.

local Config = require("./Config")
local Guard = require("./Util/Guard")
local Net = require("@self/Net")
local Types = require("./Types")

export type DataSnapshot = {
	cash: number,
	uncollectedCash: number,
	incomePerSec: number,
	slotsUnlocked: number,
	storageCount: number,
	brainrots: { Types.PublicBrainrot }, -- owner-private fields included: only ever sent to the owner
	eggs: { Types.PublicEgg },
	food: { [string]: number },
	nurseryUnlocked: boolean,
	nurseryPrice: number, -- cash price to unlock (scales with progress)
	incubators: number, -- usable incubators (3 + pass tiers)
	collarSlots: number, -- Bond Collar: how many brainrots can be collared (0 without the pass)
	dayLength: number, -- seconds per in-game day (client extrapolates timers between snapshots)
}

export type CycleState = {
	phase: Types.CyclePhase,
	endsAt: number, -- workspace:GetServerTimeNow() time the phase ends
	cycle: number,
}

export type ShopState = {
	listings: { Types.PublicListing },
	nextRotationAt: number, -- server time
	open: boolean,
}

export type PlotState = {
	owners: { number }, -- index -> owner UserId, 0 = free
	ownerNames: { string }, -- index -> display name, "" = free
	mine: number, -- 0 = not picked yet
	pickDeadline: number, -- server time; auto-assign after this
}

export type HatchResult = {
	brainrot: Types.PublicBrainrot,
	placed: "pedestal" | "storage" | "nursery",
}

export type NotifyKind = "info" | "good" | "warn" | "drop"

local plotIndex = Guard.integer(1, Config.Game.PLOT_COUNT)
local foodId = Guard.string(32)
local listingId = Guard.string(40)
local eggId = Guard.literal("basic", "fancy")

local Remotes = {
	-- Client -> server
	ClientReady = Net.clientEvent("ClientReady", Guard.args(), { burst = 2, perSecond = 0.1 }) :: Net.ClientEvent<>,
	PickPlot = Net.clientEvent("PickPlot", Guard.args(plotIndex), { burst = 3, perSecond = 1 }) :: Net.ClientEvent<number>,
	BuyListing = Net.clientEvent("BuyListing", Guard.args(listingId), { burst = 4, perSecond = 2 }) :: Net.ClientEvent<string>,
	BuyEgg = Net.clientEvent("BuyEgg", Guard.args(eggId), { burst = 3, perSecond = 1 }) :: Net.ClientEvent<string>,
	HatchEgg = Net.clientEvent("HatchEgg", Guard.args(Guard.guid), { burst = 3, perSecond = 2 }) :: Net.ClientEvent<string>,
	BuyFood = Net.clientEvent(
		"BuyFood",
		Guard.args(foodId, Guard.integer(1, 10)),
		{ burst = 4, perSecond = 2 }
	) :: Net.ClientEvent<string, number>,
	FeedBrainrot = Net.clientEvent(
		"FeedBrainrot",
		Guard.args(Guard.guid, foodId, Guard.integer(1, Config.Food.FEED_MAX_QUANTITY)),
		{ burst = 6, perSecond = 3 }
	) :: Net.ClientEvent<string, string, number>,
	UnlockNursery = Net.clientEvent("UnlockNursery", Guard.args(), { burst = 2, perSecond = 0.5 }) :: Net.ClientEvent<>,
	MoveToPedestal = Net.clientEvent("MoveToPedestal", Guard.args(Guard.guid), { burst = 3, perSecond = 2 }) :: Net.ClientEvent<string>,
	SetCollar = Net.clientEvent(
		"SetCollar",
		Guard.args(Guard.guid, Guard.boolean),
		{ burst = 3, perSecond = 1 }
	) :: Net.ClientEvent<string, boolean>,
	-- Studio only (ignored on live servers): test helpers for the runaway rules.
	DevAction = Net.clientEvent(
		"DevAction",
		Guard.args(Guard.literal("ExpireTimers", "Midnight")),
		{ burst = 2, perSecond = 1 }
	) :: Net.ClientEvent<string>,
	-- Studio only (ignored on live servers): force Day or Night lighting/state for the vertical slice.
	DevSetPhase = Net.clientEvent(
		"DevSetPhase",
		Guard.args(Guard.literal("Day", "Night")),
		{ burst = 2, perSecond = 1 }
	) :: Net.ClientEvent<string>,

	-- Server -> client
	DataSnapshot = Net.serverEvent("DataSnapshot") :: Net.ServerEvent<DataSnapshot>,
	CashUpdate = Net.serverEvent("CashUpdate", true) :: Net.ServerEvent<number, number, number>, -- cash, uncollected, perSec
	CycleState = Net.serverEvent("CycleState") :: Net.ServerEvent<CycleState>,
	ShopState = Net.serverEvent("ShopState") :: Net.ServerEvent<ShopState>,
	PlotState = Net.serverEvent("PlotState") :: Net.ServerEvent<PlotState>,
	HatchResult = Net.serverEvent("HatchResult") :: Net.ServerEvent<HatchResult>,
	Notify = Net.serverEvent("Notify") :: Net.ServerEvent<NotifyKind, string>,
}

return table.freeze(Remotes)
