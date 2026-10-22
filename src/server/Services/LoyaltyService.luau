--!strict
-- Loyalty + runaway timer + stolen-return rule (D39). Pure rules live in Logic/Loyalty; this service:
--  * ticks every owned brainrot while its owner is in the server (in-game time only passes for online owners)
--  * at the middle of each night decides who leaves: a brainrot whose timer ran out runs to the hub carpet (where
--    anyone can buy it); a stolen brainrot still loyal to its original owner runs home
--  * lets the owner (or, for a brainrot running home, the thief) catch it on the way: touch it or BONK it
--  * keeps the owner-only data owner-only: it's only ever sent in the owner's own DataSnapshot

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Cycle = require(ReplicatedStorage.Shared.Logic.Cycle)
local Growth = require(ReplicatedStorage.Shared.Logic.Growth)
local Loyalty = require(ReplicatedStorage.Shared.Logic.Loyalty)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local Brainrot = require(ReplicatedStorage.Shared.World.Brainrot)
local Entitlements = require(script.Parent.Parent.Entitlements)
local Bat = require(script.Parent.Parent.World.Bat)
local Blocks = require(script.Parent.Parent.World.Blocks)
local Builder = require(script.Parent.Parent.World.Builder)
local BaseService = require(script.Parent.BaseService)
local BrainrotService = require(script.Parent.BrainrotService)
local CycleService = require(script.Parent.CycleService)
local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)

local LoyaltyService = {}

local C = Config.Loyalty
local L = Config.Layout
local TICK_SECONDS = 1
local SNAPSHOT_SECONDS = 20 -- timers are extrapolated client-side between snapshots
local RUN_HZ = 20

type RunKind = "carpet" | "home"
type Run = {
	kind: RunKind,
	owner: Player, -- whose save holds the record while it runs
	catcher: Player, -- who can catch it (the owner; for a brainrot running home, the thief = owner too)
	home: Player?, -- "home" runs: the original owner it's running back to
	id: string,
	record: Types.Brainrot,
	model: Model,
	waypoints: { Vector3 },
	index: number, -- next waypoint
}

local runs: { [string]: Run } = {}

-- Ticking ------------------------------------------------------------------------------------------------------

local function gameDays(realSeconds: number): number
	return realSeconds * CycleService.timeScale() / Cycle.length()
end

local function tickAll(dt: number)
	local days = gameDays(dt)
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data and BaseService.plotOf(player) then
			local changed = false
			for id, b in data.brainrots do
				local stageBefore = Growth.stage(b).id
				local becameLeaving = not runs[id] and Loyalty.tick(b, days)
				if Growth.stage(b).id ~= stageBefore then
					changed = true -- grew (passive growth): rebuild it at the new size
					Remotes.Notify:fireClient(player, "good", `A baby grew into a {Growth.stage(b).id}!`)
				end
				if becameLeaving then
					changed = true
					local species = Config.Species.byId[b.speciesId]
					Remotes.Notify:fireClient(
						player,
						"warn",
						`{if species then species.displayName else "A brainrot"} will run away tonight unless you feed it!`
					)
				end
			end
			if changed then
				BrainrotService.sync(player) -- Leaving = true: it starts fidgeting
				DataService.sendSnapshot(player)
			end
		end
	end
end

-- Runs ---------------------------------------------------------------------------------------------------------

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function spokePoint(refs: Builder.PlotRefs, radius: number): Vector3
	local gate = Builder.gateCFrame(refs).Position
	local flat = Vector3.new(gate.X, 0, gate.Z).Unit
	return flat * radius + Vector3.new(0, L.HUB_TOP, 0)
end

local function label(model: Model, text: string, color: string)
	local root = model.PrimaryPart :: BasePart
	local gui = Blocks.floating(root, { { text = text, color = color } }, 6, 1.2, root.Size.Y / 2 + 4.5, 200)
	gui.Name = "RunLabel"
	gui.AlwaysOnTop = true
end

local function finish(run: Run)
	runs[run.id] = nil
	run.model:Destroy()
end

local function caught(run: Run)
	finish(run)
	Loyalty.caught(run.record, os.time())
	BrainrotService.setAway(run.id, false)
	BrainrotService.sync(run.owner)
	DataService.sendSnapshot(run.owner)
	local species = Config.Species.byId[run.record.speciesId]
	local name = if species then species.displayName else "your brainrot"
	Remotes.Notify:fireClient(
		run.catcher,
		"good",
		`You caught {name}! It's back home (-{C.CATCH_PENALTY} loyalty).`
	)
	if run.home then
		Remotes.Notify:fireClient(
			run.home,
			"warn",
			`{run.catcher.DisplayName} caught {name} before it got home.`
		)
	end
end

local function arrived(run: Run)
	finish(run)
	local record = BrainrotService.take(run.owner, run.id)
	if not record then
		return
	end
	local species = Config.Species.byId[record.speciesId]
	local name = if species then species.displayName else "A brainrot"
	if run.kind == "carpet" then
		ShopService.addRunaway(record, ShopService.nearestCarpetDistance(run.waypoints[#run.waypoints]))
		Remotes.Notify:fireClient(run.owner, "warn", `{name} reached the carpet. Anyone can buy it now!`)
	else
		local home = run.home
		Loyalty.returnHome(record, os.time())
		if home and home.Parent == Players and BrainrotService.give(home, record) then
			Remotes.Notify:fireClient(home, "good", `{name} ran all the way home to you!`)
			Remotes.Notify:fireClient(run.owner, "warn", `{name} ran home to {home.DisplayName}.`)
		else
			-- its owner left (or has no room): it heads for the carpet instead
			ShopService.addRunaway(record, 0)
		end
	end
end

local function startRun(player: Player, b: Types.Brainrot, kind: RunKind, home: Player?)
	local refs = BaseService.refsFor(player)
	if not refs or runs[b.id] then
		return
	end
	local m: Model
	local detached = BrainrotService.detachModel(player, b.id)
	if detached then
		m = detached
	else
		-- in storage: it bolts out of the gate
		m = Brainrot.create(b.speciesId, b.rarity, b.variant)
		m:PivotTo(Builder.gateCFrame(refs))
		m.Parent = refs.brainrots
	end
	BrainrotService.setAway(b.id, true)
	m:SetAttribute("Walking", true)
	m:SetAttribute("Leaving", false)
	m:SetAttribute("Running", true)
	local waypoints: { Vector3 } = { Builder.gateCFrame(refs).Position, spokePoint(refs, L.HUB_RADIUS - 4) }
	local species = Config.Species.byId[b.speciesId]
	local name = if species then species.displayName else "A brainrot"
	if kind == "carpet" then
		local hubEdge = waypoints[2]
		table.insert(waypoints, ShopService.carpetPoint(ShopService.nearestCarpetDistance(hubEdge)).Position)
		label(m, "RUNAWAY!", "#FF3B3B")
		Remotes.Notify:fireClient(
			player,
			"warn",
			`{name} is running away to the carpet! Touch it or BONK it to catch it!`
		)
	else
		local homeRefs = home and BaseService.refsFor(home)
		if not homeRefs then
			BrainrotService.setAway(b.id, false)
			return
		end
		table.insert(waypoints, spokePoint(homeRefs, L.HUB_RADIUS - 4))
		table.insert(waypoints, Builder.gateCFrame(homeRefs).Position)
		label(m, "RUNNING HOME!", "#7CFF9B")
		Remotes.Notify:fireClient(player, "warn", `{name} is running home to its old owner! Catch it!`)
		if home then
			Remotes.Notify:fireClient(home, "good", `{name} misses you and is running home!`)
		end
	end
	runs[b.id] = {
		kind = kind,
		owner = player,
		catcher = player,
		home = home,
		id = b.id,
		record = b,
		model = m,
		waypoints = waypoints,
		index = 1,
	}
end

local function stepRuns(dt: number)
	for id, run in runs do
		local root = run.model.PrimaryPart
		if not root or run.owner.Parent ~= Players then
			-- the owner left: the brainrot stays in their save and the run is called off
			runs[id] = nil
			run.model:Destroy()
			BrainrotService.setAway(id, false)
			continue
		end
		-- caught by touch?
		local catcherRoot = rootOf(run.catcher)
		if
			catcherRoot
			and (catcherRoot.Position - root.Position).Magnitude <= C.CATCH_RADIUS + root.Size.X / 2
		then
			caught(run)
			continue
		end
		local pivot = root.CFrame * root.PivotOffset
		local pos = pivot.Position
		local target = run.waypoints[run.index]
		local step = C.RUN_SPEED * dt
		local flat = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
		if flat.Magnitude <= step then
			run.index += 1
			if run.index > #run.waypoints then
				arrived(run)
				continue
			end
			pos = Vector3.new(target.X, target.Y, target.Z)
		else
			pos += flat.Unit * step
			pos = Vector3.new(pos.X, target.Y, pos.Z)
		end
		local dir = if flat.Magnitude > 1e-3 then flat.Unit else pivot.LookVector
		local right = dir:Cross(Vector3.yAxis).Unit
		root.CFrame = CFrame.fromMatrix(pos, right, Vector3.yAxis) * root.PivotOffset:Inverse()
	end
end

-- A bat swing: catches the swinger's runners within BONK_RANGE in front of them.
function LoyaltyService.bonk(player: Player)
	local root = rootOf(player)
	if not root then
		return
	end
	for _, run in runs do
		local r = run.model.PrimaryPart
		if run.catcher == player and r then
			local offset = r.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if
				flat.Magnitude <= C.BONK_RANGE
				and (flat.Magnitude < 2 or flat.Unit:Dot(root.CFrame.LookVector) > 0.2)
			then
				caught(run)
				return
			end
		end
	end
end

-- Midnight ------------------------------------------------------------------------------------------------------

function LoyaltyService.midnight()
	local present: { [number]: Player } = {}
	for _, p in Players:GetPlayers() do
		present[p.UserId] = p
	end
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data and BaseService.plotOf(player) then
			local leaving: { { b: Types.Brainrot, kind: RunKind, home: Player? } } = {}
			for _, b in data.brainrots do
				local home = if b.originalOwnerUserId then present[b.originalOwnerUserId] else nil
				local decision = Loyalty.nightDecision(b, home ~= nil and BaseService.plotOf(home) ~= nil)
				if decision == "runaway" then
					table.insert(leaving, { b = b, kind = "carpet" })
				elseif decision == "returnHome" then
					table.insert(leaving, { b = b, kind = "home", home = home })
				end
				Loyalty.nightPassed(b)
			end
			for _, l in leaving do
				startRun(player, l.b, l.kind, l.home)
			end
		end
	end
end

-- Bond Collar ------------------------------------------------------------------------------------------------

local function setCollar(player: Player, id: string, on: boolean)
	local data = DataService.get(player)
	local b = data and data.brainrots[id]
	if not data or not b then
		return
	end
	if on then
		if not Entitlements.hasBondCollar(player) then
			Remotes.Notify:fireClient(
				player,
				"info",
				"The Bond Collar pass pauses a brainrot's runaway timer."
			)
			return
		end
		local count = 0
		for _, other in data.brainrots do
			if other.bondCollared then
				count += 1
			end
		end
		if count >= C.COLLAR_MAX then
			Remotes.Notify:fireClient(player, "warn", `You can collar up to {C.COLLAR_MAX} brainrots.`)
			return
		end
	end
	b.bondCollared = on
	DataService.sendSnapshot(player)
end

-- Setup ----------------------------------------------------------------------------------------------------------

local function hookBat(player: Player, tool: Instance)
	if tool:IsA("Tool") and tool.Name == "Bonk Bat" then
		Bat.hook(tool, function()
			LoyaltyService.bonk(player)
		end)
	end
end

local function watchTools(player: Player)
	local function watch(container: Instance)
		for _, child in container:GetChildren() do
			hookBat(player, child)
		end
		container.ChildAdded:Connect(function(child)
			hookBat(player, child)
		end)
	end
	local backpack = player:WaitForChild("Backpack", 10)
	if backpack then
		watch(backpack)
	end
	player.CharacterAdded:Connect(function(character)
		watch(character)
		local bp = player:FindFirstChild("Backpack")
		if bp then
			watch(bp)
		end
	end)
	if player.Character then
		watch(player.Character)
	end
end

function LoyaltyService.init() end

function LoyaltyService.start()
	ShopService.setAcquireHook(function(record, buyer, now)
		Loyalty.acquire(record, buyer.UserId, now)
	end)
	CycleService.midnight:connect(LoyaltyService.midnight)
	Remotes.SetCollar:connect(setCollar)
	Remotes.DevAction:connect(function(player, action)
		if not RunService:IsStudio() then
			return -- never on live servers
		end
		local data = DataService.get(player)
		if action == "ExpireTimers" and data then
			for _, b in data.brainrots do
				b.timerDays = math.min(b.timerDays, 0.001)
			end
			Remotes.Notify:fireClient(player, "info", "DEV: your brainrots' timers are about to run out.")
		elseif action == "Midnight" then
			LoyaltyService.midnight()
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(watchTools, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(watchTools, player)
	end

	task.spawn(function()
		local last = os.clock()
		local sinceSnapshot = 0
		while true do
			task.wait(TICK_SECONDS)
			local now = os.clock()
			local dt = now - last
			last = now
			tickAll(dt)
			sinceSnapshot += dt
			if sinceSnapshot >= SNAPSHOT_SECONDS then
				sinceSnapshot = 0
				for _, player in Players:GetPlayers() do
					DataService.sendSnapshot(player)
				end
			end
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 1 / RUN_HZ then
			stepRuns(acc)
			acc = 0
		end
	end)
end

return LoyaltyService
