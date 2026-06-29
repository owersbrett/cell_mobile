# GAME.md — Structure Formation (M in GAMES)

> Canonical rules for the cosmic-structures-scale game. The M of GAMES: declares exactly how it is
> played, scored, and won. Self-contained module:
> `lib/games/cosmic_structures/structure_formation/structure_formation_game.dart`
> (`class StructureFormationGame`).

- **Scale (cell):** `BioScale.cosmicStructures`
- **Game id:** `structure_formation`  ·  **Widget:** `StructureFormationGame`
- **Role:** solo score-attack (also drops into party rotation)
- **Duration:** 60 seconds (host-owned clock)
- **Score unit:** mass collapsed into structure

## One-line concept
Start from a nearly-smooth early universe. **Tap to seed tiny density fluctuations**; **gravity**
amplifies them into clusters and weaves the **filamentary cosmic web**. Build the richest web you can
before **expansion** — and a late **dark-energy** surge — pull it apart.

## The board
- A faint **density field** (a 22×38 grid) begins almost uniform: mean density 1.0 with ~±4% random
  ripples, like the cosmic microwave background. Voids are unpainted; only over-dense cells light up.
- Colour ramp: deep blue (faint sheets) → violet (filaments) → orange (collapsing) → white-hot
  (cluster cores). Filaments emerge naturally as ridges of lit cells.

## What you do
- **Tap anywhere** to plant a **density fluctuation** — a small Gaussian over-density at that spot.
- **Seeds are limited.** You start with 7 and regenerate 1 every ~2.2s (cap 7). The HUD dots up top
  show your budget. Tapping with no seeds left does nothing (a brief "NO SEEDS" flash).
- **Gravity does the work.** Each frame, matter flows from lighter cells into denser neighbours
  (mass-conserving accretion). Over-densities grow, neighbouring clumps **merge**, and ridges between
  them become **filaments**.
- **Expansion fights you.** A cosmic-expansion term continuously pulls every cell back toward the mean
  (dilutes contrast). It **ramps up** over the 60s. In the final ~14s **dark energy** surges, actively
  tearing structure apart (a red warning badge appears).

## Scoring
- **Mass into structure:** every cell that newly crosses the **collapse threshold** (density ≥ 2.4×
  mean) scores **+6**. This is the core "mass collapsed into structure" count.
- **Well-formed clusters (web nodes):** a connected blob of ≥5 collapsed cells is a **node**. Each time
  the run reaches a **new high** node count, every new node pays **+40** (and refreshes a cosmic fact).
  Tearing a node apart and re-forming it does **not** re-pay — you must build a genuinely richer web.
- The longest run of node growth is reported as the **streak** (mastery award on the results screen).

## How to win
**Collapse the most mass into a well-formed web before time runs out.** Highest score wins.

## Strategy
- **Spread your seeds.** One fluctuation grows into one clump; gravity already concentrates mass, so
  dumping seeds on the same spot is wasted. Plant across the field to grow **many** nodes and the
  filaments that link them.
- **Don't starve a region** — an unseeded area stays a void and contributes nothing.
- **Seed early.** Gravity needs time to amplify; fluctuations planted late barely collapse before the
  clock — and dark energy — undo them.
- **Beat the expansion.** Build dense enough clumps that they keep collapsing even as expansion ramps.

## Session (S in GAMES)
Host-owned: intro → 3-2-1 countdown → 60s play → results, then **Play Again** re-enters a fresh smooth
universe cleanly. The game gates all simulation on `session.isRunning` and reports via
`session.addScore` / `session.noteStreak`; it owns no clock or results UI of its own.
