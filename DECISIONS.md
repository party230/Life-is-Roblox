# Decisions

Calls made while building, with the reason. Newest at the bottom of each phase.

## Phase 0: Setup

**D1. Toolchain pinned with Rokit**, plus `scripts/install-tools.sh` that downloads the same versions straight
from GitHub releases (used by CI). Versions: Rojo 7.4.4, Wally 0.3.2, Selene 0.28.0, StyLua 2.0.2,
Lune 0.10.4, luau-lsp 1.70.1.

**D2. UI library: Fusion 0.3.** Fusion's reactive state fits a HUD full of live numbers (cash ticking,
timers, loyalty meters), it's typed and works under `--!strict`, and it's lighter than React-Lua (no
reconciler or JSX-style element trees). Easy to change until Phase 2, when the first real screens get built.

**D3. Tests: TestEZ-style specs run under Lune**, not TestEZ inside Studio. `tests/Harness.luau` has the
same `describe`/`it`/`expect(x).to.equal` API, so specs run headless in CI in under a second. Specs import
the harness explicitly rather than relying on injected globals, which keeps them type-checkable. Only pure
logic is unit-tested. Services that touch the engine get tested by playtesting.

**D4. Module requires.** Pure modules in `src/shared` use Luau require-by-string (`"./X"`, `"@self/X"`),
which works in both Roblox and Lune. Code in `server`/`client` requires shared modules by instance, because
the trees live under different services. Rule: anything we want to unit-test goes in `shared`. That's
why the save template and migrations are in `shared/Data` (no secrets in them).

**D5. Strict type-checking in CI** with `luau-lsp analyze` (Roblox definitions + Rojo sourcemap). This goes
beyond the spec's lint + test, and it catches type errors before Studio ever sees them.

**D6. ProfileStore is vendored** at `src/server/Vendor/ProfileStore.luau` (Apache-2.0, license alongside)
instead of being installed through Wally. It isn't published on the Wally index, and it's a single file
that changes rarely. `DataService` wraps it in a narrow local type, because ProfileStore's
`JSONAcceptable` intersection types don't unify with our `PlayerData` under strict mode.

**D7. Networking: plain RemoteEvents behind `shared/Remotes`.** No third-party networking library. Every
remote is declared in one file (`Remotes/init.luau`) with its payload type. Every client→server remote
carries a `Guard` (argument validator) and a token-bucket rate limit. Rejected calls count toward an abuse
threshold that kicks the player (`Config/Network.luau`). There are no RemoteFunctions yet: request/response
will be events plus a server reply, which avoids yielding on clients.

**D8. Selene std overlay** (`rotshift.yml`, `std = "rotshift+roblox"`). This lets `require` take a
string, since selene's Roblox std predates require-by-string.

**D9. Config shape.** Every module returns frozen tables. Lists that need lookup expose both
`list` (ordered) and `byId`. Rarity colours are hex strings (`Color3.fromHex` in UI), so Config stays
loadable outside the engine. Weighted rolls use an injected RNG (`Util/WeightedRandom`) for seeded
tests.

**D10. Income formula** (proposed): `BASE_INCOME_PER_SEC × species.incomeFactor × rarity.incomeMult ×
mutation.incomeMult`. The 2× Income pass multiplies this base income only, not event or wave rewards.

**D11. Values I added beyond §8, all in Config and flagged for your balance review:**
- `MAX_SLOTS = 14` (8 + three Extra Slot passes × 2).
- Rarity `carrySpeedMult` (Common 1.0 → Secret 0.7). This is the "rarity weight" part of the carry penalty.
- Mutation odds and multipliers: Golden 5% ×2, Glitched 2% ×3, Rainbow 1% ×5, Tiny 4% ×0.8 (carries
  faster), Mega 3% ×1.5 (carries slower).
- Rarity weights, shop prices, egg odds, defence stats, feral stats, wave timings, Rotter cooldowns and
  rewards.

**D12. Rot Pass premium is a dev product, not a game pass.** Game passes are owned forever, but the Rot Pass
is a 30-day season. A dev product can be bought again each season. The save will record which season
each purchase applies to (Phase 8).

**D13. Save layout.** `pedestals` is a map keyed by slot string (`"1"`..`"N"`), because DataStore JSON can't
hold sparse arrays. Brainrots are a map by GUID. `grantedReceipts` is a bounded list of receipt ids for
idempotent `ProcessReceipt`. The store is named `PlayerData_v1`. Schema changes go through
`shared/Data/Migrations.luau`. The store is never renamed except for a deliberate wipe.

**D14. Placeholder species** (12 original names in `Config/Species.luau`) so systems have data to work on.
The Phase 1 concept sheet replaces the names and looks after your feedback.

## Phase 1: Mockups

**D15. Mockups are generated, not hand-drawn.** They're SVG built in code and rendered to PNG, so feedback
rounds are quick edits, and the creature shapes can serve as a reference when the 3D models get built.

**D16. Proposed species (replace the Phase 0 placeholders once approved):** Mugpup, Toasturtle and Sockodile
(Common); Lampingo and Brollybun (Uncommon); Fridgehog and Kettlephant (Rare); Cartshark and Owlarm (Epic);
Pianoceros (Legendary); Spinwhale (Mythic); Tellama (Secret). Each one is an everyday object + an animal + a
face. Before launch, the names still need a trademark/store search.

**D17. Secret rarity colour.** Flat black (#141414) disappears on night UI. Proposal: a black chip with a
rainbow rim. This needs `Config/Rarities.luau` to carry a style flag, not just a hex.

**D18. Loyalty readability.** 5 hearts that fill in proportion. Under 30 they turn purple-grey, crack and
shake. Stolen brainrots wear a mask icon. Uneasy brainrots sweat, glance sideways, and think of a little
house. Rogue ones get red eyes and a purple aura.

**D19. HUD button budget (max 6).** Day: Shop, Eggs, Base, Trade, Store, Menu. Night: Shop, Defend, Base,
Store, Menu, BONK. Roblox's own controls aren't counted.

## Direction change (after Phase 1): real 3D Roblox game + meme roster

Requested by the owner. Each item below overrides the noted part of SPEC.md or an earlier decision.

**D20. Presentation: a normal 3D Roblox experience** (overrides the isometric look of the Phase 1 mockups).
Players are their own R15 avatars with default controls, animations and camera (free orbit, zoom-out cap
kept from Q2). The world is classic Roblox: studded Plastic surfaces, bright saturated blocks, Future
lighting with a sky, atmosphere, bloom and sun rays (set in `default.project.json`, since scripts can't set
`Lighting.Technology`). The mockups stay the reference for HUD/screen layouts only
(`assets/mockups/README.md`).

**D21. Character roster: 50 Italian-brainrot meme characters** (overrides SPEC §2's "original designs only"
IP rule; replaces D14/D16). Each is modelled to look like its well-known meme version. Legal rails, per the
owner's §6:
- Names, rarities and model keys live only in `Config/Species.luau`. Logic and saves use stable snake_case
  ids, so a character can be renamed or swapped in one place.
- A `disabled` flag (per row, or the `DISABLED` set) removes a character from carpets, eggs and drops.
  Owned copies resolve to a per-rarity "Mystery" placeholder at runtime (`Logic/Catalog.resolve`), keep
  their rarity's income, and come back if re-enabled. Saves are never rewritten.
- `LEGAL_REVIEW.md` lists all 50, and Phase 10 has a review item. Models avoid real-world brand marks.

**D22. Variants replace mutations**: Normal ×1, Gold ×1.5, Diamond ×2, Rainbow ×4, Dark ×6 (odds and
multipliers in `Config/Variants.luau`; carpet price scales with the variant too). Tiny/Mega are gone.
Saves migrate v1 → v2 (`mutation` → `variant`: Golden→Gold, Rainbow→Rainbow, others→Normal). Old
original-species ids resolve to placeholders, nothing lost.

**D23. Rogue must not look like Dark.** Dark = recoloured (black/purple palette), glowing red eyes, smoke,
a slow leaning idle. Rogue (Phase 4) = violent shaking + an angry icon on the nameplate + a red outline,
with **no colour change**. The shake is already in the client animator, keyed off the `Rogue` attribute.

**D24. Buying is physical: the red carpet.** Each base has a spawn portal at the back. A brainrot steps
out every `CARPET_SPAWN_SECONDS` and walks the carpet over `CARPET_WALK_SECONDS` with its price on the
nameplate. Buy it with its ProximityPrompt and it walks to your first free pedestal. Unbought ones vanish
at the end. This replaces the rotating 5-item belt. The Shop panel stays as a list of what's on your
carpet right now (same buy action). Carpets stop at night (Q1).

**D25. Part-based rigged models** (first pass; mesh pipeline proposed in `docs/MESH_PIPELINE.md`, decision
pending). Every model follows one rig (`World/Models/Kit.luau`):
- an anchored invisible Root (PrimaryPart) with Nameplate/Vfx/Trail attachments
- a Motor6D `Anim` to the Body
- everything else welded to the Body; propellers get their own Motor6D

The server moves only the anchored Root (TweenService), so replication is one CFrame per brainrot. All
idle/walk motion, propeller spin, rainbow hue cycling and the trail run client-side by driving
`Motor6D.Transform` (`BrainrotAnimator`). Phase 10 note: move carpet walking client-side too if many
carpets run at once.

**D26. Vertical slice mode** (`Config.Game.VERTICAL_SLICE = true`):
- builds one plot plus the plaza and stall
- auto-claims the plot on join (no picker)
- freezes the cycle at midday
- spawns only modelled characters (`REQUIRE_BUILT_MODELS`), with boosted variant odds so every variant
  shows up quickly

Flip both flags off after approval.

**D27. Studio uses its own DataStore** (`PlayerData_studio_v1`) and tops cash up to `STUDIO_DEV_CASH`, so
playtesting can buy Mythics without touching live data.

**D28. Day/Night dev toggle**: Studio-only `DevSetPhase` remote (ignored on live servers), on the **N** key
or a small dev button. It switches the server phase, so lighting replicates and night closures actually
apply.

**D29. Headless model preview** (`tools/preview`): Lune builds every character with `@lune/roblox` and a
tiny software renderer draws contact sheets (`assets/previews/`). This catches builder errors and bad
silhouettes without Studio. It also found that Lune's `CFrame.lookAt` disagrees with Roblox, so limbs use
an explicit basis (`CFrame.fromMatrix`) that's correct in both.

**D30. Plaza Egg Stall** is the first physical shop: a ProximityPrompt with attribute `Opens = "Eggs"`
opens the Eggs screen. Future stalls use the same attribute.

**D31. Phase 2 work done ahead of the change** (server economy, income/collection, offline income, eggs,
plaza drop, HUD/shop UI) is kept and powers the slice. Phase 2 itself resumes only after the slice is
approved.

## Style reference pass (owner's reference images)

**D32. The slice matches the owner's style reference** (`assets/reference/style.png`):
- a blue studded baseplate
- a 10-stud red studded carpet with no trim
- dark-grey buildings with neon strips and windows
- a blue/white-awning stall on a stone platform with a green "Egg Shop" label
- a portal screen ("NEW BRAINROTS EVERY FEW SECONDS!")
- voxel trees around the ring
- a vivid purple, starry night

Nameplates are world-scaled (they shrink with distance, like the reference), FredokaOne with a thick black
stroke. Each line is colour-coded: variant, name (white), rarity (rarity colour; a rainbow gradient for
Secret), $/s (yellow) and price (green). The camera is unchanged: the default Roblox camera with the zoom
cap already matched.

**D33. Starter Bonk Bat.** The reference shows players holding a bat, so every player gets a "Bonk Bat"
Tool in StarterPack. For now it only swings, rate-limited by `Defences.BONK_COOLDOWN`. Hits come with
night defence (Phase 5).

**D34. Mesh-ready kit; mesh pipeline on hold.** Per the owner: stay part-built through the slice and
Phase 2. A model key of `"mesh:<name>"` loads an imported model from `ReplicatedStorage.Assets.Brainrots`.
`Kit.adopt` then fits it to the same rig contract, so any character can be swapped without touching game
logic (`docs/MODEL_CONTRACT.md`, enforced by `tests/Models.spec.luau`).

**D35. Character reference images.** The six character references arrived as remote URLs. This
environment can't reach those hosts, so they weren't saved, and the per-character comparison waits until
the images are attached or committed as `assets/reference/<id>.png`. Cappuccino Assassino was added as
the 6th slice character, built **provisionally** from the commonly known version. It gets rebuilt from
its reference once that arrives.

