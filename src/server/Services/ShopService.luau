--!strict
-- Red carpet conveyor (vertical slice / D24): every few seconds a brainrot steps out of each claimed base's
-- spawn portal and walks the carpet with its price on the nameplate. Buy it with its ProximityPrompt (or from
-- the Shop panel): it walks to your first free pedestal and becomes yours. Unbought ones vanish at the end.
-- Carpets stop at night (approved Q1). The server-wide plaza drop (approved Q3) works as before.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Roll = require(ReplicatedStorage.Shared.Logic.Roll)
local ShopStock = require(ReplicatedStorage.Shared.Logic.ShopStock)
local Slots = require(ReplicatedStorage.Shared.Logic.Slots)
local Types = require(ReplicatedStorage.Shared.Types)

local Brainrot = require(ReplicatedStorage.Shared.World.Brainrot)
local Builder = require(script.Parent.Parent.World.Builder)
local Entitlements = require(script.Parent.Parent.Entitlements)
local BaseService = require(script.Parent.BaseService)
local BrainrotService = require(script.Parent.BrainrotService)
local CycleService = require(script.Parent.CycleService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local ShopService = {}

type CarpetItem = {
	listing: ShopStock.Listing,
	model: Model,
	tween: Tween?,
	buying: boolean,
}
type Carpet = { items: { [string]: CarpetItem }, nextSpawnAt: number }
type Drop = { listing: ShopStock.Listing, endsAt: number, model: Model? }

local random = Random.new()
local function rng(): number
	return random:NextNumber()
end

local carpets: { [Player]: Carpet } = {}
local serial = 0
local drop: Drop? = nil
local nextDropAt = 0

local function toPublic(l: ShopStock.Listing): Types.PublicListing
	return {
		id = l.id,
		speciesId = l.speciesId,
		variant = l.variant :: Types.VariantId,
		rarity = l.rarity :: Types.RarityId,
		price = l.price,
		incomePerSec = l.incomePerSec,
		sold = l.sold,
	}
end

local function sendState(player: Player)
	if not DataService.isSessionReady(player) then
		return
	end
	local carpet = carpets[player]
	local listings: { Types.PublicListing } = {}
	if carpet then
		for _, item in carpet.items do
			table.insert(listings, toPublic(item.listing))
		end
		-- oldest first (next to walk off the end); ids are "c<serial>"
		table.sort(listings, function(a, b)
			return (tonumber(string.sub(a.id, 2)) or 0) < (tonumber(string.sub(b.id, 2)) or 0)
		end)
	end
	Remotes.ShopState:fireClient(player, {
		listings = listings,
		nextRotationAt = if carpet then carpet.nextSpawnAt else 0,
		open = CycleService.shopOpen(),
	})
end

local function blockReason(player: Player, price: number): string?
	if not CycleService.shopOpen() then
		return "The carpet is closed for the night. It opens at dawn!"
	end
	if not BaseService.plotOf(player) then
		return "Claim a base first!"
	end
	if not BrainrotService.hasFreePedestal(player) then
		return "Base full! Free up a pedestal first."
	end
	if not EconomyService.canAfford(player, price) then
		return "Not enough cash yet."
	end
	return nil
end

local function removeItem(player: Player, id: string)
	local carpet = carpets[player]
	local item = carpet and carpet.items[id]
	if carpet and item then
		carpet.items[id] = nil
		if item.tween then
			item.tween:Cancel()
		end
		item.model:Destroy()
		sendState(player)
	end
end

-- Walk the root from where it is to `target` over `seconds`. Returns the tween.
local function walk(model: Model, target: CFrame, seconds: number): Tween
	local root = model.PrimaryPart :: BasePart
	-- `target` is a pivot (feet) CFrame; the root sits above its pivot by the inverse of its PivotOffset
	local offset = root.PivotOffset:Inverse()
	model:SetAttribute("Walking", true)
	local tween = TweenService:Create(
		root,
		TweenInfo.new(seconds, Enum.EasingStyle.Linear),
		{ CFrame = target * offset }
	)
	tween:Play()
	return tween
end

function ShopService.buy(player: Player, listingId: string): boolean
	local carpet = carpets[player]
	local item = carpet and carpet.items[listingId]
	if not item or item.buying then
		Remotes.Notify:fireClient(player, "warn", "Too late, it walked off!")
		sendState(player)
		return false
	end
	local reason = blockReason(player, item.listing.price)
	if reason then
		Remotes.Notify:fireClient(player, "warn", reason)
		return false
	end
	local data = DataService.get(player)
	local refs = BaseService.refsFor(player)
	local slot = data and Slots.firstFree(data, BrainrotService.tiers(player))
	if not data or not refs or not slot then
		return false
	end
	if not EconomyService.spend(player, item.listing.price) then
		return false
	end
	item.buying = true
	item.listing.sold = true
	if item.tween then
		item.tween:Cancel()
	end
	local brainrot = Roll.newBrainrot(
		BrainrotService.newId(),
		item.listing.speciesId,
		item.listing.variant :: Types.VariantId,
		player.UserId,
		os.time()
	)
	-- walk over to the pedestal, then hand over to BrainrotService (which owns pedestal models)
	local prompt = item.model:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt:Destroy()
	end
	local target = Builder.pedestalTop(refs, slot)
	item.tween = walk(item.model, target, 1.2)
	local placedName = item.model.Name
	task.delay(1.25, function()
		removeItem(player, listingId)
		if not BrainrotService.give(player, brainrot) then
			EconomyService.grant(player, item.listing.price) -- refund if somehow no room
		end
	end)
	Remotes.Notify:fireClient(player, "good", `{placedName} joined your base!`)
	sendState(player)
	return true
end

local function spawnOnCarpet(player: Player)
	local refs = BaseService.refsFor(player)
	local carpet = carpets[player]
	if not refs or not carpet then
		return
	end
	local count = 0
	for _ in carpet.items do
		count += 1
	end
	if count >= Config.Shop.CARPET_MAX_ITEMS then
		return
	end
	serial += 1
	local listing = ShopStock.carpetListing(rng, `c{serial}`, Entitlements.luck(player))
	if not listing then
		return
	end
	local model =
		Brainrot.create(listing.speciesId, listing.rarity, listing.variant, { price = listing.price })
	model:PivotTo(Builder.carpetStart(refs))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = `Buy {Format.price(listing.price)}`
	prompt.ObjectText = model.Name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	local id = listing.id
	prompt.Triggered:Connect(function(who)
		if who == player then
			ShopService.buy(player, id)
		else
			Remotes.Notify:fireClient(who, "info", "That carpet belongs to another base.")
		end
	end)
	model.Parent = refs.carpetItems
	local item: CarpetItem = { listing = listing, model = model, tween = nil, buying = false }
	carpet.items[id] = item
	item.tween = walk(model, Builder.carpetEnd(refs), Config.Shop.CARPET_WALK_SECONDS)
	local tween = item.tween :: Tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not item.buying then
			removeItem(player, id)
		end
	end)
	sendState(player)
end

local function clearCarpet(player: Player)
	local carpet = carpets[player]
	if not carpet then
		return
	end
	for id in carpet.items do
		removeItem(player, id)
	end
end

-- Plaza drop ---------------------------------------------------------------------------------------------

local function dropState(): Remotes.PlazaDropState?
	local d = drop
	if not d then
		return nil
	end
	return {
		listing = toPublic(d.listing),
		endsAt = d.endsAt,
		x = Config.Layout.PLAZA_DROP_BELT.x,
		z = Config.Layout.PLAZA_DROP_BELT.z,
	}
end

local function clearDrop()
	local d = drop
	drop = nil
	if d and d.model then
		d.model:Destroy()
	end
	Remotes.PlazaDrop:fireAll(nil)
end

local function nearPlazaBelt(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local b = Config.Layout.PLAZA_DROP_BELT
	return (root.Position - Vector3.new(b.x, root.Position.Y, b.z)).Magnitude
		<= Config.Shop.PLAZA_DROP_BUY_RADIUS
end

function ShopService.buyPlazaDrop(player: Player, id: string): boolean
	local d = drop
	if not d or d.listing.id ~= id or d.listing.sold then
		Remotes.Notify:fireClient(player, "warn", "Too late! Someone else got it.")
		return false
	end
	if not nearPlazaBelt(player) then
		Remotes.Notify:fireClient(player, "warn", "Get to the plaza belt to buy the drop!")
		return false
	end
	local reason = blockReason(player, d.listing.price)
	if reason then
		Remotes.Notify:fireClient(player, "warn", reason)
		return false
	end
	if not EconomyService.spend(player, d.listing.price) then
		return false
	end
	d.listing.sold = true -- claim first so a second buyer in the same frame loses
	local brainrot = Roll.newBrainrot(
		BrainrotService.newId(),
		d.listing.speciesId,
		d.listing.variant :: Types.VariantId,
		player.UserId,
		os.time()
	)
	if not BrainrotService.give(player, brainrot) then
		EconomyService.grant(player, d.listing.price)
		d.listing.sold = false
		return false
	end
	local name = if d.model then d.model.Name else "the drop"
	clearDrop()
	Remotes.Notify:fireAll("drop", `{player.DisplayName} grabbed the plaza drop: {name}!`)
	return true
end

local function startDrop()
	serial += 1
	local listing = ShopStock.plazaDrop(rng, `drop{serial}`)
	if not listing then
		return
	end
	local world = workspace:FindFirstChild("World")
	local belt = world and world:FindFirstChild("PlazaDropBelt") :: BasePart?
	local model: Model? = nil
	if belt then
		local m =
			Brainrot.create(listing.speciesId, listing.rarity, listing.variant, { price = listing.price })
		m:PivotTo(belt.CFrame * CFrame.new(0, belt.Size.Y / 2, 0))
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = `Buy {Format.price(listing.price)}`
		prompt.ObjectText = "Plaza drop"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = Config.Shop.PLAZA_DROP_BUY_RADIUS
		prompt.RequiresLineOfSight = false
		prompt.Parent = m.PrimaryPart
		local id = listing.id
		prompt.Triggered:Connect(function(who)
			ShopService.buyPlazaDrop(who, id)
		end)
		m.Parent = belt
		model = m
	end
	drop = {
		listing = listing,
		endsAt = workspace:GetServerTimeNow() + Config.Shop.PLAZA_DROP_DURATION,
		model = model,
	}
	Remotes.PlazaDrop:fireAll(dropState())
	local name = if model then model.Name else listing.speciesId
	Remotes.Notify:fireAll("drop", `PLAZA DROP: {listing.rarity} {name}! First to buy it wins.`)
end

function ShopService.init() end

function ShopService.start()
	nextDropAt = workspace:GetServerTimeNow() + Config.Shop.PLAZA_DROP_INTERVAL
	DataService.sessionReady:connect(function(player)
		sendState(player)
		Remotes.PlazaDrop:fireClient(player, dropState())
	end)
	BaseService.assigned:connect(function(player)
		carpets[player] = { items = {}, nextSpawnAt = workspace:GetServerTimeNow() + 1 }
		sendState(player)
	end)
	BaseService.released:connect(function(player)
		clearCarpet(player)
		carpets[player] = nil
	end)
	Remotes.BuyListing:connect(function(player, id)
		ShopService.buy(player, id)
	end)
	Remotes.BuyPlazaDrop:connect(function(player, id)
		ShopService.buyPlazaDrop(player, id)
	end)
	CycleService.phaseChanged:connect(function(phase)
		if phase == "Night" then
			clearDrop()
			for player in carpets do
				clearCarpet(player)
			end
		elseif phase == "Day" then
			nextDropAt = workspace:GetServerTimeNow() + Config.Shop.PLAZA_DROP_INTERVAL
		end
		for _, player in Players:GetPlayers() do
			sendState(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		clearCarpet(player)
		carpets[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = workspace:GetServerTimeNow()
			if CycleService.shopOpen() then
				for player, carpet in carpets do
					if now >= carpet.nextSpawnAt then
						carpet.nextSpawnAt = now + Config.Shop.CARPET_SPAWN_SECONDS
						spawnOnCarpet(player)
					end
				end
			end
			local d = drop
			if d and now >= d.endsAt then
				clearDrop()
			elseif not d and CycleService.phase() == "Day" and now >= nextDropAt then
				nextDropAt = now + Config.Shop.PLAZA_DROP_INTERVAL
				startDrop()
			end
		end
	end)
end

return ShopService
