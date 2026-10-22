# v3 update: design proposal (awaiting owner feedback)

Scope (from the owner's update): a bigger map with 12 bases round a central hub, a shared conveyor, nursery +
loyalty, and a food shop. Nothing here is implemented yet. After feedback, the work goes in this order: map →
shared conveyor → food shop → loyalty/runaway → nursery/growth → stolen-return rule → monetisation.

Renders: `assets/mockups/v3/`. In-world shots come from `tools/preview/design/map.luau`, which uses the real
Parts helpers and character models through the world renderer. UI screens come from `tools/mockups/v3/`.

| Image | Shows |
|---|---|
| `design-map-topdown.png` | the 12-base ring, hub, spokes, meadow decor, escape lanes |
| `design-hub.png`, `design-hub-close.png`, `design-hub-night.png` | the shared carpet loop, central portal, Egg Shop + Food Shop, leaderboards, event stage, trade zone, hangout |
| `design-base-nursery-unlocked.png`, `design-nursery-interior.png` | your base with the nursery open |
| `design-base-nursery-locked.png` | a neighbour's base with the nursery locked |
| `design-owner-overlay.png` / `-others.png` | the owner's loyalty bar + runaway timer (normal / low / leaving tonight) vs what other players see |
| `design-base-owner-view.png` | the overlay in context, with the tighter nameplates |
| `ui-food-feasts.png`, `ui-food-premium.png` | Food Shop UI |
| `ui-nursery.png`, `ui-nursery-locked.png` | Nursery UI + unlock dialog |

## 1. Map (proposed numbers → Config/Layout)

| | Value | Why |
|---|---|---|
| Bases | 12, gates facing the hub, at 30° steps | server size 12 |
| Gate radius | 230 studs | gate → nearest carpet edge = **191 studs ≈ 12 s** at WalkSpeed 16 (target 10–15 s) |
| Hub plaza | radius 84 | carpet loop (radius 34, 10 wide) + six features in a ring around it |
| Base footprint | 64 × 84 | main hall with 14 pedestals + nursery across the back |
| Map | ~750 studs across | grass meadow between spokes, 12 spoke paths with lamps, ring road at the gates |
| Decor | 6 landmark types × 2 (pond + bridge, pizza statue, windmill, cup fountain, picnic, playground) + trees, bushes, rocks, flower beds, benches | "big but never empty" |

**Escape lanes:** coloured obby tiles plus a jump pad in an arc between each pair of neighbouring bases' side
exits. A thief can run along the ring of lanes, or cut across the hub. Cutting across the hub resets the +1 speed stack
and tells the owner which brainrot is being carried (the Q8 rule).

**Nameplates (§1.4):**
- 5.6 studs wide, 0.72-stud lines, hidden beyond 60 studs. Your own brainrots stay visible to 140.
- Pedestals are 12 studs apart in a row, so plates never touch side by side.

## 2. Shared conveyor

- One central portal on an island. Brainrots walk a ramp onto a 330° carpet loop, counter-clockwise, and
  despawn at an exit vortex.
- First to buy gets it. A Rare+ spawn gets a server-wide banner (the old plaza drop).
- Per-base carpets and portals are removed.

## 3. Loyalty, runaway, growth (proposed → Config/Loyalty, Config/Nursery)

- **Income multiplier from loyalty:** piecewise linear, ×0.5 at 0 → ×1 at 50 → ×2 at 100.
- **Time trickle:** +1 loyalty per in-game hour owned, up to +6 per in-game day. **Neglect:** −3 per in-game day
  with no feed.
- **Runaway timer:**
  - Every brainrot starts with 2 in-game days. Food stacks, capped at 60 days.
  - It only ticks while the owner is in a server.
  - 1 in-game day = one full Day+Dusk+Night+Vote cycle ≈ 12.8 min at current cycle lengths.
  - At 0 the brainrot is "leaving tonight" and runs at mid-night.
  - Catch it (touch/BONK) → it goes home with −10 loyalty and the timer reset to the 2-day minimum.
- **Overlay colours:** white ≥ 1 day, yellow < 1 day, red pill "LEAVING TONIGHT!".
- **Stolen brainrots:**
  - They keep their loyalty to the original owner. At ≥ `RETURN_HOME_THRESHOLD` = 70 they run home at
    mid-night, and the thief can catch them on the way.
  - Otherwise they start at 15 loyalty with the new owner.
- **Growth:**
  - Baby → Teen at 40 growth points, Teen → Adult at 100 more.
  - Size ×0.5 / ×0.75 / ×1. Income ×0.4 / ×0.7 / ×1.
  - Babies and Teens can sit on pedestals.
- **Bond Collar:** pauses the timer on up to 2 brainrots; loyalty doesn't grow while paused.

## 4. Food shop

Every value is as given by the owner; the full table will live in `Config/Food.luau`.
- Tabs: Snacks 1–4, Meals 5–9, Feasts 10–14 (cash or Robux), Premium 15–18 (Robux only).
- Quantities: ×1/×5/×10 for cash; ×1/×5 for Robux.
- Food goes to an inventory and is fed from a pedestal/incubator prompt or from Inspect, with "feed ×N".

## 5. Nursery + monetisation (proposed)

- **Unlock:** $250,000, or skip for 99 R$ (dev product).
- **Incubators:** 3 free + 3 game-pass tiers (99 / 149 / 199 R$).
- **Removed:** Treat Packs.
- **Added:** dev products for foods 10–18 (one per price and bundle), Nursery Unlock skip, incubator passes.
- Nothing purchasable stops stealing, reveals other players' loyalty or guarantees a catch.

## Open questions

1. Robux ×5 bundles: exactly 5× the price, or a small discount?
2. Nursery unlock: is a flat $250K right, or should it scale with progress?
3. Growth: food only, or also a slow passive trickle?
4. Nonna's Secret Recipe on a brainrot already on a pedestal: does it just become an Adult there?
5. A "best for your income" highlight in the Food Shop?
6. Balance note: at current incomes a Common earns ~$770 per in-game day, so even the cheapest foods cost
   more than a Common earns. That makes food worth it mainly on Rare+ brainrots. The prices stay as given (the
   owner asked to keep this scale). Flagging it in case low-rarity brainrots should simply be allowed to run away.
