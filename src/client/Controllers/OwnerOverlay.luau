--!strict
-- Owner-only overlay (D39): on the local player's own brainrots (in their base, on pedestals or in the nursery pen)
-- adds the loyalty bar and the runaway-timer bar to the nameplate, raises its MaxDistance, and puts a local
-- "Feed" ProximityPrompt on the model that opens the brainrot card. All of it is created on this client only,
-- from this player's own snapshot: nothing here replicates and other players never see it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local OwnerStatus = require(ReplicatedStorage.Shared.World.OwnerStatus)
local Types = require(ReplicatedStorage.Shared.Types)

local Store = require(script.Parent.Parent.UI.Store)

local OwnerOverlay = {}

local UPDATE_SECONDS = 0.5

type Tracked = { model: Model, gui: BillboardGui, prompt: ProximityPrompt }

local function nameplateOf(model: Model): BillboardGui?
	local root = model.PrimaryPart
	local anchor = root and root:FindFirstChild("Nameplate")
	local gui = anchor and anchor:FindFirstChild("Nameplate")
	return if gui and gui:IsA("BillboardGui") then gui else nil
end

function OwnerOverlay.start(store: Store.Store)
	local me = Players.LocalPlayer.UserId
	local tracked: { [Model]: Tracked } = {}

	local function track(inst: Instance)
		if not inst:IsA("Model") or tracked[inst] then
			return
		end
		local model = inst :: Model
		if model:GetAttribute("OwnerUserId") ~= me or model:GetAttribute("BrainrotId") == nil then
			return
		end
		local gui = nameplateOf(model)
		local root = model.PrimaryPart
		if not gui or not root then
			return
		end
		OwnerStatus.attach(gui)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "FeedPrompt"
		prompt.ActionText = "Feed"
		prompt.ObjectText = model.Name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		prompt.Triggered:Connect(function()
			store.cardBrainrot:set(model:GetAttribute("BrainrotId") :: string)
		end)
		tracked[model] = { model = model, gui = gui, prompt = prompt }
	end

	local function untrack(inst: Instance)
		local t = tracked[inst :: Model]
		if t then
			t.prompt:Destroy()
			tracked[inst :: Model] = nil
		end
	end

	for _, m in CollectionService:GetTagged("Brainrot") do
		track(m)
	end
	CollectionService:GetInstanceAddedSignal("Brainrot"):Connect(function(m)
		task.defer(track, m) -- attributes are set right after the tag
	end)
	CollectionService:GetInstanceRemovedSignal("Brainrot"):Connect(untrack)

	task.spawn(function()
		while true do
			task.wait(UPDATE_SECONDS)
			local byId: { [string]: Types.PublicBrainrot } = {}
			for _, b in Fusion.peek(store.brainrots) do
				byId[b.id] = b
			end
			local snapshotAt = Fusion.peek(store.snapshotAt)
			local dayLength = Fusion.peek(store.dayLength)
			for model, t in tracked do
				if not model.Parent then
					untrack(model)
					continue
				end
				if not t.gui.Parent then
					continue
				end
				local id = model:GetAttribute("BrainrotId") :: string
				local b = byId[id]
				if b then
					local timer = Store.timerNow(b, snapshotAt, dayLength)
					local fraction = if b.timerFullDays > 0 then timer / b.timerFullDays else 0
					OwnerStatus.set(t.gui, b.loyalty / Config.Loyalty.MAX, fraction)
				end
			end
		end
	end)
end

return OwnerOverlay
