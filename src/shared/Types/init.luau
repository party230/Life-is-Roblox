--!strict
-- Shared data shapes. Saved shapes (PlayerData, Brainrot) must stay JSON-safe: no Instances, Vector3s,
-- or mixed/sparse arrays. Bump PlayerData.version and add a migration when changing a saved shape.

export type RarityId = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"
export type VariantId = "Normal" | "Rainbow" | "Evil"
export type CyclePhase = "Day" | "Dusk" | "Night" | "DawnVote"

export type Brainrot = {
	id: string, -- GUID
	speciesId: string, -- stable id from Config/Species (may later be disabled: shown as its rarity's placeholder)
	rarity: RarityId, -- stored so a disabled/removed character still resolves to the right placeholder
	variant: VariantId,
	incomePerSec: number, -- cached from species/rarity/variant; recomputed on load
	ownerUserId: number,
	originalOwnerUserId: number?, -- set when stolen
	loyalty: number, -- 0..Loyalty.MAX toward the current owner (owner-private)
	oldLoyalty: number?, -- loyalty toward originalOwnerUserId (decays per night; >= RETURN_HOME_THRESHOLD runs home)
	acquiredAt: number, -- unix seconds
	lastInteractedAt: number, -- unix seconds
	isStolen: boolean,
	lowLoyaltySince: number?, -- unix seconds loyalty dropped below ROGUE_THRESHOLD (Rogue, Phase 4)
	bondCollared: boolean, -- Bond Collar: runaway timer paused, loyalty doesn't grow
	-- Runaway timer (in-game days, ticks only while the owner is online; owner-private)
	timerDays: number, -- left
	timerFullDays: number, -- value at the last fill (the owner's bar shows timerDays / timerFullDays)
	leaving: boolean, -- timer ran out: runs away at the middle of the next night unless fed
	sinceFedDays: number, -- in-game days since the last feed (neglect)
	-- Growth (Baby -> Teen -> Adult by points; see Config/Nursery)
	growth: number,
	inNursery: boolean, -- living in the nursery pen (not on a pedestal, not in storage)
}

export type PendingEgg = {
	id: string,
	eggId: string,
	startedAt: number,
	hatchSeconds: number,
}

export type PlayerStats = {
	steals: number,
	timesStolenFrom: number,
	rottersCaught: number,
	timesRotter: number,
	rotterWins: number,
	nightsSurvived: number,
	defectionsWon: number,
	totalEarned: number,
	peakIncome: number, -- best income/s ever (scales the nursery unlock price)
}

export type PlayerSettings = {
	musicVolume: number,
	sfxVolume: number,
	reducedMotion: boolean,
}

export type PlayerData = {
	version: number,
	cash: number,
	uncollectedCash: number,
	brainrots: { [string]: Brainrot }, -- by id
	pedestals: { [string]: string }, -- slot index ("1".."N") -> brainrot id
	eggs: { PendingEgg }, -- in nursery incubators
	food: { [string]: number }, -- food id -> count
	nurseryUnlocked: boolean,
	lastOnlineAt: number, -- unix seconds; 0 = never
	streak: { count: number, lastClaimDay: number },
	stats: PlayerStats,
	settings: PlayerSettings,
	baseName: string, -- filtered with TextService before saving
	-- Receipt ids already granted, newest last, bounded (ProcessReceipt idempotency).
	grantedReceipts: { string },
	activeBoosts: { [string]: number }, -- boost key -> expires at (unix seconds)
}

-- Client-visible subset sent over the network.
export type PublicBrainrot = {
	id: string,
	speciesId: string, -- already resolved (placeholder id if disabled)
	rarity: RarityId,
	variant: VariantId,
	incomePerSec: number, -- effective (after loyalty and growth stage)
	isStolen: boolean,
	slot: number?, -- pedestal slot, nil = storage or nursery
	stage: string, -- "Baby" | "Teen" | "Adult"
	growth: number,
	inNursery: boolean,
	-- owner-private (only ever in the owner's own snapshot)
	loyalty: number,
	timerDays: number,
	timerFullDays: number,
	leaving: boolean,
	bondCollared: boolean,
}

export type PublicEgg = {
	id: string,
	eggId: string,
	readyAt: number, -- unix seconds (os.time)
}

export type PublicListing = {
	id: string,
	speciesId: string,
	variant: VariantId,
	rarity: RarityId,
	price: number,
	incomePerSec: number,
	sold: boolean,
	featured: boolean?, -- the guaranteed Rare+ featured spawn
	runaway: boolean?, -- a runaway that rejoined the carpet (anyone can buy it)
}

return {}
