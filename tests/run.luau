--!strict
-- Lune test runner: `lune run tests/run.luau`. Runs every *.spec.luau in this folder.

local fs = require("@lune/fs")
local process = require("@lune/process")

local Harness = require("./Harness")

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
