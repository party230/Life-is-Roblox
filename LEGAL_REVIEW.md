# Legal review: character roster

Every character in the game, for review **before publishing** (Phase 10 checklist). This is a tracking
sheet, not legal advice: have someone qualified review it.

Context: the roster is based on popular "Italian brainrot" internet meme characters, chosen by the project
owner (DECISIONS D21, an override of SPEC §2's original-designs rule). The owner flagged that some are under
active trademark/copyright disputes, **Tung Tung Tung Sahur** especially. Rails in the code:

- Names and models live only in `src/shared/Config/Species.luau`. Logic and saves use stable ids, so any
  character can be renamed or re-modelled in one place.
- `disabled = true` (or listing the id in `DISABLED` in that file) pulls a character from carpets, eggs and
  drops. Owned copies show as their rarity's "Mystery" placeholder and keep earning. Saves are untouched, so
  re-enabling restores them.
- Models carry no real-world brand marks (e.g. no shoe logo on Tralalero Tralala, no national insignia on
  Bombardiro Crocodilo).

Status keys: **Model**: built (part-based) / not built. **Reference**: provided in `assets/reference/` or
*missing* (built from the commonly known version).

| # | Id | Name | Rarity | Model | Reference | Review notes | Cleared? |
|---|---|---|---|---|---|---|---|
| 1 | `bobrito_bandito` | Bobrito Bandito | Common | not built | n/a |  | [ ] |
| 2 | `trulimero_trulichina` | Trulimero Trulichina | Common | not built | n/a |  | [ ] |
| 3 | `frulli_frulla` | Frulli Frulla | Common | not built | n/a |  | [ ] |
| 4 | `talpa_di_ferro` | Talpa Di Ferro | Common | not built | n/a |  | [ ] |
| 5 | `pipi_kiwi` | Pipi Kiwi | Common | not built | n/a |  | [ ] |
| 6 | `pipi_corni` | Pipi Corni | Common | not built | n/a |  | [ ] |
| 7 | `penguino_cocosino` | Penguino Cocosino | Common | not built | n/a |  | [ ] |
| 8 | `salamino_pinguino` | Salamino Pinguino | Common | not built | n/a |  | [ ] |
| 9 | `agarrini_la_palini` | Agarrini La Palini | Common | not built | n/a |  | [ ] |
| 10 | `svinino_bombondino` | Svinino Bombondino | Common | not built | n/a |  | [ ] |
| 11 | `lirili_larila` | Lirili Larila | Uncommon | not built | n/a |  | [ ] |
| 12 | `boneca_ambalabu` | Boneca Ambalabu | Uncommon | not built | n/a |  | [ ] |
| 13 | `burbaloni_luliloli` | Burbaloni Luliloli | Uncommon | not built | n/a |  | [ ] |
| 14 | `orangutini_ananasini` | Orangutini Ananasini | Uncommon | not built | n/a |  | [ ] |
| 15 | `spioniro_golubiro` | Spioniro Golubiro | Uncommon | not built | n/a |  | [ ] |
| 16 | `zibra_zubra_zibralini` | Zibra Zubra Zibralini | Uncommon | not built | n/a |  | [ ] |
| 17 | `bananita_dolphinita` | Bananita Dolphinita | Uncommon | not built | n/a |  | [ ] |
| 18 | `tigroligre_frutonni` | Tigroligre Frutonni | Uncommon | not built | n/a |  | [ ] |
| 19 | `rhino_toasterino` | Rhino Toasterino | Uncommon | not built | n/a |  | [ ] |
| 20 | `brr_brr_patapim` | Brr Brr Patapim | Rare | built | *missing* |  | [ ] |
| 21 | `trippi_troppi` | Trippi Troppi | Rare | not built | n/a |  | [ ] |
| 22 | `chimpanzini_bananini` | Chimpanzini Bananini | Rare | not built | n/a |  | [ ] |
| 23 | `bombombini_gusini` | Bombombini Gusini | Rare | not built | n/a |  | [ ] |
| 24 | `cappuccino_assassino` | Cappuccino Assassino | Rare | built (provisional) | *missing* |  | [ ] |
| 25 | `frigo_camelo` | Frigo Camelo | Rare | not built | n/a |  | [ ] |
| 26 | `glorbo_fruttodrillo` | Glorbo Fruttodrillo | Rare | not built | n/a |  | [ ] |
| 27 | `tric_trac_baraboom` | Tric Trac Baraboom | Rare | not built | n/a |  | [ ] |
| 28 | `cavallo_virtuoso` | Cavallo Virtuoso | Rare | not built | n/a |  | [ ] |
| 29 | `ballerina_cappuccina` | Ballerina Cappuccina | Epic | built | *missing* |  | [ ] |
| 30 | `girafa_celeste` | Girafa Celeste | Epic | not built | n/a |  | [ ] |
| 31 | `cocofanto_elefanto` | Cocofanto Elefanto | Epic | not built | n/a |  | [ ] |
| 32 | `graipuss_medussi` | Graipuss Medussi | Epic | not built | n/a |  | [ ] |
| 33 | `chef_crabracadabra` | Chef Crabracadabra | Epic | not built | n/a |  | [ ] |
| 34 | `elefantino_frigorifero` | Elefantino Frigorifero | Epic | not built | n/a |  | [ ] |
| 35 | `orcalero_orcala` | Orcalero Orcala | Epic | not built | n/a |  | [ ] |
| 36 | `tigrullini_watermelini` | Tigrullini Watermelini | Epic | not built | n/a |  | [ ] |
| 37 | `bombardiro_crocodilo` | Bombardiro Crocodilo | Legendary | built | *missing* |  | [ ] |
| 38 | `bombardino_gusini` | Bombardino Gusini | Legendary | not built | n/a |  | [ ] |
| 39 | `tralalita_tralala` | Tralalita Tralala | Legendary | not built | n/a |  | [ ] |
| 40 | `chicleteira_bicicleteira` | Chicleteira Bicicleteira | Legendary | not built | n/a |  | [ ] |
| 41 | `trenostruzzo_turbo_3000` | Trenostruzzo Turbo 3000 | Legendary | not built | n/a |  | [ ] |
| 42 | `los_orcalitos` | Los Orcalitos | Legendary | not built | n/a |  | [ ] |
| 43 | `tralalero_tralala` | Tralalero Tralala | Mythic | built | *missing* |  | [ ] |
| 44 | `tung_tung_tung_sahur` | Tung Tung Tung Sahur | Mythic | built | *missing* | Owner flagged an active trademark/copyright dispute. | [ ] |
| 45 | `la_vaca_saturno_saturnita` | La Vaca Saturno Saturnita | Mythic | not built | n/a |  | [ ] |
| 46 | `nuclearo_dinossauro` | Nuclearo Dinossauro | Mythic | not built | n/a |  | [ ] |
| 47 | `los_bombinitos` | Los Bombinitos | Mythic | not built | n/a |  | [ ] |
| 48 | `los_tralaleritos` | Los Tralaleritos | Secret | not built | n/a |  | [ ] |
| 49 | `las_tralaleritas` | Las Tralaleritas | Secret | not built | n/a |  | [ ] |
| 50 | `la_grande_combinasion` | La Grande Combinasion | Secret | not built | n/a |  | [ ] |

## Built without a reference image

These were modelled from the commonly known meme versions. The owner sent reference images as remote
links, but they couldn't be downloaded here, so they're still missing from `assets/reference/`:

- Tralalero Tralala, Tung Tung Tung Sahur, Bombardiro Crocodilo, Ballerina Cappuccina, Brr Brr Patapim,
  Cappuccino Assassino

## Reference images

The reference images are third-party fan art and stills taken from the web. They stay in the repo **only as
modelling references** and never ship in the game. Before publishing, check that nothing in a model copies
a specific artist's work closely enough to need permission.
