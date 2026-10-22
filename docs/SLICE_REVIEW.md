# Vertical slice: how to open it and what to screenshot

## Open it in Studio
1. Pull the branch `claude/rot-shift-roblox-game-zaokoh`.
2. In the repo: `rokit install` (or `scripts/install-tools.sh`), then `wally install` (fetches Fusion).
3. `rojo serve`
4. In Studio: **File → New → Baseplate**. Delete the default **Baseplate** part and **SpawnLocation**
   (the slice builds its own). Then open the Rojo plugin → **Connect**. Accept the sync.
5. Check that **Lighting → Technology** shows **Future** (Rojo sets it). If Studio kept the template's
   value, set it by hand.
6. *(Optional, for saves)* Game Settings → Security → **Enable Studio Access to API Services**. Studio
   uses its own `PlayerData_studio_v1` store and tops your cash up to $1,000,000 so you can buy anything.
7. Press **Play** (F5).

## What you should see
- You spawn as your own avatar in your base (auto-claimed; the gate sign shows your name).
- Brainrots step out of the purple portal at the back and walk down the red carpet with nameplates
  (variant, name, rarity, $/s, price). New one every ~4 s. Unbought ones vanish at the end.
- Walk up to one and hold the prompt to **Buy**: it walks to a pedestal and the pedestal rim lights up in
  its rarity colour. Your income starts; walk over the yellow **COLLECT** pad to bank it.
- Day HUD: cash + income/s, the cycle timer with phase bar, and 6 buttons (Shop and Eggs work; the rest say
  which phase brings them).
- The plaza (follow the path out of the gate) has the **Egg Shop** stall (green floating label, blue/white
  awning) with a merchant. Its prompt opens the
  Eggs screen.
- Nameplates shrink with distance like the reference: variant / name / rarity / $/s / price, white text with
  a thick black outline.
- The escape lane: coloured obby blocks out of the gap in the right wall.
- **Day/Night**: press **N** or click the **DEV: Day ⇄ Night** button at the bottom. Night switches the
  lighting, closes the carpet and eggs, and swaps the HUD to the night buttons + BONK.

## Screenshot checklist (please send these)
1. Spawn view of the base in **day**: carpet, portal, pedestals, gate (third-person, a bit zoomed out).
2. Close-up of a brainrot **walking on the carpet**, nameplate readable.
3. One shot of each character: **Tralalero Tralala, Tung Tung Tung Sahur, Bombardiro Crocodilo,
   Ballerina Cappuccina, Brr Brr Patapim, Cappuccino Assassino** (close enough to judge the likeness).
4. Each **variant** you catch: **Rainbow** (colour bands scrolling upward; try to catch it walking, with
   its trail) and **Evil** (black, glowing red eyes, red lightning flickering around it). Variant odds are
   boosted in the slice, so you'll see them quickly.
5. The **Buy prompt** and the brainrot **on a pedestal** after buying (rim lit).
6. The **day HUD** full screen, ideally once on a phone-sized window too: Studio → Test → Device emulator.
7. The **Shop** panel (Shop button) and the **Eggs** screen (Egg Stall prompt).
8. The **plaza with the Egg Stall** and merchant.
9. The **escape lane** exit.
10. The same base view at **night** (press N), plus the night HUD.
11. **Holding the Bonk Bat** (it's in your backpack: press 1) and swinging it. Check the bat points up and out
    of your hand, not sideways.
12. Anything that looks broken (floating parts, wrong facing, unreadable text) with the Output window
    visible.

If anything errors, a screenshot of the **Output** window is the most useful thing you can send.
