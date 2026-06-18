# AGENT.md — Meiosis

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> **STATUS: This game is UNBUILT. No `.dart` file exists. This document is the implementation brief.**

---

## Scope (hard boundary)

- **Work only within:**
  - Game code (to be created): `lib/games/cell/meiosis/meiosis_game.dart` → `MeiosisGame`
  - Game docs: `lib/games/cell/meiosis/` (GAME.md, MANUAL.md, AGENT.md)
  - Scale education: `lib/games/cell/EDUCATION.md`
- **Read-only reference:** `lib/views/screens/mini_game_page/games/mitosis_rush_game.dart` —
  read for the phase scaffold, painter helpers, and data class patterns. **Do NOT modify it.**
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_registry.dart` — read as needed, **no edits without explicit escalation**.
- **Do not touch** other games, other scales, the host/router, or `mini_game_page.dart`.

---

## Scene / exit contract

- `MeiosisGame` should follow the same contract as `MitosisRushGame`:
  self-contained (`const MeiosisGame()`), no `MiniGameSession` args, owns its own timer,
  results screen, and restart.
- This is consistent with Mitosis Rush as a sibling game on the same scale.
- The game must never trap the player. If wrapped in a host later, the internal results/restart
  must be delegated to the host (same migration path as Mitosis Rush — see that game's AGENT.md).

---

## Files

| Role | Path |
|---|---|
| Game widget (to be created) | `lib/games/cell/meiosis/meiosis_game.dart` → `MeiosisGame` |
| Canonical spec | `lib/games/cell/meiosis/GAME.md` (rules live here — implement to this spec) |
| Manual entry | `lib/games/cell/meiosis/MANUAL.md` |
| Scale education | `lib/games/cell/EDUCATION.md` |
| Phase scaffold reference | `lib/views/screens/mini_game_page/games/mitosis_rush_game.dart` (read-only) |
| Registry | Not yet registered (add to `mini_game_registry.dart` on `BioScale.cell` after build) |

---

## Reuse from Mitosis Rush (copy these patterns directly)

The Mitosis Rush phase scaffold is the correct starting point. Copy-adapt, do not invent from
scratch.

| Component | Source (read-only) | Notes |
|---|---|---|
| Phase loop | `_MitosisRushGameState._onTick` | `_phaseTimer`, `_bannerAge`, `_phaseDone`, `_phaseDoneAge` — identical contract |
| Phase scoring | `_scorePhase(double timeRemaining)` | Same formula: base 50 + speed bonus |
| Phase advance | `_advancePhase()` | Extend for 8 phases across two divisions |
| Particle effects | `_FloatParticle`, `_FloatLabel`, `_spawnBurst`, `_spawnDirectedBurst` | Copy as-is |
| Drawing helpers | `_drawCellOutline`, `_drawGlowCircle`, `_drawProgressMeter`, `_drawHUD`, `_drawBanner`, `_drawDashedCircle` | Copy as-is into the new painter |
| Chromosome rendering | `_drawMetaphase` (oval X pairs + centromere) | Adapt for bivalents and single-chromatid variants |
| Anaphase swipe | `_onPanStart` / `_onPanUpdate` anaphase branch | Copy directly; same vertical gesture |
| Telophase tap | `_handleTelophase` | Copy; reduce `_kTapsPerNucleus` from 5 to 3 per spec |
| Cytokinesis drag | `_onPanUpdate` cytokinesis branch | Copy directly |

---

## New elements (not in Mitosis Rush)

### 1. Crossing-over drag (Prophase I) — the primary new mechanic
- Display 4 homologous pairs as side-by-side chromosome ovals. Each chromosome has 3 colored
  band segments at fixed vertical positions.
- Gesture: tap a band to select it (highlight), then drag it to the matching position on the
  homologue. Release to drop.
- Valid drop condition: same vertical position on the homologue. Color category is decorative
  (shows genetic content) but is not a drop constraint.
- On success: +30, spark burst at the crossover point, draw a small X (chiasmata mark) at
  the crossing position.
- On invalid drop: silently return the band to its source. No penalty.
- Data class needed: `_GeneSegment { int chromosomeId; int position; Color color; bool crossed; }`.

### 2. Bivalent rendering (Metaphase I, Anaphase I)
- A bivalent is two chromosomes (maternal + paternal) joined at a chiasmata.
- Draw as two parallel X-oval pairs connected by a small X mark between them.
- After a crossing-over, the X mark appears at the crossed position.

### 3. Single-chromatid visual (Anaphase II)
- In Division II, the chromosomes being separated are single chromatids — draw them as thinner,
  shorter ovals (half the height of the Division I chromosome shapes).
- The visual difference is the educational signal: "you're in Division II, separating sisters,
  not homologues."

### 4. Side-by-side dual-cell layout (Division II phases)
- After Cytokinesis I, the canvas is conceptually split into left and right halves.
- Each half hosts one daughter cell with its own chromosome set.
- Hit zones must account for the smaller canvas area per cell. Use 60% of normal chromosome
  sizes in Division II.
- Metaphase II: 2 drag targets per cell, 4 total.
- Anaphase II: 2 swipe targets per cell, 4 total.
- Telophase II: 4 nucleus seals total.

### 5. Ploidy labels
- Starting cell: "2n" label near the cell outline.
- After Cytokinesis I: "n" on both daughter cells.
- Final 4 gametes: "n" on each, plus a unique color pattern per cell showing the genetic
  content inherited (3-band color set matching the crossing-over outcome).

### 6. "NO DNA REPLICATION" interstitial
- Between Division I and Division II: a 2.5 s banner reads:
  "NO DNA REPLICATION — Division II begins immediately."
- This is the most important fact of meiosis that is not taught in Mitosis Rush.

### 7. 4-gamete finale
- After the final cytokinesis, 4 small cells fan outward from the center.
- Each has a distinct band-color pattern reflecting the crossing-over outcome from Phase 1.
- Banner: "4 UNIQUE GAMETES — meiosis complete."
- Results screen follows (same layout as Mitosis Rush, adapted for 8 phases).

---

## Tunable constants (recommended starting values)

| Constant | Suggested value | Notes |
|---|---|---|
| `_kCrossoverPairs` | 4 | Chromosome pairs needing crossover in Prophase I |
| `_kBandsPerChromosome` | 3 | Gene segments per chromosome (top/middle/bottom) |
| `_kCrossoverBonus` | 30 | Points per successful crossing-over swap |
| `_kProphaseITime` | 15.0 s | Longest phase; crossing over needs extra time |
| `_kMetaphaseITime` | 10.0 s | |
| `_kAnaPhaseITime` | 12.0 s | |
| `_kTeloICytoITime` | 8.0 s | Combined phase |
| `_kMetaphaseIITime` | 8.0 s | Shorter — same mechanic, less chromosome count |
| `_kAnaPhaseIITime` | 12.0 s | |
| `_kTeloIICytoIITime` | 8.0 s | Combined phase |
| `_kTapsPerNucleus` | 3 | Reduced from Mitosis Rush's 5 (8 nuclei total across the run) |
| `_kFurrowTarget` | 0.80 | Same as Mitosis Rush |
| `_kPhaseBaseScore` | 50 | Same as Mitosis Rush |
| `_kPerfectBonus` | 100 | Same as Mitosis Rush |

---

## Known TODOs (before first build)

1. **[HIGH] Decide division structure in code.** Two options:
   - Single `_Phase` enum with 8 entries + a `_division` int (1 or 2) for layout switching.
   - Two separate enums (`_DivisionIPhase`, `_DivisionIIPhase`) with a wrapper state.
   The single enum is simpler and closer to the Mitosis Rush pattern. Recommended unless the
   dual-cell layout becomes complex enough to warrant its own state class.

2. **[HIGH] Crossing-over gesture implementation.** The drag-to-swap is new. Prototype this
   first and confirm it's readable before building the rest. If tap-select-then-drag proves
   confusing in playtesting, fallback: a simple "tap to toggle cross" on the paired band —
   tapping a band swaps it with the matching position on the homologue automatically.

3. **[MEDIUM] Division II canvas layout.** The side-by-side layout needs the cell size to shrink
   to fit both in the canvas. Use `cellRadius * 0.55` for each Division II cell. Test on smallest
   supported screen (iPhone SE, ~375 × 667 pt).

4. **[MEDIUM] Registration.** After the game is built and passes play-testing, register it in
   `lib/games/mini_game_registry.dart` on `BioScale.cell`. A per-scale game picker (NORTH_STAR §8)
   is needed before both Mitosis Rush and Meiosis are accessible from Explore.

5. **[LOW] Interstitial banner timing.** The "NO DNA REPLICATION" banner between divisions is
   purely informational (no interaction). 2.5 s hold time. If it feels disruptive, shorten to
   1.8 s. Do not make it skippable — the message is educationally important.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG, JPEG, or raster assets.** Everything drawn
procedurally: chromosomes as oval paths, bands as colored rect segments, chiasmata as X-path
marks, cells as sine-deformed circles, HUD via `TextPainter` and `RRect`.
