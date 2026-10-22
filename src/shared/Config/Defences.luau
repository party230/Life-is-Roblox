--!strict
-- Night defences that slot into base sockets (§4.5). Destroyed defences rebuild at Dawn.

export type DefenceDef = {
	id: string,
	displayName: string,
	cashPrice: number,
	health: number,
	range: number, -- studs
	cooldown: number, -- seconds between activations
	knockback: number, -- studs pushed per hit (Slap Turret)
	slowMult: number, -- walk speed multiplier applied to ferals in range (Sticky Floor)
	repelRadius: number, -- ferals avoid this radius (Rot Repellent)
}

local list: { DefenceDef } = {
	{
		id = "slapturret",
		displayName = "Slap Turret",
		cashPrice = 750,
		health = 100,
		range = 14,
		cooldown = 1.5,
		knockback = 12,
		slowMult = 1,
		repelRadius = 0,
	},
	{
		id = "stickyfloor",
		displayName = "Sticky Floor",
		cashPrice = 400,
		health = 60,
		range = 8,
		cooldown = 0,
		knockback = 0,
		slowMult = 0.4,
		repelRadius = 0,
	},
	{
		id = "rotrepellent",
		displayName = "Rot Repellent",
		cashPrice = 1_200,
		health = 80,
		range = 0,
		cooldown = 0,
		knockback = 0,
		slowMult = 1,
		repelRadius = 10,
	},
}

local byId: { [string]: DefenceDef } = {}
for _, def in list do
	byId[def.id] = table.freeze(def)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	SOCKETS_PER_BASE = 4,
	BONK_COOLDOWN = 0.6,
	BONK_RANGE = 7,
})
