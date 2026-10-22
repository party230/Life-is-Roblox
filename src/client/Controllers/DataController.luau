--!strict
-- Holds the latest server snapshot of the local player's data. Read-only mirror: never the source of truth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local DataController = {
	changed = Signal.new() :: Signal.Signal<Remotes.DataSnapshot>,
}

local snapshot: Remotes.DataSnapshot? = nil

function DataController.get(): Remotes.DataSnapshot?
	return snapshot
end

function DataController.init() end

function DataController.start()
	Remotes.DataSnapshot:connect(function(data)
		snapshot = data
		DataController.changed:fire(data)
	end)
	Remotes.ClientReady:fire()
end

return DataController
