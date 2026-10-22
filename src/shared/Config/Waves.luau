--!strict
-- Night wave composition (§4.5). `at` is seconds into the night. Feral counts scale per player present.

export type FeralDef = {
	id: string,
	health: number,
	walkSpeed: number,
	bonksToStun: number,
}

export type WaveDef = {
	at: number,
	ferals: { [string]: number }, -- feralId -> count per player
}

local ferals: { [string]: FeralDef } = {
	grub = table.freeze({ id = "grub", health = 2, walkSpeed = 10, bonksToStun = 2 }),
	sprinter = table.freeze({ id = "sprinter", health = 1, walkSpeed = 18, bonksToStun = 1 }),
	brute = table.freeze({ id = "brute", health = 6, walkSpeed = 7, bonksToStun = 5 }),
}

local waves: { WaveDef } = {
	{ at = 10, ferals = { grub = 2 } },
	{ at = 60, ferals = { grub = 2, sprinter = 1 } },
	{ at = 120, ferals = { grub = 3, sprinter = 2 } },
	{ at = 180, ferals = { grub = 2, sprinter = 2, brute = 1 } },
}

return table.freeze({
	ferals = table.freeze(ferals),
	waves = table.freeze(waves),
	MAX_ALIVE = 40, -- server-wide cap for performance
	PEDESTAL_KNOCKOUT = true, -- reaching a pedestal stops its income for the rest of the night
	SURVIVE_REWARD_BASE = 250,
	SURVIVE_REWARD_PER_PARTICIPATION = 0.75, -- extra reward fraction at 100% participation
})
