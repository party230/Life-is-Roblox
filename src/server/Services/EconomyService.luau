--!strict
-- Cash: income accrues into each base's collector every tick; walking over the collector claims it.
-- Offline earnings are credited to the collector on join. All spending goes through `spend`.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Income = require(ReplicatedStorage.Shared.Logic.Income)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Slots = require(ReplicatedStorage.Shared.Logic.Slots)

local Entitlements = require(script.Parent.Parent.Entitlements)
local BaseService = require(script.Parent.BaseService)
local DataService = require(script.Parent.DataService)

local EconomyService = {}

local pendingOffline: { [Player]: number } = {}
local COLLECT_CHECK_INTERVAL = 0.2

function EconomyService.perSec(player: Player): number
	local data = DataService.get(player)
	if not data then
		return 0
	end
	return Income.basePerSec(data) * Entitlements.incomeMultiplier(player)
end

function EconomyService.sendCash(player: Player)
	local data = DataService.get(player)
	if data then
		Remotes.CashUpdate:fireClient(
			player,
			data.cash,
			math.floor(data.uncollectedCash),
			EconomyService.perSec(player)
		)
	end
end

function EconomyService.canAfford(player: Player, amount: number): boolean
	local data = DataService.get(player)
	return data ~= nil and amount >= 0 and data.cash >= amount
end

-- Deducts cash if affordable. Returns true on success. Never goes negative.
function EconomyService.spend(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if not data or amount < 0 or data.cash < amount then
		return false
	end
	data.cash -= amount
	EconomyService.sendCash(player)
	return true
end

function EconomyService.grant(player: Player, amount: number)
	local data = DataService.get(player)
	if not data or amount <= 0 then
		return
	end
	data.cash += math.floor(amount)
	data.stats.totalEarned += math.floor(amount)
	EconomyService.sendCash(player)
end

local function collect(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local amount = math.floor(data.uncollectedCash)
	if amount < 1 then
		return
	end
	data.uncollectedCash -= amount
	data.cash += amount
	data.stats.totalEarned += amount
	EconomyService.sendCash(player)
end

local function updateCollectorLabel(player: Player)
	local data = DataService.get(player)
	local refs = BaseService.refsFor(player)
	if data and refs then
		refs.collectorLabel.Text = Format.cash(math.floor(data.uncollectedCash))
	end
end

local function onLoaded(player: Player, data: any)
	Income.refresh(data)
	Slots.sanitize(data, Entitlements.extraSlotTiers(player))
	local now = os.time()
	if data.lastOnlineAt > 0 then
		local earned = Income.offline(
			Income.basePerSec(data),
			now - data.lastOnlineAt,
			Entitlements.hasAutoCollect(player)
		)
		if earned > 0 then
			data.uncollectedCash += earned
			pendingOffline[player] = earned
		end
	end
	data.lastOnlineAt = now
end

local function tick(dt: number)
	local now = os.time()
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data and BaseService.plotOf(player) then
			data.uncollectedCash += EconomyService.perSec(player) * dt
			-- Kept fresh so a server crash can't double-count offline time on the next join.
			data.lastOnlineAt = now
			if Entitlements.hasAutoCollect(player) then
				collect(player)
			end
			updateCollectorLabel(player)
			EconomyService.sendCash(player)
		end
	end
end

local function checkCollectors()
	local radius = Config.Game.COLLECT_RADIUS
	for _, player in Players:GetPlayers() do
		local refs = BaseService.refsFor(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if refs and root then
			local offset = root.Position - refs.collector.Position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius and math.abs(offset.Y) < 8 then
				collect(player)
				updateCollectorLabel(player)
			end
		end
	end
end

function EconomyService.init() end

function EconomyService.start()
	DataService.loaded:connect(onLoaded)
	DataService.sessionReady:connect(function(player)
		EconomyService.sendCash(player)
		local earned = pendingOffline[player]
		if earned then
			pendingOffline[player] = nil
			Remotes.Notify:fireClient(
				player,
				"good",
				`While you were away your base earned {Format.cash(earned)}. Walk over your collector to claim it!`
			)
		end
	end)
	BaseService.assigned:connect(function(player)
		updateCollectorLabel(player)
	end)
	BaseService.released:connect(function(_, refs)
		refs.collectorLabel.Text = "$0"
	end)
	Players.PlayerRemoving:Connect(function(player)
		pendingOffline[player] = nil
	end)

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Config.Game.INCOME_TICK_SECONDS)
			local now = os.clock()
			tick(now - last)
			last = now
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= COLLECT_CHECK_INTERVAL then
			acc = 0
			checkCollectors()
		end
	end)
end

return EconomyService
