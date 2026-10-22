--!strict
-- Server entry point: validates Config, then runs init() on every service in order, then start().

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Validate = require(ReplicatedStorage.Shared.Config.Validate)

type Service = { init: () -> (), start: () -> () }

local result = Validate.run(Config)
for _, message in result.warnings do
	warn(`[Config] {message}`)
end
if #result.errors > 0 then
	error(`[Config] invalid config:\n{table.concat(result.errors, "\n")}`)
end

local Services = script.Services
-- Order matters: DataService first, everything else depends on loaded saves.
local services: { Service } = {
	require(Services.DataService) :: Service,
	require(Services.CycleService) :: Service,
	require(Services.BaseService) :: Service,
	require(Services.BrainrotService) :: Service,
	require(Services.EconomyService) :: Service,
	require(Services.ShopService) :: Service,
	require(Services.EggService) :: Service,
	require(Services.FoodService) :: Service,
	require(Services.NurseryService) :: Service,
	require(Services.StealService) :: Service,
	require(Services.LoyaltyService) :: Service,
	require(Services.NightService) :: Service,
	require(Services.RotterService) :: Service,
	require(Services.TradeService) :: Service,
	require(Services.MonetizationService) :: Service,
	require(Services.EventsService) :: Service,
}

for _, service in services do
	service.init()
end
for _, service in services do
	task.spawn(service.start)
end

if RunService:IsStudio() and workspace:GetAttribute("RunSmokeTests") == true then
	local SmokeTests = require(script.Dev.SmokeTests) :: { run: () -> () }
	SmokeTests.run()
end
