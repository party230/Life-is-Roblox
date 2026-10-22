--!strict
-- Studio-only engine smoke tests. Opt in by adding a boolean attribute `RunSmokeTests = true` on Workspace,
-- then press Play. Results print to Output as [SmokeTest] PASS/FAIL lines.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ProfileStore = require(script.Parent.Parent.Vendor.ProfileStore)
local DataService = require(script.Parent.Parent.Services.DataService)

local SAVE_TIMEOUT = 30

type SmokeData = { runs: number, nonce: string }

local SmokeTests = {}

local function report(name: string, ok: boolean, detail: string)
	local line = `[SmokeTest] {if ok then "PASS" else "FAIL"} {name}: {detail}`
	if ok then
		print(line)
	else
		warn(line)
	end
end

-- Save -> release -> read back -> re-open, on a separate store so real player data is never touched.
local function profileStoreRoundTrip()
	local store = ProfileStore.New("SmokeTest_v1", { runs = 0, nonce = "" }) :: any
	local key = "smoke"

	local first = store:StartSessionAsync(key)
	if not first then
		report("ProfileStore", false, "could not start session")
		return
	end
	local data = first.Data :: SmokeData
	data.runs += 1
	local nonce = HttpService:GenerateGUID(false)
	data.nonce = nonce
	local runs = data.runs

	local saved = false
	first.OnAfterSave:Connect(function()
		saved = true
	end)
	first:EndSession()
	local deadline = os.clock() + SAVE_TIMEOUT
	while not saved and os.clock() < deadline do
		task.wait(0.2)
	end
	if not saved then
		report("ProfileStore", false, `session did not save within {SAVE_TIMEOUT}s`)
		return
	end

	local readBack = store:GetAsync(key)
	if not readBack or (readBack.Data :: SmokeData).nonce ~= nonce then
		report("ProfileStore", false, "GetAsync did not return the value just saved")
		return
	end

	local second = store:StartSessionAsync(key)
	if not second or (second.Data :: SmokeData).nonce ~= nonce then
		report("ProfileStore", false, "re-opened session did not load the saved value")
		return
	end
	second:EndSession()

	local mode = ProfileStore.DataStoreState
	if mode == "Access" then
		report(
			"ProfileStore",
			true,
			`saved and reloaded against real DataStores. Run #{runs}: stop and Play again, this number should go up.`
		)
	else
		report(
			"ProfileStore",
			true,
			`round trip OK but using MOCK storage (DataStoreState={mode}). Enable Studio Access to API Services to test real saves.`
		)
	end
end

local function playerProfileLoads()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local data = DataService.waitFor(player)
	if data then
		report("PlayerData", true, `{player.Name} loaded: version {data.version}, cash {data.cash}`)
	else
		report("PlayerData", false, `{player.Name} left before data loaded`)
	end
end

function SmokeTests.run()
	task.spawn(profileStoreRoundTrip)
	task.spawn(playerProfileLoads)
end

return SmokeTests
