--!strict
-- Plots: builds the map, lets players pick a free plot on join (or auto-assigns one after PLOT_PICK_SECONDS,
-- next to a friend if possible), spawns them there, and frees the plot when they leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Config = require(ReplicatedStorage.Shared.Config)
local Plots = require(ReplicatedStorage.Shared.Logic.Plots)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local Builder = require(script.Parent.Parent.World.Builder)
local DataService = require(script.Parent.DataService)

export type PlotRefs = Builder.PlotRefs

local BaseService = {
	assigned = Signal.new() :: Signal.Signal<Player, PlotRefs>,
	released = Signal.new() :: Signal.Signal<Player, PlotRefs>,
}

local refs: { PlotRefs } = {}
local owners: { [number]: Player } = {}
local plotOf: { [Player]: number } = {}
local deadlines: { [Player]: number } = {}

function BaseService.plotOf(player: Player): number?
	return plotOf[player]
end

function BaseService.refs(index: number): PlotRefs
	return refs[index]
end

function BaseService.refsFor(player: Player): PlotRefs?
	local index = plotOf[player]
	return if index then refs[index] else nil
end

function BaseService.ownerOf(index: number): Player?
	return owners[index]
end

local function stateFor(player: Player): Remotes.PlotState
	local ownerIds: { number } = {}
	local names: { string } = {}
	for i = 1, Config.Game.PLOT_COUNT do
		local owner = owners[i]
		ownerIds[i] = if owner then owner.UserId else 0
		names[i] = if owner then owner.DisplayName else ""
	end
	return {
		owners = ownerIds,
		ownerNames = names,
		mine = plotOf[player] or 0,
		pickDeadline = deadlines[player] or 0,
	}
end

local function broadcast()
	for _, player in Players:GetPlayers() do
		if DataService.isSessionReady(player) then
			Remotes.PlotState:fireClient(player, stateFor(player))
		end
	end
end

local function spawnAtPlot(player: Player)
	local r = BaseService.refsFor(player)
	local character = player.Character
	if r and character then
		character:PivotTo(Builder.spawnCFrame(r))
	end
end

local function assign(player: Player, index: number): boolean
	if owners[index] or plotOf[player] or player.Parent ~= Players then
		return false
	end
	owners[index] = player
	plotOf[player] = index
	deadlines[player] = nil
	local r = refs[index]
	-- Roblox display names are already filtered; base names typed by players will go through TextService.
	r.signLabel.Text = string.upper(player.DisplayName) .. "'S BASE"
	r.model:SetAttribute("OwnerUserId", player.UserId)
	spawnAtPlot(player)
	BaseService.assigned:fire(player, r)
	broadcast()
	return true
end

local function isFriend(a: Player, b: Player): boolean
	local ok, result = pcall(a.IsFriendsWithAsync, a, b.UserId)
	return ok and result == true
end

-- Free plot next to a friend if there is one, else the first free plot.
local function autoAssign(player: Player)
	if plotOf[player] then
		return
	end
	local fallback: number? = nil
	for i = 1, Config.Game.PLOT_COUNT do
		if not owners[i] then
			fallback = fallback or i
			local left, right = Plots.neighbours(i)
			for _, n in { left, right } do
				local neighbour = owners[n]
				if neighbour and isFriend(player, neighbour) then
					assign(player, i)
					return
				end
			end
		end
	end
	if fallback then
		assign(player, fallback)
	else
		-- Server is full of plots (shouldn't happen with MaxPlayers = PLOT_COUNT).
		player:Kick("This server has no free bases. Please try another server.")
	end
end

local function release(player: Player)
	local index = plotOf[player]
	plotOf[player] = nil
	deadlines[player] = nil
	if not index then
		return
	end
	owners[index] = nil
	local r = refs[index]
	r.signLabel.Text = "FREE PLOT"
	r.model:SetAttribute("OwnerUserId", nil)
	BaseService.released:fire(player, r)
	broadcast()
end

function BaseService.init()
	refs = Builder.build()
	StarterPlayer.CameraMaxZoomDistance = Config.Game.CAMERA_MAX_ZOOM
	StarterPlayer.CameraMinZoomDistance = Config.Game.CAMERA_MIN_ZOOM
end

function BaseService.start()
	local function setup(player: Player)
		player.CameraMaxZoomDistance = Config.Game.CAMERA_MAX_ZOOM
		player.CameraMinZoomDistance = Config.Game.CAMERA_MIN_ZOOM
		player.CharacterAdded:Connect(function(character)
			if plotOf[player] then
				character:WaitForChild("HumanoidRootPart", 5)
				task.defer(spawnAtPlot, player)
			end
		end)
	end
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		setup(player)
	end

	DataService.loaded:connect(function(player)
		deadlines[player] = workspace:GetServerTimeNow() + Config.Game.PLOT_PICK_SECONDS
		task.delay(Config.Game.PLOT_PICK_SECONDS, function()
			if player.Parent == Players then
				autoAssign(player)
			end
		end)
	end)
	DataService.sessionReady:connect(function(player)
		Remotes.PlotState:fireClient(player, stateFor(player))
	end)
	Remotes.PickPlot:connect(function(player, index)
		if not DataService.get(player) or plotOf[player] then
			return
		end
		if not assign(player, index) then
			Remotes.Notify:fireClient(player, "warn", "That spot was just taken. Pick another!")
			Remotes.PlotState:fireClient(player, stateFor(player))
		end
	end)
	Players.PlayerRemoving:Connect(release)
end

return BaseService
