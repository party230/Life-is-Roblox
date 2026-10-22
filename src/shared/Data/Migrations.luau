--!strict
-- Save migrations. `steps[n]` upgrades a save from version n to n + 1, in place.
-- Never edit a shipped step; append a new one and bump Template.CURRENT_VERSION.

export type Step = (data: { [string]: any }) -> ()

local Migrations = {}

Migrations.steps = {} :: { Step }

-- Runs every step from data.version up to target. Returns false (and leaves the save untouched by later
-- steps) if the save is from a newer build than this server knows about.
function Migrations.run(data: { [string]: any }, target: number, steps: { Step }?): (boolean, string?)
	local list = steps or Migrations.steps
	local version = if type(data.version) == "number" then data.version else 1
	if version > target then
		return false, `save version {version} is newer than server version {target}`
	end
	while version < target do
		local step = list[version]
		if not step then
			return false, `missing migration step {version} -> {version + 1}`
		end
		step(data)
		version += 1
		data.version = version
	end
	return true, nil
end

return Migrations
