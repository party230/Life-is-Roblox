--!strict
-- The shared red-carpet conveyor in the hub (D38). Every CARPET_SPAWN_SECONDS a brainrot steps out of the central
-- portal and walks the carpet path (ramp -> loop -> exit vortex) with its price on the nameplate. Anyone can buy
-- it (ProximityPrompt, or the Shop panel while standing at the carpet): first to buy gets it, and it lands on a
-- free pedestal (or in storage). Unsold ones vanish into the exit vortex.
--
-- Rare+ spawns get a server-wide banner over the portal; a guaranteed Rare+ "featured" spawn arrives every
-- FEATURED_INTERVAL of Day. The carpet closes at night (Q1), but runaways (LoyaltyService) rejoin it any time.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Roll = require(ReplicatedStorage.Shared.Logic.Roll)
local ShopStock = require(ReplicatedStorage.Shared.Logic.ShopStock)
local Types = require(ReplicatedStorage.Shared.Types)

local Brainrot = require(ReplicatedStorage.Shared.World.Brainrot)
local Builder = require(script.Parent.Parent.World.Builder)
local BaseService = require(script.Parent.BaseService)
local BrainrotService = require(script.Parent.BrainrotService)
local CycleService = require(script.Parent.CycleService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local ShopService = {}

type Item = {
	listing: ShopStock.Listing,
	model: Model,
	dist: number, -- studs walked along the carpet path
	buying: boolean,
	featured: boolean,
	record: Types.Brainrot?, -- set for runaways: the brainrot itself changes hands
}

local random = Random.new()
local function rng(): number
	return random:NextNumber()
end

local items: { [string]: Item } = {}
local serial = 0
local nextSpawnAt = 0
local nextFeaturedAt = 0
local announceUntil = 0
local stateDirty = false

-- Carpet path (from the Hub builder) with cumulative distances for sampling.
local path: { Vector3 } = {}
local cumulative: { number } = {}
local pathLength = 0

local function buildPath()
	path = Builder.hub().carpetPath
	cumulative = { 0 }
	for i = 2, #path do
		cumulative[i] = cumulative[i - 1] + (path[i] - path[i - 1]).Magnitude
	end
	pathLength = cumulative[#path]
end

-- Position and heading at `dist` along the path.
local function sample(dist: number): CFrame
	local d = math.clamp(dist, 0, pathLength)
	for i = 2, #path do
		if d <= cumulative[i] or i == #path then
			local seg = cumulative[i] - cumulative[i - 1]
			local t = if seg > 0 then (d - cumulative[i - 1]) / seg else 0
			local a, b = path[i - 1], path[i]
			local pos = a:Lerp(b, t)
			local dir = (b - a).Unit
			local right = dir:Cross(Vector3.yAxis).Unit
			return CFrame.fromMatrix(pos, right, Vector3.yAxis)
		end
	end
	return CFrame.new(path[1])
end

-- Nearest distance along the path to a world point (runaways join the carpet where they reach it).
function ShopService.nearestCarpetDistance(point: Vector3): number
	local best, bestDist = math.huge, 0
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local ab = b - a
		local t = math.clamp((point - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
		local d = (a + ab * t - point).Magnitude
		if d < best then
			best = d
			bestDist = cumulative[i - 1] + ab.Magnitude * t
		end
	end
	return bestDist
end

function ShopService.carpetPoint(dist: number): CFrame
	return sample(dist)
end

local function toPublic(item: Item): Types.PublicListing
	local l = item.listing
	return {
		id = l.id,
		speciesId = l.speciesId,
		variant = l.variant :: Types.VariantId,
		rarity = l.rarity :: Types.RarityId,
		price = l.price,
		incomePerSec = l.incomePerSec,
		sold = l.sold,
		featured = item.featured,
		runaway = item.record ~= nil,
	}
end

local function stateFor(): Remotes.ShopState
	local list: { Item } = {}
	for _, item in items do
		table.insert(list, item)
	end
	-- next to walk off the end first
	table.sort(list, function(a, b)
		return a.dist > b.dist
	end)
	local listings: { Types.PublicListing } = {}
	for _, item in list do
		table.insert(listings, toPublic(item))
	end
	return { listings = listings, nextRotationAt = nextSpawnAt, open = CycleService.shopOpen() }
end

local function broadcast()
	local state = stateFor()
	for _, player in Players:GetPlayers() do
		if DataService.isSessionReady(player) then
			Remotes.ShopState:fireClient(player, state)
		end
	end
end

local function removeItem(id: string)
	local item = items[id]
	if item then
		items[id] = nil
		item.model:Destroy()
		stateDirty = true
	end
end

local function place(item: Item)
	local root = item.model.PrimaryPart :: BasePart
	local hover = (item.model:GetAttribute("Hover") :: number?) or 0
	root.CFrame = sample(item.dist) * CFrame.new(0, hover, 0) * root.PivotOffset:Inverse()
end

local function announce(rarity: string, name: string, featured: boolean)
	local hub = Builder.hub()
	hub.announceLabels[1].Text = if featured
		then `FEATURED: {string.upper(rarity)}!`
		else `{string.upper(rarity)} SPAWNED!`
	hub.announceLabels[1].TextColor3 = Color3.fromHex(Config.Rarities.byId[rarity].color)
	hub.announceLabels[2].Text = `{name} is on the carpet`
	hub.announceGui.Enabled = true
	announceUntil = os.clock() + Config.Shop.ANNOUNCE_SECONDS
	Remotes.Notify:fireAll("drop", `{rarity} {name} is on the carpet! First to buy it wins.`)
end

local function blockReason(player: Player, price: number, isRunaway: boolean): string?
	if not CycleService.shopOpen() and not isRunaway then
		return "The carpet is closed for the night. It opens at dawn!"
	end
	if not BaseService.plotOf(player) then
		return "Claim a base first!"
	end
	if not BrainrotService.hasRoom(player) then
		return "No room! Free a pedestal or a storage slot first."
	end
	if not EconomyService.canAfford(player, price) then
		return "Not enough cash yet."
	end
	return nil
end

local function nearItem(player: Player, item: Item): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local itemRoot = item.model.PrimaryPart
	return root ~= nil
		and itemRoot ~= nil
		and (root.Position - itemRoot.Position).Magnitude <= Config.Shop.BUY_RADIUS
end

-- Hook for LoyaltyService: turns a bought runaway's record into the buyer's (fresh timer, loyalty...).
-- Default: just hand it over.
local acquireHook: (record: Types.Brainrot, buyer: Player, now: number) -> () = function(record, buyer, _now)
	record.ownerUserId = buyer.UserId
end
function ShopService.setAcquireHook(hook: (record: Types.Brainrot, buyer: Player, now: number) -> ())
	acquireHook = hook
end

function ShopService.buy(player: Player, listingId: string): boolean
	local item = items[listingId]
	if not item or item.buying or item.listing.sold then
		Remotes.Notify:fireClient(player, "warn", "Too late, someone else got it!")
		return false
	end
	if not nearItem(player, item) then
		Remotes.Notify:fireClient(player, "warn", "Walk to the carpet in the hub to buy it!")
		return false
	end
	local reason = blockReason(player, item.listing.price, item.record ~= nil)
	if reason then
		Remotes.Notify:fireClient(player, "warn", reason)
		return false
	end
	if not EconomyService.spend(player, item.listing.price) then
		return false
	end
	-- claim first: a second buyer in the same frame loses
	item.buying = true
	item.listing.sold = true
	local now = os.time()
	local brainrot: Types.Brainrot
	local record = item.record
	if record then
		brainrot = record
		acquireHook(brainrot, player, now)
	else
		brainrot = Roll.newBrainrot(
			BrainrotService.newId(),
			item.listing.speciesId,
			item.listing.variant :: Types.VariantId,
			player.UserId,
			now
		)
	end
	local name = item.model.Name
	removeItem(listingId)
	if not BrainrotService.give(player, brainrot) then
		EconomyService.grant(player, item.listing.price) -- refund if somehow no room
		return false
	end
	Remotes.Notify:fireClient(player, "good", `{name} is heading to your base!`)
	if item.featured or item.record then
		Remotes.Notify:fireAll("info", `{player.DisplayName} got {name} from the carpet!`)
	end
	return true
end

local function addItem(
	listing: ShopStock.Listing,
	dist: number,
	featured: boolean,
	record: Types.Brainrot?
): Item
	local model =
		Brainrot.create(listing.speciesId, listing.rarity, listing.variant, { price = listing.price })
	if record then
		model:SetAttribute("Runaway", true)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = `Buy {Format.price(listing.price)}`
	prompt.ObjectText = model.Name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	local id = listing.id
	prompt.Triggered:Connect(function(who)
		ShopService.buy(who, id)
	end)
	local item: Item = {
		listing = listing,
		model = model,
		dist = dist,
		buying = false,
		featured = featured,
		record = record,
	}
	model:SetAttribute("Walking", true)
	place(item)
	model.Parent = Builder.hub().carpetItems
	items[id] = item
	stateDirty = true
	if featured or Config.Rarities.byId[listing.rarity].order >= Config.Shop.ANNOUNCE_MIN_RARITY_ORDER then
		announce(listing.rarity, model.Name, featured)
	end
	return item
end

local function count(): number
	local n = 0
	for _ in items do
		n += 1
	end
	return n
end

local function spawnNext(featured: boolean)
	if count() >= Config.Shop.CARPET_MAX_ITEMS then
		return
	end
	serial += 1
	local listing = if featured
		then ShopStock.featured(rng, `f{serial}`)
		else ShopStock.carpetListing(rng, `c{serial}`, 1)
	if listing then
		addItem(listing, 0, featured, nil)
	end
end

-- A runaway reached the carpet: it walks on from `dist` like any listing, and anyone can buy it (any time).
function ShopService.addRunaway(record: Types.Brainrot, dist: number)
	serial += 1
	local listing = ShopStock.listingFor(
		`r{serial}`,
		record.speciesId,
		record.variant,
		rng,
		Config.Shop.RUNAWAY_PRICE_MULT
	)
	addItem(listing, dist, false, record)
	local species = Config.Species.byId[record.speciesId]
	Remotes.Notify:fireAll(
		"drop",
		`A runaway {if species then species.displayName else "brainrot"} jumped onto the carpet! Anyone can buy it.`
	)
end

local function clearNormal()
	for id, item in items do
		if not item.record and not item.buying then
			removeItem(id)
		end
	end
end

function ShopService.init() end

function ShopService.start()
	buildPath()
	local now = workspace:GetServerTimeNow()
	nextSpawnAt = now + 1
	nextFeaturedAt = now + Config.Shop.FEATURED_INTERVAL

	DataService.sessionReady:connect(function(player)
		Remotes.ShopState:fireClient(player, stateFor())
	end)
	Remotes.BuyListing:connect(function(player, id)
		ShopService.buy(player, id)
	end)
	CycleService.phaseChanged:connect(function(phase)
		if phase == "Night" then
			clearNormal()
		elseif phase == "Day" then
			nextFeaturedAt = workspace:GetServerTimeNow() + Config.Shop.FEATURED_INTERVAL
		end
		stateDirty = true
	end)

	local acc = 0
	local step = 1 / Config.Shop.CARPET_UPDATE_HZ
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < step then
			return
		end
		local elapsed = acc
		acc = 0
		for id, item in items do
			if not item.buying then
				item.dist += Config.Shop.CARPET_WALK_SPEED * elapsed
				if item.dist >= pathLength then
					removeItem(id) -- into the exit vortex (a runaway nobody bought is gone for good)
				else
					place(item)
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			local t = workspace:GetServerTimeNow()
			if CycleService.shopOpen() then
				if t >= nextSpawnAt then
					nextSpawnAt = t + Config.Shop.CARPET_SPAWN_SECONDS
					spawnNext(false)
				end
				if CycleService.phase() == "Day" and t >= nextFeaturedAt then
					nextFeaturedAt = t + Config.Shop.FEATURED_INTERVAL
					spawnNext(true)
				end
			end
			if announceUntil > 0 and os.clock() >= announceUntil then
				announceUntil = 0
				Builder.hub().announceGui.Enabled = false
			end
			if stateDirty then
				stateDirty = false
				broadcast()
			end
		end
	end)
end

return ShopService
