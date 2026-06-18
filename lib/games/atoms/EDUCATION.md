# EDUCATION.md — Atoms (cell)

> The educational blocks that occupy the Atoms scale, and which game(s) engage each.
> Source data: `lib/data/scales/atoms_entities.dart` (5 blocks).
> **The learning arc:** particles → quarks/electrons are the lego bricks; **atoms → those bricks
> assemble into the first named elements**, forged in the Big Bang and in stars, ultimately
> building the molecules of a potato.

- **Scale (cell):** atoms
- **Games on this scale:**
  - `atom_builder` — game-1, canonical, strong edu tie.
  - `starch_factory` — game-2, variety slot, ⚠️ thematic tie (amyloplast / starch / carbon
    chains). Docs at `lib/games/atoms/starch_factory/`. Not yet registered in the game registry.

---

## Blocks

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Hydrogen | The First Atom | One proton, one electron — forged in the Big Bang; fuel of every star. | `atom_builder` | ✅ Z=1, the starting proton; first shell to fill |
| Carbon | The Versatile Backbone | Six protons, four bonding electrons — the backbone of all organic chemistry and every starch molecule. | `atom_builder` | ⚠️ reachable (Z=6, Shell 1 complete at He then onto Ne), but not called out by name |
| Oxygen | The Reactive Essential | Eight protons — makes water, respiration, and fire possible. | `atom_builder` | ⚠️ reachable (Z=8, just before Ne checkpoint), not named |
| Nitrogen | The Atmospheric Reservoir | Seven protons; N₂'s triple bond is the bottleneck of all biology; first fertilizer nutrient banked. | `atom_builder` | ✅ explicitly banked — reaching Z=7 triggers "NITROGEN BANKED 🥔" + bonus |
| Phosphorus | The Energy Broker | Fifteen protons; DNA backbone, ATP energy currency, limiting nutrient of world agriculture. | `atom_builder` | ✅ explicitly banked — reaching Z=15 triggers "PHOSPHORUS BANKED 🥔" + bonus |

### Strength notes

**Hydrogen ✅** — The game literally starts here. You build your first proton and your first
electron. Proton count = 1 is Hydrogen, and the element name displays in the target panel
(`HYDROGEN · H`). The mechanics of one proton + one electron in Shell 1 are the definition of
the block.

**Carbon ⚠️** — You pass through Z=6 on the way to the Neon checkpoint (Z=10). The target panel
shows `CARBON · C` when you have 6 protons collected, so the name surfaces. But the game doesn't
highlight carbon's *four bonding electrons* or its role as the backbone of starch — it's a
waypoint, not a teaching moment. The WOW flare (see below) can fill this gap.

**Oxygen ⚠️** — Same situation: you pass Z=8, the name shows as `OXYGEN · O`, and that's it.
Oxygen's role in water and respiration is not engaged. WOW flare opportunity.

**Nitrogen ✅** — The fertilizer system makes this explicit: the first time your proton count
hits 7, a banner fires — "NITROGEN BANKED 🥔" — and +25 points are credited. This is more than
cosmetic; it teaches that Nitrogen is element 7 *and* that it's a fertilizer the potato needs.

**Phosphorus ✅** — Same as Nitrogen: Z=15 triggers "PHOSPHORUS BANKED 🥔." Reinforces P as a
plant macronutrient.

> **Gap to note:** Sulfur (Z=16, symbol S) is also in the fertilizer bonus set (`_kNutrientAtomicNumbers`
> has `'S': 16` and `'K': 19`), but Sulfur and Potassium are **not** education blocks on this
> scale. They appear as gameplay bonuses — which is fine and enriches the potato tie — but the
> EDUCATION ledger only covers the 5 declared blocks.

---

## The WOW layer — cosmic provenance flare ✅ BUILT

> Status: implemented in `atom_builder.dart` + `atom_provenance.dart`.
> Shell-ring preview also implemented. See below for original proposal.

**Proposal:** analogous to the Particles discovery timeline, the Atoms scale should surface each
element's **cosmic origin** — where it was forged and what it does for a potato — on the moment
the element name first appears in the target panel (i.e. when proton count first hits that Z value).

Recommended data (the 5 blocks + the 2 fertilizer-bonus elements for completeness):

| Z | Element | Forged in | Potato role |
|---|---|---|---|
| 1 | Hydrogen | Big Bang (380,000 yr after) | Water; every organic molecule; the star-fuel chain that grew your potato |
| 6 | Carbon | Red giant stars (triple-alpha process) | Backbone of glucose, starch, cellulose, DNA |
| 7 | Nitrogen | Stellar cores + supernova ejecta | Amino acids, chlorophyll, DNA — the "N" in N-P-K fertilizer |
| 8 | Oxygen | Stellar fusion (CNO cycle) | Water (H₂O); respiration; the soil's oxidizing chemistry |
| 15 | Phosphorus | Supernova nucleosynthesis (s/r-process) | ATP bonds, DNA backbone, the "P" in N-P-K |
| 16 | Sulfur | Supernova nucleosynthesis | Protein structure (cysteine/methionine); the "S" in N-P-S-K |
| 19 | Potassium | Supernova nucleosynthesis | Ion pumps, starch quality, crop yield — the "K" in N-P-K |

**Trigger:** when `_elementLabel(gotP)` first returns a name for a Z value (i.e., `gotP` just
incremented to that value). Surface a brief, dismissible **cosmic provenance card** — two lines:
`forged in [X]` and `potato role: [Y]`. Non-scoring, never blocks input, fades in ~0.8 s.

**WOW flare verdict — recommend Cosmic Provenance + Potato Role (combined).** The particles scale
uses discovery history ("who found it, when") as its hook. Atoms has an even richer hook:
*everything you're building was forged in a star*. Hydrogen in the Big Bang → heavier elements
in stellar cores → the heaviest in supernova explosions → all of it washed into the soil → potato.
A two-line card ("forged in a red giant · backbone of your starch") closes the loop from the
Nothings "make stars" lore all the way down to a potato on your plate. This is the best WOW
option and should be the build target.

---

## Association verdict

**KEEP — strongest educational tie in the app.** Atom Builder engages 3 of 5 blocks explicitly
(Hydrogen, Nitrogen, Phosphorus) and passes through all 5 by proton count. The WOW flare fills
the Carbon and Oxygen gap. No other scale has a game that encodes real element construction
mechanics (atomic number = proton count, shell capacities, nuclear stability, fertilizer bonding).

---

## Potato angle

This is the scale where the potato tie is richest and most literal:

- **N-P-K-S fertilizer is encoded in the scoring system.** Reaching Z=7, 15, 16, 19 banks the
  four macronutrients a potato actually needs. Players are literally collecting the atoms of
  fertilizer.
- **Carbon** (Z=6) is the backbone of starch — the defining molecule of a potato. Passing through
  it on the way to Neon is a natural moment for the cosmic provenance flare.
- **The forging chain** — H in the Big Bang → C/N/O in stars → P/S/K in supernovae → into soil
  → potato — is this scale's narrative spine. It threads directly from the Nothings "make stars"
  lore (scale 1) through Particles (the bricks) into Atoms (the first named things). The potato
  is the destination the whole chain was building toward.

---

## Decision log

- **Second game slot — DECIDED:** `StarchFactoryGame` is confirmed as game-2 on this scale
  (variety slot). Docs created at `lib/games/atoms/starch_factory/`. Edu tie is ⚠️ (thematic:
  amyloplast / glucose / starch), which is clearly framed in its GAME.md. Registry integration
  is a follow-up (currently delivered via legacy mini_game_page path).
- **WOW flare — BUILT ✅:** `lib/games/atoms/atom_provenance.dart` created (19 elements,
  Z=1–54 coverage of all notable waypoints). Provenance card fires on first proton-count
  crossing for each Z, fades in over 0.25 s, holds, fades out — non-scoring, IgnorePointer.
- **Shell-ring preview — BUILT ✅:** The painter now draws faint (10 % alpha) concentric rings
  for upcoming unfilled shells within the current noble-gas checkpoint, giving players visual
  structure to build toward.
