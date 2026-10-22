# v3 build: how to open it in Studio and what to screenshot

This covers the v3 update: the 12-base map, the shared conveyor, food, loyalty and runaways, the nursery, and
monetisation. The game still runs in **slice mode** (`Config.Game.VERTICAL_SLICE = true`):
- you claim a base automatically when you join
- the clock is frozen at midday (press **N** to switch Day/Night)
- variant odds are boosted
- only the six modelled characters spawn

Runaway timers still tick in real time while you're in the server: 1 in-game day ≈ 12.8 minutes.

## Open it in Studio
1. Pull the branch `claude/rot-shift-roblox-game-zaokoh`.
2. In the repo: `rokit install` (or `scripts/install-tools.sh`), then `wally install` (fetches Fusion).
3. `rojo serve`
4. In Studio: **File → New → Baseplate**. Delete the default **Baseplate** and **SpawnLocation**, then
   open the Rojo plugin → **Connect** and accept the sync.
5. Check that **Lighting → Technology** is **Future** (Rojo sets it).
6. *(Optional, for saves)* Game Settings → Security → **Enable Studio Access to API Services**. Studio uses its
   own `PlayerData_studio_v1` store and tops your cash up to $1,000,000. Old Studio saves migrate to v4
   automatically: existing brainrots become Adults with a 2-day timer.
7. Press **Play** (F5). For the multiplayer checks, use **Test → Clients and Servers** with 2 players.

## Studio-only test buttons (bottom of the screen)
- **DEV: Day ⇄ Night (N)**: switches the phase. In slice mode, **midnight** comes about 4 seconds after you
  switch to Night.
- **DEV: expire my timers**: runs every one of your brainrots' timers out. They're "leaving tonight" within a
  second.
- **DEV: midnight now**: makes every "leaving tonight" brainrot run immediately.

## Walkthrough (what should happen)
1. **Map:** you spawn in your base (gate sign "<you>'s Base"). Walk out of the gate and follow the spoke to
   the hub, about 12 s. Between the bases and the hub: lamps, trees, benches, ponds, a windmill, a pizza statue
   and other landmarks.
2. **Shared conveyor:** brainrots step out of the purple portal in the middle of the hub, walk the red loop and
   vanish into the vortex at the end.
   - Walk up to one and hold **Buy**: it appears on one of your pedestals.
   - The **Shop** button lists the carpet, but buying from it only works within about 16 studs of the
     brainrot.
   - A Rare+ shows a banner over the portal and a toast for everyone. Every 3 minutes of Day there's a
     guaranteed **featured** Rare+.
3. **Food Shop:** use the hub stall with the orange "Food Shop" label.
   - Tabs: Snacks / Meals / Feasts / Premium, with **x1/x5/x10**.
   - One card shows a yellow **BEST FOR YOU** badge.
   - Buy some Pizza Slices; the inventory strip shows them.
   - Robux buttons say "isn't set up yet" until the dev product ids are filled in `Config/Products.luau`.
4. **Owner overlay:** over each of *your* brainrots, the nameplate has a **pink loyalty bar with a heart** and a
   **long green timer bar** under it.
   - The timer bar drains over time, turns yellow at 25% and red at 10%.
   - Nameplates fade beyond about 60 studs; yours stay visible to about 140.
5. **Feeding:** walk up to one of your brainrots and press **Feed**. The card shows growth, loyalty with its
   income multiplier, and the timer bar.
   - Pick a food, set the quantity and press **FEED xN**. The timer bar refills and loyalty goes up.
6. **Runaway:**
   - Press **DEV: expire my timers**. Your brainrots start **fidgeting**, turning toward the hub, and you
     get "will run away tonight" toasts.
   - Feed one of them: it calms down.
   - Press **N** (Night), or **DEV: midnight now**. The rest jump off their pedestals with a red
     **RUNAWAY!** label and run out of the gate toward the hub.
   - **Catch one** by touching it or swinging the **Bonk Bat** at it (press 1 to equip, click to swing). It
     goes back to its pedestal and loses 10 loyalty.
   - Let another reach the carpet: it walks the loop with a price, and **anyone** can buy it, even at night.
7. **Nursery:**
   - The Base button, or the door prompt at the back of your base, opens the **unlock dialog**. The price scales
     with your best income ($25K minimum).
   - Unlock it: the bars disappear and the room turns pink with incubator domes.
   - Buy an egg at the **Egg Shop**: it sits on an incubator with a countdown. **HATCH** it from the Eggs or
     Nursery screen.
   - A small **Baby** with a "Baby" line on its nameplate appears in the pen. Tap it in the Nursery screen, feed
     it Lasagna until it becomes a **Teen** (bigger), then use **To a pedestal**.
8. **Privacy (2 players):** in **Clients and Servers**, look at the other player's base. Their nameplates have
   **no hearts and no bars**, and you get no Feed prompt on their brainrots.

## Screenshot checklist (please send these)
1. **Your base** from the gate, with the owner rows over your brainrots.
2. **Close-up** of one brainrot's nameplate showing the heart + loyalty bar and the long timer bar.
3. The same brainrot after **DEV: expire my timers**: red / empty bar, fidgeting.
4. A **runaway running** out of the gate with its RUNAWAY! label, and the moment you **catch it** (toast).
5. A runaway **walking the hub carpet** with a price.
6. The **hub** from above the gate path: portal, carpet loop, Egg Shop and Food Shop.
7. The **Food Shop** screen on two tabs (Snacks and Feasts), with the **BEST FOR YOU** badge visible.
8. The **brainrot card** (Feed screen) with a food selected and the gain preview.
9. The **Nursery unlock dialog**, then the **open nursery** with an egg hatching and a baby in the pen.
10. A **Baby** next to an **Adult** of the same character (size difference).
11. **Second player's view** of your base (no bars, no hearts).
12. The **top of the map**: zoom out on a spoke between the hub and the bases (decor, lanes).
13. Anything broken (floating parts, wrong facing, unreadable text) with the **Output** window visible.

If anything errors, a screenshot of the **Output** window is the most useful thing you can send.

## Not in this build (later phases)
- **Stealing** (Phase 3). Picking up a brainrot, escape runs and the hub-shortcut speed reset aren't built yet.
  The **stolen-return rule** is built and tested (`Logic/Loyalty.steal` / `nightDecision`, and the
  run-home with the thief's catch in LoyaltyService), and it switches on once stealing exists.
- **Robux purchases** need real product and pass ids in `Config/Products.luau`.
- Leaderboards show placeholders. Trading and the event stage are decoration for now.
