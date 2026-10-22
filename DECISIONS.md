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
