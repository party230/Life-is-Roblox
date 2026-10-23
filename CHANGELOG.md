# Changelog

## v3: bigger map, shared conveyor, food, loyalty + runaways, nursery (awaiting Studio feedback)

- **Map:** 12 bases in a ring around a central hub (gate to carpet ≈ 12 s).
  - Spokes with lamps; a meadow with trees, benches and six landmark types.
  - Escape lanes between neighbouring bases.
  - A nursery in every base.
- **Shared conveyor:** one portal and carpet loop for everyone, first to buy. Rare+ banner; a featured Rare+
  every 3 minutes of Day; runaways rejoin it.
- **Food Shop:** 18 foods (owner's table), cash x1/x5/x10, Robux x1/x5 (10% off), a Best-for-you badge,
  inventory, feeding from a prompt or the brainrot card.
- **Loyalty and runaway timer:**
  - Owner-only loyalty bar and one long timer bar on your nameplates (green → yellow 25% → red 10%).
  - Income ×0.5–×2 from loyalty.
  - "Leaving tonight" fidget, midnight runaways to the carpet, catch by touch or BONK.
  - Stolen brainrots run home if still loyal.
- **Nursery:** progress-scaled unlock or a Robux skip, incubators (3 + passes), Babies grow to Teens and
  Adults (bigger, earning more) from food and slowly over time; move to a pedestal at any stage.
- **Monetisation:** Nursery Unlock skip, Robux food bundles and Extra Incubator passes added; Treat Packs
  removed; the Bond Collar now pauses the timer; idempotent receipts.
- **Save v4:** migration with tests. New tests for the timer, the runaway/return decision, income, growth and
  food pricing (116 tests).
- **Fixes:**
  - Runaways pathfind (PathfindingService) round pedestals and walls instead of walking in a straight line.
  - A runaway earns nothing from the moment it starts running, and earns again only if caught.
  - The Bonk Bat swing now works (each player's copy is hooked).
  - Disabled labels are no longer drawn in previews.
- **Previews:** real-code world renders in `assets/previews/world-*.png`; Studio steps and screenshot
  checklist in `docs/SLICE_REVIEW.md`.

## v3 design round (awaiting feedback)

- **Design renders** for the 12-base ring and hub map, the shared conveyor, the nursery (locked and unlocked)
  and the owner-only loyalty/runaway overlay, plus Food Shop and Nursery UI mockups, all in
  `assets/mockups/v3/`.
- Proposed numbers and open questions are in `docs/DESIGN_V3.md`; the overrides are logged as D37.
- **Preview tooling:**
  - shared headless runtime (`tools/preview/runtime.luau`)
  - design-only map builder (`tools/preview/design/`)
  - renderer: top-down orthographic shots, per-shot frames, bars/pills, an owner-only row toggle, map labels
- **Preview fix:** nameplates now sit above the heads. Lune keeps `Attachment.Position` separate from `CFrame`,
  so they were drawn at body height; the slice world renders are redone.

## Variant redesign

- Variants are now **Normal, Rainbow (×4) and Evil (×6)**; Gold and Diamond are gone, and Normal takes
  their odds (D36).
- Rainbow: 7 bright bands, top to bottom, scrolling upward. Evil: black, glowing red eyes, red lightning
  flickering around it (client-only), red glow.
- Save migration v2 → v3 (Gold/Diamond → Normal, Dark → Evil) with tests. New tests for the Rainbow bands,
  the Evil look and the lightning generator.
- Previews re-rendered with the new variants.

## Style reference pass (awaiting Studio feedback)

- **World matched to `assets/reference/style.png`:**
  - blue studded floor; 10-wide red studded carpet
  - dark neon-trimmed walls with windows
  - Egg Shop stall with a blue/white awning and a green floating label
  - portal screen; voxel trees
  - purple starry night (Sky, Atmosphere, per-phase lighting)
- **Nameplates rewritten:** world-scaled, thick black stroke, colour-coded lines.
- **Bonk Bat tool** in StarterPack (swing only).
- **Cappuccino Assassino added** as the 6th slice character (provisional, no reference yet).
- **Mesh-ready models:**
  - `"mesh:<name>"` model keys and `Kit.adopt` bring imported models into the rig contract
  - `docs/MODEL_CONTRACT.md` documents the contract
  - `tests/Models.spec.luau` checks it
- **Previews:** re-rendered (6 characters × 5 variants), with before/after composites in `assets/previews/`.
- **Fix: brainrots no longer sink halfway into the carpet and pedestals.** Roblox ignores `Model.WorldPivot`
  once a PrimaryPart is set, so `PivotTo` put the Root's centre on the ground. The Root's `PivotOffset` now
  puts the pivot at the feet, and the carpet walk uses it. The contract test checks this.
- **World preview** (`tools/preview/world.luau` + `world.mjs`):
  - runs the real `Builder.build()` and `Brainrot.create` headless in Lune
  - draws the result with three.js in headless Chromium
  - shots of the base, the carpet, the Egg Shop and the overview, by day and night, in
    `assets/previews/world-*.png`

## Vertical slice (Phase 1 redo, awaiting feedback)

- Direction change logged (DECISIONS D20–D31): real 3D Roblox presentation, a 50-character meme roster,
  variants, the red carpet conveyor.
- `Config/Species.luau`: all 50 characters with stable ids, rarities, model keys, reference paths and
  `disabled` support. `Config/Variants.luau` replaces mutations. Save migration v1 → v2.
- `Logic/Catalog.luau`: name/disable resolution with per-rarity placeholders; only spawnable characters roll.
- Part-based rigged models for Tralalero Tralala, Tung Tung Tung Sahur, Bombardiro Crocodilo, Ballerina
  Cappuccina and Brr Brr Patapim, plus the Mystery placeholder. All 5 variants with effects. Nameplates:
  variant / name / rarity / $/s / price.
- Client `BrainrotAnimator`: bob/sway/fly/twirl idles, walking waddle, propellers, rainbow cycling + trail,
  Dark idle, Rogue shake hook.
- World rebuilt in classic Roblox style: studded baseplate, a base with spawn portal + red carpet +
  round pedestals + collector + escape lane, and the plaza with the Egg Stall and merchant. Future
  lighting, sky, atmosphere, bloom.
- Carpet shop: spawn, walk, buy by prompt, walk to a pedestal. Eggs screen (Fusion) opened from the stall.
  Day HUD with all 6 buttons, night HUD with BONK. Studio Day/Night toggle (N).
- Headless preview tool (`tools/preview`) with contact sheets in `assets/previews/`.
- `LEGAL_REVIEW.md`, `docs/MESH_PIPELINE.md` (proposal, awaiting decision), `docs/SLICE_REVIEW.md`
  (Studio steps + screenshot checklist).

## Phase 1: Mockups (awaiting feedback)

- 13 PNGs in `assets/mockups/`: HUD, conveyor shop, inspect panel, base layout, map overview and the
  12-species concept sheet, each in day and night lighting, plus `00-overview.png` with everything side by side.
- `tools/mockups/`: SVG-in-browser generator so mockups can be re-rendered after feedback.
- Studio smoke tests (`src/server/Dev/SmokeTests.luau`, opt-in through a Workspace attribute): ProfileStore
  save → read back → reload, plus a check that the player's save loaded.
- Removed legacy `Workspace.FilteringEnabled` and the redundant `Players` defaults from the Rojo project
  (a blank-place sync could choke on them).

## Phase 0: Setup

- Project scaffold: Rojo project (`default.project.json`), Rokit tool pins, Wally manifest (Fusion),
  Selene + StyLua config, `.luaurc` strict mode, VS Code settings.
- `scripts/check.sh`: StyLua check → Selene → Rojo build → luau-lsp strict type-check → Lune unit tests.
  `scripts/install-tools.sh` + GitHub Actions CI running the same gate.
- Config modules: `Game` (all §8 values), `Rarities`, `Mutations`, `Species` (12 placeholders), `Shop`,
  `Eggs`, `Defences`, `Waves`, `Rotter`, `Products` (placeholder ids), `Network`. Plus `Validate`,
  which runs at server boot and in tests.
- Shared types for brainrots, saves and network snapshots.
- Utilities: `WeightedRandom` (seedable), `RateLimiter` (token bucket), `Signal`, `Guard` (remote argument
  validation).
- Typed remotes (`shared/Remotes`) with per-remote guards, rate limits and abuse kicks.
- Data: ProfileStore (vendored) behind `DataService`, covering session lock, GDPR user id, reconcile,
  versioned migrations, and a snapshot sent to the client. Save template + migration runner.
- Server/client bootstraps with ordered `init`/`start`. Service stubs for every system, each tagged with the
  phase that builds it.
- 34 unit tests (config integrity, RNG, rate limiter, signal, guards, template, migrations).
