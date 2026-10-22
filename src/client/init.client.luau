--!strict
-- Client entry point: runs init() on every controller, then start().

type Controller = { init: () -> (), start: () -> () }

local Controllers = script.Controllers
local controllers: { Controller } = {
	require(Controllers.DataController) :: Controller,
}

for _, controller in controllers do
	controller.init()
end
for _, controller in controllers do
	task.spawn(controller.start)
end
