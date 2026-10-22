--!strict
-- Conveyor shop (approved Q3 hybrid): every player has their own belt with stock that rotates on a shared clock,
-- and every few minutes of Day a server-wide Rare+ drop appears on the plaza belt (first to buy it there wins).
-- Belt and plaza drop are closed at night (approved Q1).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Roll = require(ReplicatedStorage.Shared.Logic.Roll)
local ShopStock = require(ReplicatedStorage.Shared.Logic.ShopStock)
local Types = require(ReplicatedStorage.Shared.Types)

local BrainrotModel = require(script.Parent.Parent.World.BrainrotModel)
local Builder = require(script.Parent.Parent.World.Builder)
local Entitlements = require(script.Parent.Parent.Entitlements)
local BaseService = require(script.Parent.BaseService)
local BrainrotService = require(script.Parent.BrainrotService)
local CycleService = require(script.Parent.CycleService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local ShopService = {}

type Stock = { rotation: number, listings: { ShopStock.Listing } }
type Drop = { listing: ShopStock.Listing, endsAt: number, model: Model? }

local random = Random.new()
local function rng(): number
	return random:NextNumber()
end

local stocks: { [Player]: Stock } = {}
local drop: Drop? = nil
local nextDropAt = 0
local dropSerial = 0

local function rotationIndex(): number
	return workspace:GetServerTimeNow() // Config.Shop.ROTATION_SECONDS
end

local function toPublic(l: ShopStock.Listing): Types.PublicListing
	return {
		id = l.id,
		speciesId = l.speciesId,
		rarity = l.rarity :: Types.RarityId,
		price = l.price,
		incomePerSec = l.incomePerSec,
		sold = l.sold,
	}
end

local function ensureStock(player: Player): Stock
	local index = rotationIndex()
	local stock = stocks[player]
	if stock and stock.rotation == index then
		return stock
	end
	local fresh: Stock = {
		rotation = index,
		listings = ShopStock.generate(rng, tostring(index), Entitlements.luck(player)),
	}
	stocks[player] = fresh
	return fresh
end

local function sendState(player: Player)
	if not DataService.isSessionReady(player) then
		return
	end
	local stock = ensureStock(player)
	local listings: { Types.PublicListing } = {}
	for _, l in stock.listings do
		table.insert(listings, toPublic(l))
	end
	Remotes.ShopState:fireClient(player, {
		listings = listings,
		nextRotationAt = (stock.rotation + 1) * Config.Shop.ROTATION_SECONDS,
		open = CycleService.shopOpen(),
	})
end

-- Why a purchase can't happen, in player-facing words (nil = OK).
local function blockReason(player: Player, price: number): string?
	if not CycleService.shopOpen() then
		return "The belt is closed for the night. It opens at dawn!"
	end
	if not BaseService.plotOf(player) then
		return "Pick a base first!"
	end
	if not BrainrotService.hasFreePedestal(player) then
		return "Base full! Free up a pedestal first."
	end
	if not EconomyService.canAfford(player, price) then
		return "Not enough cash yet."
	end
	return nil
end

local renderBelt: (Player) -> ()

function ShopService.buy(player: Player, listingId: string): boolean
	local stock = stocks[player]
	if not stock or stock.rotation ~= rotationIndex() then
		Remotes.Notify:fireClient(player, "warn", "That stock just rotated. Take another look!")
		sendState(player)
		return false
	end
	local listing: ShopStock.Listing? = nil
	for _, l in stock.listings do
		if l.id == listingId then
			listing = l
		end
	end
	if not listing or listing.sold then
		sendState(player)
		return false
	end
	local reason = blockReason(player, listing.price)
	if reason then
		Remotes.Notify:fireClient(player, "warn", reason)
		return false
	end
	if not EconomyService.spend(player, listing.price) then
		return false
	end
	local brainrot =
		Roll.newBrainrot(BrainrotService.newId(), listing.speciesId, "None", player.UserId, os.time())
	local placed = BrainrotService.give(player, brainrot)
	if not placed then
		-- Shouldn't happen (checked above); refund rather than lose the cash.
		EconomyService.grant(player, listing.price)
		return false
	end
	listing.sold = true
	sendState(player)
	renderBelt(player)
	local species = Config.Species.byId[listing.speciesId]
	Remotes.Notify:fireClient(player, "good", `{species.displayName} joined your base!`)
	return true
end

-- In-world belt: unsold listings stand on the conveyor with a buy prompt (walk-up buying).
function renderBelt(player: Player)
	local refs = BaseService.refsFor(player)
	if not refs then
		return
	end
	refs.beltItems:ClearAllChildren()
	local stock = ensureStock(player)
	local open = CycleService.shopOpen()
	for i, listing in stock.listings do
		if not listing.sold then
			local model = BrainrotModel.build(
				listing.speciesId,
				"None",
				{ showIncome = true, tag = Format.price(listing.price) }
			)
			model:ScaleTo(0.75)
			model:PivotTo(Builder.beltSlot(refs, i, #stock.listings))
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = `Buy {Format.price(listing.price)}`
			prompt.ObjectText = Config.Species.byId[listing.speciesId].displayName
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Enabled = open
			prompt.Parent = model.PrimaryPart
			local id = listing.id
			prompt.Triggered:Connect(function(who)
				if who == player then
					ShopService.buy(player, id)
				end
			end)
			model.Parent = refs.beltItems
		end
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

local function startDrop()
	dropSerial += 1
	local listing = ShopStock.plazaDrop(rng, `drop{dropSerial}`)
	if not listing then
		return
	end
	local belt = workspace:FindFirstChild("World")
		and (workspace :: any).World:FindFirstChild("PlazaDropBelt") :: BasePart?
	local model: Model? = nil
	if belt then
		local m = BrainrotModel.build(listing.speciesId, "None", { tag = Format.price(listing.price) })
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
	local species = Config.Species.byId[listing.speciesId]
	Remotes.Notify:fireAll(
		"drop",
		`PLAZA DROP: {listing.rarity} {species.displayName}! First to buy it wins.`
	)
end

local function nearPlazaBelt(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local b = Config.Layout.PLAZA_DROP_BELT
	local offset = root.Position - Vector3.new(b.x, root.Position.Y, b.z)
	return offset.Magnitude <= Config.Shop.PLAZA_DROP_BUY_RADIUS
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
	d.listing.sold = true -- claim before anything else so a second buyer in the same frame loses
	local brainrot =
		Roll.newBrainrot(BrainrotService.newId(), d.listing.speciesId, "None", player.UserId, os.time())
	if not BrainrotService.give(player, brainrot) then
		EconomyService.grant(player, d.listing.price)
		d.listing.sold = false
		return false
	end
	local species = Config.Species.byId[d.listing.speciesId]
	clearDrop()
	Remotes.Notify:fireAll("drop", `{player.DisplayName} grabbed the plaza drop: {species.displayName}!`)
	return true
end

function ShopService.init() end

function ShopService.start()
	nextDropAt = workspace:GetServerTimeNow() + Config.Shop.PLAZA_DROP_INTERVAL
	DataService.sessionReady:connect(function(player)
		sendState(player)
		Remotes.PlazaDrop:fireClient(player, dropState())
	end)
	BaseService.assigned:connect(function(player)
		renderBelt(player)
	end)
	BaseService.released:connect(function(_, refs)
		refs.beltItems:ClearAllChildren()
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
		end
		if phase == "Day" then
			nextDropAt = workspace:GetServerTimeNow() + Config.Shop.PLAZA_DROP_INTERVAL
		end
		for _, player in Players:GetPlayers() do
			sendState(player)
			renderBelt(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		stocks[player] = nil
	end)

	task.spawn(function()
		local lastRotation = rotationIndex()
		while true do
			task.wait(1)
			local index = rotationIndex()
			if index ~= lastRotation then
				lastRotation = index
				for _, player in Players:GetPlayers() do
					sendState(player)
					renderBelt(player)
				end
			end
			local now = workspace:GetServerTimeNow()
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
