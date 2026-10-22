# Brainrot model contract

Game logic never touches a character's parts. It only sees a `Model` that follows this contract, so a
character can switch from the part-built kit to an imported MeshPart model by changing **one row** in
`src/shared/Config/Species.luau` (its `model` key).

## Model keys (Config/Species)

| Key | Source |
|---|---|
| `"<id>"` | Part builder at `src/shared/World/Models/Characters/<id>.luau` (uses `Kit`) |
| `"mesh:<name>"` | Imported model at `ReplicatedStorage.Assets.Brainrots.<name>`, run through `Kit.adopt` |
| `nil` / disabled | Per-rarity Mystery placeholder (`Models/Placeholder.luau`) |

`Models.build(def)` resolves the key. If a `mesh:` asset is missing, the placeholder is used, so a typo
never breaks a save or a carpet.

## What every model has

- **`PrimaryPart` = `Root`**: anchored, invisible, non-colliding. Its pivot is at the feet (ground
  contact), facing -Z. The server moves only this part.
- **Attachments on Root**: `Nameplate` (above the head), `Vfx` (centre of the body), `TrailA` / `TrailB`
  (for the Rainbow trail).
- **Motor6D `Anim`** from Root to `Body`. The client idles/walks the model by setting `Anim.Transform`.
- Every other part is **welded to Body** (or to a part welded to it), unanchored, `CanCollide = false`,
  `Massless = true`.
- **Optional Motor6Ds named `Spinner`** (propellers, wheels). The client spins them.
- **Per-part attributes**: `Role` (`skin`, `eye`, `pupil`, `detail`, `glow`) drives the variant recolour,
  and `BaseColor` stores the Normal colour so variants can be re-applied.
- **Model attributes**: `Hover` (studs above the ground, for flyers), `Idle` (`bob`, `sway`, `fly`,
  `twirl`).

`tests/Models.spec.luau` checks all of this for every model key in Config, plus `Kit.adopt` on a plain
model.

## Swapping in a MeshPart version

1. Build or import the character in Studio as a `Model` of MeshParts (no scripts). Name the eye parts
   `Eye…` and pupils `Pupil…` so Dark gets red eyes. The largest part becomes `Body`. Mark other parts
   with a `Role` attribute if you want to control how variants recolour them.
2. Right-click → **Save to File** as `assets/models/<name>.rbxm`. Rojo syncs it to
   `ReplicatedStorage.Assets.Brainrots.<name>`.
3. In `Config/Species.luau`, change that character's model key to `"mesh:<name>"`. Optionally set the
   `Hover` / `Idle` attributes on the saved model.
4. Run `scripts/check.sh`. The contract test covers the part-built keys; check the mesh one in Studio.

Nothing else changes: nameplates, variants, carpet walking, pedestals, saves and income all go through the
contract. No Creator Store models are inserted without the owner's say-so (D20 §4).
