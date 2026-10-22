--!strict
-- Thin typed wrapper over RemoteEvents. All remotes are declared in Remotes/init.luau.
--
-- ClientEvent: client -> server intent. Server handlers only run after the per-player rate limit and the
--              remote's Guard pass; failures count toward an abuse threshold that kicks the player.
-- ServerEvent: server -> client update.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require("../Config")
local RateLimiter = require("../Util/RateLimiter")

local IS_SERVER = RunService:IsServer()
local FOLDER_NAME = "Remotes"

export type RateOptions = RateLimiter.Options

export type ClientEvent<T...> = {
	name: string,
	-- client
	fire: (self: ClientEvent<T...>, T...) -> (),
	-- server
	connect: (self: ClientEvent<T...>, handler: (player: Player, T...) -> ()) -> RBXScriptConnection,
}

export type ServerEvent<T...> = {
	name: string,
	unreliable: boolean,
	-- server
	fireClient: (self: ServerEvent<T...>, player: Player, T...) -> (),
	fireAll: (self: ServerEvent<T...>, T...) -> (),
	fireList: (self: ServerEvent<T...>, players: { Player }, T...) -> (),
	-- client
	connect: (self: ServerEvent<T...>, handler: (T...) -> ()) -> RBXScriptConnection,
}

local Net = {}

local folder: Folder
if IS_SERVER then
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function getRemote(name: string, unreliable: boolean): BaseRemoteEvent
	if IS_SERVER then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing :: BaseRemoteEvent
		end
		local remote: BaseRemoteEvent = if unreliable
			then Instance.new("UnreliableRemoteEvent")
			else Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name) :: BaseRemoteEvent
end

-- Abuse tracking (server only): rejected calls within a rolling window.
local abuse: { [Player]: { count: number, windowStart: number } } = {}

local function reportRejected(player: Player, remoteName: string, reason: string)
	local now = os.clock()
	local existing = abuse[player]
	local entry = if existing and now - existing.windowStart <= Config.Network.ABUSE_WINDOW_SECONDS
		then existing
		else { count = 0, windowStart = now }
	abuse[player] = entry
	entry.count += 1
	if entry.count == 1 or entry.count % 50 == 0 then
		warn(`[Net] rejected {remoteName} from {player.UserId}: {reason} (x{entry.count})`)
	end
	if entry.count >= Config.Network.ABUSE_KICK_THRESHOLD then
		player:Kick("Too many invalid requests.")
	end
end

if IS_SERVER then
	Players.PlayerRemoving:Connect(function(player)
		abuse[player] = nil
	end)
end

function Net.clientEvent(name: string, guard: (...any) -> boolean, rate: RateOptions?): ClientEvent<...any>
	local remote = getRemote(name, false) :: RemoteEvent
	local limiter = RateLimiter.new(rate or Config.Network.DEFAULT_RATE)
	if IS_SERVER then
		Players.PlayerRemoving:Connect(function(player)
			limiter:forget(player)
		end)
	end

	local event = { name = name }

	function event.fire(_: any, ...: any)
		assert(not IS_SERVER, `{name}: fire() is client-only`)
		remote:FireServer(...)
	end

	function event.connect(_: any, handler: (Player, ...any) -> ()): RBXScriptConnection
		assert(IS_SERVER, `{name}: connect() is server-only`)
		return remote.OnServerEvent:Connect(function(player: Player, ...: any)
			if not limiter:allow(player) then
				reportRejected(player, name, "rate limited")
				return
			end
			if not guard(...) then
				reportRejected(player, name, "invalid arguments")
				return
			end
			handler(player, ...)
		end)
	end

	return (event :: any) :: ClientEvent<...any>
end

function Net.serverEvent(name: string, unreliable: boolean?): ServerEvent<...any>
	local isUnreliable = unreliable == true
	local remote = getRemote(name, isUnreliable)
	local event = { name = name, unreliable = isUnreliable }

	function event.fireClient(_: any, player: Player, ...: any)
		assert(IS_SERVER, `{name}: fireClient() is server-only`);
		(remote :: any):FireClient(player, ...)
	end

	function event.fireAll(_: any, ...: any)
		assert(IS_SERVER, `{name}: fireAll() is server-only`);
		(remote :: any):FireAllClients(...)
	end

	function event.fireList(_: any, players: { Player }, ...: any)
		assert(IS_SERVER, `{name}: fireList() is server-only`)
		for _, player in players do
			(remote :: any):FireClient(player, ...)
		end
	end

	function event.connect(_: any, handler: (...any) -> ()): RBXScriptConnection
		assert(not IS_SERVER, `{name}: connect() is client-only`)
		return (remote :: any).OnClientEvent:Connect(handler)
	end

	return (event :: any) :: ServerEvent<...any>
end

return Net
