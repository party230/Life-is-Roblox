--!strict
-- Lune test runner: `lune run tests/run.luau`. Runs every *.spec.luau in this folder.

local fs = require("@lune/fs")
local process = require("@lune/process")

local roblox = require("@lune/roblox")

local Harness = require("./Harness")

-- Roblox datatypes for specs that build Instances (model contract tests).
for _, k in
	{
		"Instance",
		"Vector3",
		"CFrame",
		"Color3",
		"Enum",
		"Vector2",
		"UDim2",
		"UDim",
		"ColorSequence",
		"ColorSequenceKeypoint",
		"NumberSequence",
		"NumberSequenceKeypoint",
		"NumberRange",
	}
do
	(getfenv(0) :: any)[k] = (roblox :: any)[k]
end

local files: { string } = {}
for _, name in fs.readDir("tests") do
	if string.match(name, "%.spec%.luau$") then
		table.insert(files, name)
	end
end
table.sort(files)

local totalPassed, totalFailed = 0, 0
for _, file in files do
	Harness.reset()
	local loaded, loadErr = pcall(require, `./{string.gsub(file, "%.luau$", "")}`)
	if not loaded then
		totalFailed += 1
		print(`✗ {file} failed to load:\n    {loadErr}`)
		continue
	end
	local passed, failed, failures = Harness.run()
	totalPassed += passed
	totalFailed += failed
	print(`{if failed == 0 then "✓" else "✗"} {file}: {passed} passed, {failed} failed`)
	for _, message in failures do
		print(`    ✗ {message}`)
	end
end

print(`\n{totalPassed} passed, {totalFailed} failed`)
if totalFailed > 0 then
	process.exit(1)
end
