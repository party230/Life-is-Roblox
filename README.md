# Rot Shift (working title)

Raise brainrots by day, defend them by night. A Roblox game in strict Luau.

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder
   (or `scripts/install-tools.sh`, which drops the same pinned tools into `.tools/bin`).
2. `wally install`: fetches packages into `Packages/` (Fusion).
3. `rojo serve`, then connect from the Rojo plugin in Studio. Or build a place file:
   `rojo build -o build/RotShift.rbxl`.

## Checks

```
scripts/check.sh        # StyLua check, Selene, Rojo build, luau-lsp strict type-check, unit tests
scripts/check.sh --fix  # same, but formats with StyLua first
```

CI (`.github/workflows/ci.yml`) runs the same script on every push.

## Layout

```
src/
  server/   init.server.luau (bootstrap), Services/, Vendor/ProfileStore
  client/   init.client.luau (bootstrap), Controllers/, UI/
  shared/   Config/ (all tunables), Types/, Util/, Remotes/, Data/ (save template + migrations)
assets/     mockups/, concept/
tests/      *.spec.luau, run under Lune (`lune run tests/run.luau`)
```

## Conventions

- `--!strict` in every file.
- Every balance number lives in `src/shared/Config/`. `Config/Validate.luau` checks it at boot and in tests.
- The server decides everything. Clients only send intents through `Remotes`. Every client→server remote
  declares an argument Guard and a rate limit.
- Pure logic goes in `src/shared` with string requires (`require("./X")`) so the tests can load it.
  Server and client code require shared modules by instance (`require(ReplicatedStorage.Shared.Config)`).

See `DECISIONS.md` for the reasoning behind these choices and `CHANGELOG.md` for progress.
