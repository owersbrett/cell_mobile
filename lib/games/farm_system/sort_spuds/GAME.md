# GAME.md — Sort the Spuds

> Canonical rules for the farm-system grading game. The manual (M in GAMES). Update this first, then
> the code.

- **Scale (cell):** `BioScale.farmSystem`
- **Game id:** `sort_spuds`
- **Widget:** `SortSpudsGame` (`lib/games/farm_system/sort_spuds/sort_spuds_game.dart`)
- **One-line concept:** Potatoes ride a conveyor; grade each one into the right bin by size and
  **cull the defects** before they fall off the end.
- **Role:** solo score-attack, 60 s, host-owned clock.

## The line
A conveyor belt carries potatoes left → right. Below it sit four bins:

`SMALL` · `MEDIUM` · `LARGE` · `REJECT`

The **leading** spud (the one nearest the end of the belt, ringed in gold) is the one you're grading.
Tap a bin to send it there. Sort fast — if a spud reaches the end of the belt unsorted it falls off
the line (a miss).

## Grading rules
- A **clean** potato belongs in the bin matching its **size**: SMALL / MEDIUM / LARGE.
- A **defective** potato — **rotten** (dark mushy patches), **green** (greened skin / solanine), or
  **blemished** (scab spots) — must be **culled** into REJECT, whatever its size.

## Scoring
| Action | Points |
|---|---|
| Correct size grade | **+10** (+streak bonus) |
| Correct cull (defect → REJECT) | **+14** (+streak bonus) — QC is the payoff |
| Wrong size bin (e.g. MEDIUM → SMALL) | **−6** |
| Good potato thrown to REJECT (waste) | **−12** |
| **Rotten potato sent to a SALE bin** (contaminates the crate) | **−30** |
| Spud falls off the belt unsorted (miss) | **−5** |

A **streak** counts consecutive correct sorts; from 3+ it adds `(streak − 2) × 2` bonus points to
each correct sort. Any wrong sort or miss resets it. The session reports the streak to the host for
the results-screen mastery award.

## How to win
Highest score when the 60-second timer runs out. Score never drops below zero.

## The accelerate
As the round wears on (ramp ≈ 45 s, then plateau):
- the **belt speeds up** (≈ 0.115 → 0.290 belt-lengths/sec),
- the belt gets **more crowded** (spawn gap tightens),
- **size grades get subtler** — sizes drift toward the SMALL/MEDIUM/LARGE boundaries (but never cross,
  so the labelled grade is always honestly correct),
- **defects get sneakier** — the rot/green/scab tells fade in contrast.

## Education (E)
Grading & quality control: why produce is sorted by size for uniform packs, why defects are culled
(one rotten spud spoils the crate), greening/solanine, and grade standards through the supply chain.
A rotating grading fact surfaces on each clean cull. Full write-up in `EDUCATION.md`.

## Rendering / performance
Procedural canvas only — no raster assets. One `AnimationController` ticker drives one
`CustomPainter`; belt, potatoes, bins, particles, score pops and flashes are mutated in the tick
without `setState` and the canvas repaints off the ticker. See the performance note at the top of
the source.
