# GAME.md — Nephron

> Canonical spec for the organ-scale game **Nephron** — run the kidney's filter. Where most cell games
> live inside one cell, this one zooms out to a whole organ's working unit: the nephron, the kidney's
> million-fold-repeated filtration tubule.

- **Scale (cell):** organ (`BioScale.organ`)
- **Game id:** `nephron` (widget `NephronGame`, self-contained module)
- **One-line concept:** Blood streams down the nephron's tubule; the player SORTS each molecule —
  reabsorb the good stuff back into the blood, let the waste leave in the urine.
- **Role:** solo high-score / party round (60 s)

## The science (this IS the mechanic)
A nephron does its job in two steps. (1) **Filtration**: at the glomerulus, blood pressure pushes water
and small molecules — good *and* bad, indiscriminately — out of the blood and into the tubule. Almost
everything small gets dumped in. (2) **Selective reabsorption**: as that filtrate flows down the tubule,
the body actively pulls back the things it needs — glucose, most of the water, amino acids, and the right
amount of key ions — and returns them to the surrounding blood vessels. Whatever is *not* reabsorbed
keeps flowing and exits as urine: urea, toxins, drug metabolites, and surplus salt.

The game makes this asymmetry the core rule: **the tubule's default is "everything leaves in the urine."**
Reabsorption is the *active, selective step* the player performs. Doing nothing sends a molecule to urine —
which is correct for waste and wrong for a nutrient.

## Core loop
- Molecules fall down the central tubule (one Ticker drives them all).
- **Flick LEFT** (tap on a molecule's left side) → reabsorb it into the **BLOOD** (left gutter, red).
- **Flick RIGHT** (tap on its right side) → send it to the **URINE** (right gutter, amber).
- Let a molecule fall out the bottom → it passively exits in urine (the tubule default).
- **Blood purity** (a 0–1 bar) is the health stat: bad calls drain it, good calls slowly restore it.
  Drain it to zero and the filter fails — the round ends early.

## Correct vs. wrong (the calls)
| Molecule | Right move | Wrong move |
|---|---|---|
| Good (glucose, water, amino acid, needed Na⁺/K⁺/HCO₃⁻) | Reabsorb → BLOOD | To urine = nutrient lost (−pts, −purity) |
| Waste (urea, creatinine, toxin, uric acid, ammonia, drug, **excess** Na⁺) | To URINE (or let it fall) | Keep in BLOOD = waste in blood (−pts, −−purity) |

## Escalation (accelerate)
Level climbs with elapsed time (LV1→LV5): **faster flow**, **more molecule types**, and **subtler calls** —
at LV3 *needed* sodium and *excess* sodium look identical (same symbol, same colour); only the label
(`Sodium` vs `Sodium · EXCESS`) tells them apart, exactly as the kidney discriminates the amount the body
needs from the surplus.

## Scoring
- **Correct call** = base 10 × streak multiplier (up to ×3 at a 20-streak).
- **Streak** climbs on consecutive correct calls; any wrong call resets it.
- Waste that passively exits the bottom pays a small +2 (the default doing its job).
- `scoreUnit`: "molecules".

## How to win
Highest score when the 60 s run ends — keep blood purity up by reabsorbing every nutrient and routing
every toxin out.

## Spec (registered in `mini_game_registry.dart` — DO NOT edit from this module)
- `humanMax: 1400`, `starThresholds: [400, 850, 1400]` (seed values; tune by playtest).
- `durationSeconds: 60`, `accent: Color(0xFFC65A6E)`, `icon: Icons.filter_alt`.

## Implementation notes
- ONE `Ticker` advances every molecule, particle and pop; ONE `CustomPainter` (`_NephronPainter`) draws the
  tubule, gutters, glomerulus, molecules, FX and HUD. The painter repaints off a `Listenable` — no
  per-frame `setState` over a widget tree (reference: `arcade/hungry_cell.dart`).
- Imports limited to `../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`, flutter.
- Calm ready state: when `!session.isRunning`, a few molecules drift slowly and an overlay explains the
  controls; the run resets the instant `isRunning` flips true (host owns clock/countdown/score/results).
- Health depletion is the only `endEarly` path (a genuine fail state — the filter clogged).
