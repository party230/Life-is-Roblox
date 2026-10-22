# Mockup generator

Phase 1 design mockups are drawn as SVG in the browser and rendered to PNG. Output goes to `assets/mockups/`.

```
cd tools/mockups
npm install            # playwright-core only
node render.mjs        # all pages, day + night, plus 00-overview.png
node render.mjs hud    # one page
```

`render.mjs` uses `CHROMIUM_PATH` if set, otherwise a Playwright headless shell under `/opt/pw-browsers`,
otherwise Playwright's default browser.

- `core.js`: palette, day/night lighting (`L()`), SVG and isometric helpers, UI pieces, loyalty hearts, page frame
- `creatures.js`: the 12 species, moods (happy, content, uneasy, rogue, sleepy) and mutation overlays
- `scene.js`: isometric base diorama, avatar, feral and tree sprites
- `screens.js`: one function per page (`hud`, `shop`, `inspect`, `base`, `map`, `concept`, `overview`)

Fonts: Fredoka and Nunito (SIL OFL, licences in `fonts/`). Fredoka is close to Roblox's built-in Fredoka One.
