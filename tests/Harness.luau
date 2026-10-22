--!strict
-- Minimal TestEZ-compatible harness for running pure-logic specs under Lune (no Roblox engine needed).
-- Supports: describe, it, beforeEach, expect(x).to.equal / .be.ok / .be.near / .throw / .a, and .never.

type TestCase = { name: string, fn: () -> () }
type Suite = {
	name: string,
	tests: { TestCase },
	children: { Suite },
	beforeEach: { () -> () },
	parent: Suite?,
}

local Harness = {}

local root: Suite = { name = "", tests = {}, children = {}, beforeEach = {}, parent = nil }
local current = root

function Harness.describe(name: string, fn: () -> ())
	local suite: Suite = { name = name, tests = {}, children = {}, beforeEach = {}, parent = current }
	table.insert(current.children, suite)
	local previous = current
	current = suite
	fn()
	current = previous
end

function Harness.it(name: string, fn: () -> ())
	table.insert(current.tests, { name = name, fn = fn })
end

function Harness.beforeEach(fn: () -> ())
	table.insert(current.beforeEach, fn)
end

local function fmt(value: any): string
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

export type Expectation = {
	to: Expectation,
	be: Expectation,
	never: Expectation,
	equal: (expected: any) -> (),
	ok: () -> (),
	near: (expected: number, epsilon: number?) -> (),
	throw: (substring: string?) -> (),
	a: (typeName: string) -> (),
}

function Harness.expect(actual: any): Expectation
	local negated = false
	local e = {} :: any

	local function check(pass: boolean, message: string)
		if pass == negated then
			error((if negated then "Expected NOT: " else "Expected: ") .. message, 3)
		end
	end

	setmetatable(e, {
		__index = function(_, key)
			if key == "to" or key == "be" then
				return e
			elseif key == "never" then
				negated = not negated
				return e
			end
			return nil
		end,
	})

	function e.equal(expected: any)
		check(actual == expected, `{fmt(actual)} to equal {fmt(expected)}`)
	end
	function e.ok()
		check(actual ~= nil and actual ~= false, `{fmt(actual)} to be ok`)
	end
	function e.near(expected: number, epsilon: number?)
		local eps = epsilon or 1e-7
		check(math.abs(actual - expected) <= eps, `{fmt(actual)} to be near {fmt(expected)} (+/-{eps})`)
	end
	function e.throw(substring: string?)
		local ok, err = pcall(actual)
		local matched = not ok and (substring == nil or string.find(tostring(err), substring, 1, true) ~= nil)
		check(matched, `function to throw{if substring then " " .. fmt(substring) else ""}, got {fmt(err)}`)
	end
	function e.a(typeName: string)
		check(typeof(actual) == typeName, `{fmt(actual)} to be a {typeName}`)
	end

	return e :: Expectation
end

-- Runs all registered suites. Returns (passed, failed, failure messages).
function Harness.run(): (number, number, { string })
	local passed, failed = 0, 0
	local failures: { string } = {}

	local function hooksFor(suite: Suite): { () -> () }
		local chain: { Suite } = {}
		local s: Suite? = suite
		while s do
			table.insert(chain, 1, s)
			s = s.parent
		end
		local hooks: { () -> () } = {}
		for _, item in chain do
			for _, hook in item.beforeEach do
				table.insert(hooks, hook)
			end
		end
		return hooks
	end

	local function walk(suite: Suite, path: string)
		local hooks = hooksFor(suite)
		for _, test in suite.tests do
			local ok, err = pcall(function()
				for _, hook in hooks do
					hook()
				end
				test.fn()
			end)
			if ok then
				passed += 1
			else
				failed += 1
				table.insert(failures, `{path} {test.name}\n    {err}`)
			end
		end
		for _, child in suite.children do
			walk(child, if path == "" then child.name else `{path} > {child.name}`)
		end
	end

	walk(root, "")
	return passed, failed, failures
end

-- Clears registered suites (between files).
function Harness.reset()
	root = { name = "", tests = {}, children = {}, beforeEach = {}, parent = nil }
	current = root
end

return Harness
