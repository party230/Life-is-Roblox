--!strict
-- One call to make a complete brainrot: character model + variant look + nameplate, tagged "Brainrot"
-- so the client animator picks it up. Used by the server for carpet, pedestal and drop brainrots.

local CollectionService = game:GetService("CollectionService")

local Models = require(script.Parent.Models)
local Nameplate = require(script.Parent.Nameplate)
local Variants = require(script.Parent.Variants)

local Brainrot = {}

export type Options = {
	price: number?, -- shows the price line (carpet)
	stage: string?, -- growth stage; Baby / Teen get a public stage line on the nameplate
}

function Brainrot.create(speciesId: string, rarity: string, variant: string, opts: Options?): Model
	local model = Models.build(speciesId, rarity)
	Variants.apply(model, variant)
	Nameplate.attach(model, speciesId, rarity, variant, opts)
	model:SetAttribute("Walking", false)
	CollectionService:AddTag(model, "Brainrot")
	return model
end

return Brainrot
