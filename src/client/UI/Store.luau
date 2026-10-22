--!strict
-- Reactive client state: Fusion Values fed by server remotes. Read-only mirror of server truth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

type Scope = Fusion.Scope<typeof(Fusion)>
type V<T> = Fusion.Value<T, any>

export type Toast = { id: number, kind: Remotes.NotifyKind, text: string }

export type Store = {
	cash: V<number>,
	uncollected: V<number>,
	perSec: V<number>,
	slotsUnlocked: V<number>,
	placedCount: V<number>,
	brainrots: V<{ Types.PublicBrainrot }>,
	eggs: V<{ Types.PublicEgg }>,
	phase: V<Types.CyclePhase>,
	phaseEndsAt: V<number>,
	now: V<number>, -- server time, ticks ~5x a second
	listings: V<{ Types.PublicListing }>,
	nextRotationAt: V<number>,
	shopOpen: V<boolean>,
	plazaDrop: V<Remotes.PlazaDropState?>,
	plot: V<Remotes.PlotState?>,
	toast: V<Toast?>,
	shopVisible: V<boolean>,
	eggsVisible: V<boolean>,
	pushToast: (kind: Remotes.NotifyKind, text: string) -> (),
}

local Store = {}

local TOAST_SECONDS = 3.5

function Store.new(scope: Scope): Store
	local store: Store = {
		cash = scope:Value(0) :: any,
		uncollected = scope:Value(0) :: any,
		perSec = scope:Value(0) :: any,
		slotsUnlocked = scope:Value(0) :: any,
		placedCount = scope:Value(0) :: any,
		brainrots = scope:Value({}) :: any,
		eggs = scope:Value({}) :: any,
		phase = scope:Value("Day" :: Types.CyclePhase) :: any,
		phaseEndsAt = scope:Value(0) :: any,
		now = scope:Value(workspace:GetServerTimeNow()) :: any,
		listings = scope:Value({}) :: any,
		nextRotationAt = scope:Value(0) :: any,
		shopOpen = scope:Value(true) :: any,
		plazaDrop = scope:Value(nil :: Remotes.PlazaDropState?) :: any,
		plot = scope:Value(nil :: Remotes.PlotState?) :: any,
		toast = scope:Value(nil :: Toast?) :: any,
		shopVisible = scope:Value(false) :: any,
		eggsVisible = scope:Value(false) :: any,
		pushToast = function() end,
	}

	table.insert(
		scope,
		Remotes.DataSnapshot:connect(function(snap)
			store.cash:set(snap.cash)
			store.uncollected:set(snap.uncollectedCash)
			store.perSec:set(snap.incomePerSec)
			store.slotsUnlocked:set(snap.slotsUnlocked)
			local placed = 0
			for _, b in snap.brainrots do
				if b.slot then
					placed += 1
				end
			end
			store.placedCount:set(placed)
			store.brainrots:set(snap.brainrots)
			store.eggs:set(snap.eggs)
		end)
	)
	table.insert(
		scope,
		Remotes.CashUpdate:connect(function(cash, uncollected, perSec)
			store.cash:set(cash)
			store.uncollected:set(uncollected)
			store.perSec:set(perSec)
		end)
	)
	table.insert(
		scope,
		Remotes.CycleState:connect(function(state)
			store.phase:set(state.phase)
			store.phaseEndsAt:set(state.endsAt)
		end)
	)
	table.insert(
		scope,
		Remotes.ShopState:connect(function(state)
			store.listings:set(state.listings)
			store.nextRotationAt:set(state.nextRotationAt)
			store.shopOpen:set(state.open)
		end)
	)
	table.insert(
		scope,
		Remotes.PlazaDrop:connect(function(state)
			store.plazaDrop:set(state)
		end)
	)
	table.insert(
		scope,
		Remotes.PlotState:connect(function(state)
			store.plot:set(state)
		end)
	)

	-- Toasts: one at a time (approved HUD-3), queued.
	local queue: { Toast } = {}
	local serial = 0
	local showing = false
	local function pump()
		if showing then
			return
		end
		local nextToast = table.remove(queue, 1)
		if not nextToast then
			store.toast:set(nil)
			return
		end
		showing = true
		store.toast:set(nextToast)
		task.delay(TOAST_SECONDS, function()
			showing = false
			pump()
		end)
	end
	store.pushToast = function(kind, text)
		serial += 1
		table.insert(queue, { id = serial, kind = kind, text = text })
		if #queue > 4 then
			table.remove(queue, 1)
		end
		pump()
	end
	table.insert(scope, Remotes.Notify:connect(store.pushToast))

	local acc = 0
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function(dt)
			acc += dt
			if acc >= 0.2 then
				acc = 0
				store.now:set(workspace:GetServerTimeNow())
			end
		end)
	)

	return store
end

return Store
