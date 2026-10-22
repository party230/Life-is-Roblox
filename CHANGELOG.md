# Changelog

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
