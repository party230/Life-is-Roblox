--!strict
-- Owns player saves. Session-locked via ProfileStore; every other service reads/writes through here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Income = require(Shared.Logic.Income)
local Migrations = require(Shared.Data.Migrations)
local Public = require(Shared.Data.Public)
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Util.Signal)
local Slots = require(Shared.Logic.Slots)
local Template = require(Shared.Data.Template)
local Types = require(Shared.Types)

local Entitlements = require(script.Parent.Parent.Entitlements)

local ProfileStore = require(script.Parent.Parent.Vendor.ProfileStore)

-- Narrow view of ProfileStore's Profile: its JSONAcceptable intersection types don't unify with our
-- PlayerData type under strict mode, so the store is cast once at creation.
type Profile = {
	Data: Types.PlayerData,
	OnSessionEnd: { Connect: (self: any, listener: () -> ()) -> any },
	IsActive: (self: Profile) -> boolean,
	Reconcile: (self: Profile) -> (),
	EndSession: (self: Profile) -> (),
	AddUserId: (self: Profile, userId: number) -> (),
	Save: (self: Profile) -> (),
}
type Store = {
	StartSessionAsync: (self: Store, key: string, params: any) -> Profile?,
}

-- Bump the store name only for a deliberate full wipe (e.g. test servers); use Migrations otherwise.
-- Studio uses its own store so playtest saves (and dev cash) never touch live data.
local STORE_NAME = if RunService:IsStudio() then "PlayerData_studio_v1" else "PlayerData_v1"

local DataService = {
	-- Fired once a player's save is loaded, migrated and ready.
	loaded = Signal.new() :: Signal.Signal<Player, Types.PlayerData>,
	-- Fired just before a player's session ends (last chance to write to their data).
	releasing = Signal.new() :: Signal.Signal<Player, Types.PlayerData>,
	-- Fired once both the save is loaded and the client has said it's listening (send initial state here).
	sessionReady = Signal.new() :: Signal.Signal<Player, Types.PlayerData>,
}

local store: Store
local profiles: { [Player]: Profile } = {}
local clientReady: { [Player]: boolean } = {}
local sessionFired: { [Player]: boolean } = {}

local function trySessionReady(player: Player)
	local profile = profiles[player]
	if profile and clientReady[player] and not sessionFired[player] then
		sessionFired[player] = true
		DataService.sessionReady:fire(player, profile.Data)
	end
end

local function toSnapshot(player: Player, data: Types.PlayerData): Remotes.DataSnapshot
	local slotById: { [string]: number } = {}
	for key, id in data.pedestals do
		slotById[id] = tonumber(key) :: number
	end
	local brainrots: { Types.PublicBrainrot } = {}
	for _, b in data.brainrots do
		table.insert(brainrots, Public.brainrot(b, slotById[b.id]))
	end
	local eggs: { Types.PublicEgg } = {}
	for _, e in data.eggs do
		table.insert(eggs, { id = e.id, eggId = e.eggId, readyAt = e.startedAt + e.hatchSeconds })
	end
	return {
		cash = data.cash,
		uncollectedCash = data.uncollectedCash,
		incomePerSec = Income.basePerSec(data) * Entitlements.incomeMultiplier(player),
		slotsUnlocked = Slots.unlockedCount(Entitlements.extraSlotTiers(player)),
		storageCount = Slots.storageCount(data),
		brainrots = brainrots,
		eggs = eggs,
	}
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(
		`Player_{player.UserId}`,
		{
			Cancel = function()
				return player.Parent ~= Players
			end,
		} :: any
	)

	if profile == nil then
		-- Another server holds the lock and would not release it, or the player left while loading.
		if player.Parent == Players then
			player:Kick("Could not load your data. Please rejoin.")
		end
		return
	end

	profile:AddUserId(player.UserId) -- GDPR right-to-erasure association
	profile:Reconcile()

	local ok, reason = Migrations.run(profile.Data :: any, Template.CURRENT_VERSION)
	if RunService:IsStudio() and profile.Data.cash < Config.Game.STUDIO_DEV_CASH then
		profile.Data.cash = Config.Game.STUDIO_DEV_CASH -- Studio-only store, see STORE_NAME
	end
	if not ok then
		warn(`[DataService] {player.UserId}: {reason}`)
		profile:EndSession()
		player:Kick("Your save is from a newer version. Please rejoin in a moment.")
		return
	end

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data session ended. Please rejoin.")
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	DataService.loaded:fire(player, profile.Data)
	trySessionReady(player)
end

local function onPlayerRemoving(player: Player)
	clientReady[player] = nil
	sessionFired[player] = nil
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Data.lastOnlineAt = os.time()
	DataService.releasing:fire(player, profile.Data)
	profile:EndSession()
end

-- Returns the live (mutable) save, or nil if not loaded. Only the server ever touches this table.
function DataService.get(player: Player): Types.PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- True once the save is loaded and the client is listening for remotes.
function DataService.isSessionReady(player: Player): boolean
	return sessionFired[player] == true
end

-- Yields until the player's data is loaded; returns nil if they leave first.
function DataService.waitFor(player: Player): Types.PlayerData?
	while player.Parent == Players do
		local data = DataService.get(player)
		if data then
			return data
		end
		task.wait(0.1)
	end
	return nil
end

-- Forces an immediate save (e.g. right after granting a Robux purchase).
function DataService.save(player: Player)
	local profile = profiles[player]
	if profile and profile:IsActive() then
		profile:Save()
	end
end

function DataService.sendSnapshot(player: Player)
	local data = DataService.get(player)
	if data then
		Remotes.DataSnapshot:fireClient(player, toSnapshot(player, data))
	end
end

function DataService.init()
	store = ProfileStore.New(STORE_NAME, Template.create() :: any) :: any
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	DataService.sessionReady:connect(function(player)
		DataService.sendSnapshot(player)
	end)
	Remotes.ClientReady:connect(function(player)
		clientReady[player] = true
		trySessionReady(player)
	end)
end

return DataService
