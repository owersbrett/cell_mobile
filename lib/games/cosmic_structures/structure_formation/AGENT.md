# AGENT.md — Structure Formation (A in GAMES)

> The agent assigned to this one game. Owns `lib/games/cosmic_structures/structure_formation/` and
> nothing else. Any redesign, balance pass, or bug fix for Structure Formation is this agent's job.

## Charter
Keep **Structure Formation** a complete, polished, GAMES-rubric title: a 45-second **claim-the-web
contest**. You and rival civilizations plant OWNED, colored seeds into one shared young universe;
every seed is a bright node NOW that pulls filaments and grows a territory; you score the share of
the cosmic web that collapses around YOUR seeds. Solo = AI rivals; online = real players streaming
their seeds into the same universe (round-robin). Both run identical game code behind one seam.

> History: this game was rank **F** (an illegible density sim). Rebuilt 2026-07-07 from GAME.md.
> The re-implementation is the deliverable, not the old physics — see GAME.md "Why this fixes the F".

## Boundaries (hard rules)
- **Work ONLY inside this folder.** Do **not** edit the registry, catalog, host, theme, or any other
  game. The framework contract is fixed:
  `class StructureFormationGame extends StatefulWidget { final MiniGameSession session; final StructureSeedSource? source; ... }`.
- **Allowed dependencies only:** `package:flutter/*`, `dart:math`, `dart:typed_data`,
  `package:firebase_database` (online layer only), `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart`, and this folder's own `structure_seed_source.dart` / `structure_net.dart`.
  Never import another game's code.
- **The rival seam is the law:** the game only ever READS rival seeds from `StructureSeedSource`
  (`structure_seed_source.dart`). Solo injects `AiSeedSource`; online injects `NetSeedSource`
  (`structure_net.dart`). Never make the game itself network-aware beyond accepting a source.
- **The host owns the clock, countdown, score HUD, and results.** This widget renders ONLY the play
  area, auto-starts on `session.isRunning`, shows a calm ready state otherwise, and reports through
  `session.addScore` / `session.noteStreak`. Never draw a timer/score/results screen here.

## Performance contract (non-negotiable)
- The density field + particles render on **ONE `AnimationController` ticker → ONE `CustomPainter`**.
- Simulation mutates flat **typed arrays** (`Float32List` / `Uint8List`) every frame **without
  setState**; the canvas repaints via `repaint: _ticker`. Only a **throttled ~15fps** `setState`
  refreshes HUD text (seed dots, fact banner, badges).
- No `MaskFilter.blur` per cell (per-frame web-rasterizer stall). Guard every painter against
  non-finite metrics — a single NaN can black the frame.
- Keep the grid (`_cols × _rows`) and particle caps modest; the field is ~836 cells and only over-dense
  cells are drawn.

## Where the knobs are
All tuning lives in the `// FEEL / TUNING` block at the top of the dart file: `_gravity`,
`_expansionBase`/`_expansionRamp`, `_darkEnergyAt`/`_darkEnergyBoost`, `_collapseRatio`/
`_uncollapseRatio`, `_massPerCell`, `_clusterMinSize`/`_clusterBonus`, the seed economy (`_seedMax`,
`_seedRegenSeconds`, `_seedPeak`, `_seedSigma`, `_seedRadius`), `_drawFloor`, and `kClaimantColors`.
Rival behavior tunes in `structure_seed_source.dart` (`AiSeedSource`). Tune without touching logic.

## Legibility contract (the F was an illegibility failure — protect this)
- **A tap is a bright OWNED node instantly** (the seed centre collapses on placement). Never regress
  to "wait and see if something forms".
- **The board is a map:** claimed cells are drawn in their **owner's color**; the live top **share
  bar** always answers "am I winning?". Don't remove either.

## Definition of done for any change
1. `flutter analyze lib/games/cosmic_structures/structure_formation/` → **zero issues**.
2. A session completes (45s) and **Play Again** re-enters a fresh smooth universe cleanly (the S gate).
3. Scoring stays honest: local owned-mass scores on **growth only** (monotonic — a rival stealing a
   border never claws back banked score); node bonus pays on a **new high** local node count.
4. Solo runs with AI rivals; the online path (`NetSeedSource`) still maps slots→claimants correctly
   (`test/games/structure_formation_test.dart`).
5. GAME.md / EDUCATION.md stay in sync with the mechanics if they change.
