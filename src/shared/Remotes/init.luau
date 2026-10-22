--!strict
-- Every remote in the game is declared here, with its argument Guard (client -> server) and payload type.
-- Server: `Remotes.X:connect(function(player, ...) end)`. Client: `Remotes.X:fire(...)`.

local Guard = require("./Util/Guard")
local Net = require("@self/Net")
local Types = require("./Types")

export type DataSnapshot = {
	cash: number,
	uncollectedCash: number,
	slots: number,
	brainrots: { Types.PublicBrainrot },
	pedestals: { [string]: string },
}

local Remotes = {
	-- Client -> server
	ClientReady = Net.clientEvent("ClientReady", Guard.args(), { burst = 2, perSecond = 0.1 }) :: Net.ClientEvent<>,

	-- Server -> client
	DataSnapshot = Net.serverEvent("DataSnapshot") :: Net.ServerEvent<DataSnapshot>,
	Notify = Net.serverEvent("Notify") :: Net.ServerEvent<string>,
}

return table.freeze(Remotes)
