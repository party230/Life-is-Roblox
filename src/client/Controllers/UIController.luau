--!strict
-- Mounts the Fusion UI, then tells the server the client is ready to receive state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local App = require(script.Parent.Parent.UI.App)

local UIController = {}

function UIController.init() end

function UIController.start()
	App.mount()
	Remotes.ClientReady:fire()
end

return UIController
