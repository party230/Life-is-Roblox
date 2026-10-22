--!strict
-- Every character model must satisfy the rig contract (docs/MODEL_CONTRACT.md), so part-built and future
-- mesh-built characters are interchangeable without touching game logic.
local Harness = require("./Harness")
local describe, it, expect = Harness.describe, Harness.it, Harness.expect

local Config = require("../src/shared/Config")
local Kit = require("../src/shared/World/Models/Kit")

local ROLES = { skin = true, eye = true, pupil = true, detail = true, glow = true }

local function checkContract(model: Model)
	local root = model.PrimaryPart :: BasePart
	expect(root).to.be.ok()
	expect(root.Name).to.equal("Root")
	expect(root.Anchored).to.equal(true)
	expect(root.Transparency).to.equal(1)
	for _, name in { "Nameplate", "Vfx", "TrailA", "TrailB" } do
		expect(root:FindFirstChild(name)).to.be.ok()
	end
	local anim = root:FindFirstChild("Anim") :: Motor6D
	expect(anim).to.be.ok()
	expect(anim.Part0).to.equal(root)
	local body = anim.Part1 :: BasePart
	expect(body).to.be.ok()
	local eyes, pupils = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			expect(d.Anchored).to.equal(false)
			expect(d.CanCollide).to.equal(false)
			local role = d:GetAttribute("Role") :: string
			expect(ROLES[role]).to.equal(true)
			expect(d:GetAttribute("BaseColor")).to.be.ok()
			if role == "eye" then
				eyes += 1
			elseif role == "pupil" then
				pupils += 1
			end
			if d ~= body then
				-- joined to the rig by a weld or a spinner motor
				local joined = d:FindFirstChildOfClass("WeldConstraint") or d:FindFirstChild("Spinner")
				expect(joined).to.be.ok()
			end
		end
	end
	-- the Dark variant needs eyes to turn red
	expect(eyes >= 2).to.equal(true)
	expect(pupils >= 2).to.equal(true)
end

local function lowestPoint(model: Model): number
	local lowest = math.huge
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			local half = d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local corner =
							d.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
						lowest = math.min(lowest, corner.Y)
					end
				end
			end
		end
	end
	return lowest
end

describe("Character models", function()
	-- every part-built model key in Config must have a builder that satisfies the contract
	for _, def in Config.Species.list do
		local name = def.model
		if not name or string.sub(name, 1, 5) == "mesh:" then
			continue
		end
		it(`{name} satisfies the rig contract and stands on the ground`, function()
			local build = require(`../src/shared/World/Models/Characters/{name}`) :: any
			local model = build() :: Model
			checkContract(model)
			local hover = model:GetAttribute("Hover") :: number
			if hover == 0 then
				expect(math.abs(lowestPoint(model)) < 0.35).to.equal(true)
			end
		end)
	end

	it("Kit.adopt turns a plain (mesh-style) model into the same rig", function()
		local model = Instance.new("Model")
		model.Name = "MeshThing"
		local body = Instance.new("Part")
		body.Name = "BodyMesh"
		body.Size = Vector3.new(3, 4, 2)
		body.CFrame = CFrame.new(10, 2, 5)
		body.Anchored = true
		body.Parent = model
		for side = -1, 1, 2 do
			local eye = Instance.new("Part")
			eye.Name = "EyeL"
			eye.Size = Vector3.new(0.5, 0.5, 0.5)
			eye.CFrame = CFrame.new(10 + side * 0.6, 3, 4)
			eye.Parent = model
			local pupil = Instance.new("Part")
			pupil.Name = "PupilL"
			pupil.Size = Vector3.new(0.2, 0.2, 0.2)
			pupil.CFrame = CFrame.new(10 + side * 0.6, 3, 3.8)
			pupil.Parent = model
		end
		Kit.adopt(model)
		checkContract(model)
		expect(model.WorldPivot.Position.Y).to.be.near(0, 1e-4) -- feet at the lowest point
		local root = model.PrimaryPart :: BasePart
		expect(root.CFrame.Position.X).to.be.near(10, 1e-4)
	end)
end)

return nil
