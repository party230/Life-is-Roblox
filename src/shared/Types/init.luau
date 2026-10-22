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
	loyalty: number, -- 0..LOYALTY_MAX toward current owner
	oldLoyalty: number?, -- loyalty toward originalOwnerUserId (decays per night)
	acquiredAt: number, -- unix seconds
	lastInteractedAt: number, -- unix seconds
	isStolen: boolean,
	loyaltyTimeToday: number, -- minutes of time-owned loyalty gained today (for LOYALTY_DAILY_TIME_CAP)
	loyaltyDay: number, -- unix day number loyaltyTimeToday refers to
	lowLoyaltySince: number?, -- unix seconds loyalty dropped below ROGUE_THRESHOLD
	bondCollared: boolean,
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
	eggs: { PendingEgg },
	treats: number,
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
	incomePerSec: number,
	loyalty: number,
	isStolen: boolean,
	slot: number?, -- pedestal slot, nil = in storage
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
}

return {}
