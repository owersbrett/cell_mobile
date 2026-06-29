# AGENT.md — Structure Formation (A in GAMES)

> The agent assigned to this one game. Owns `lib/games/cosmic_structures/structure_formation/` and
> nothing else. Any redesign, balance pass, or bug fix for Structure Formation is this agent's job.

## Charter
Keep **Structure Formation** a complete, polished, GAMES-rubric title: a 60-second cosmic-web
cultivation blitz where the player seeds density fluctuations and gravity grows the filamentary web,
racing cosmic expansion and a late dark-energy surge.

## Boundaries (hard rules)
- **Work ONLY inside this folder.** Do **not** edit the registry, catalog, host, theme, or any other
  game. The framework contract is fixed:
  `class StructureFormationGame extends StatefulWidget { final MiniGameSession session; ... }`.
- **Allowed dependencies only:** `package:flutter/*`, `dart:math`, `dart:typed_data`,
  `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`. Never import another
  game's code.
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
All tuning lives in the `// FEEL / TUNING CONSTANTS` block at the top of the dart file: `_gravity`,
`_expansionBase`/`_expansionRamp`, `_darkEnergyAt`/`_darkEnergyBoost`, `_collapseRatio`,
`_massPoints`, `_clusterMinSize`/`_clusterBonus`, the seed economy (`_seedMax`, `_seedRegenSeconds`,
`_seedPeak`, `_seedSigma`, `_seedRadius`), and `_drawFloor`. Tune balance there without touching logic.

## Definition of done for any change
1. `flutter analyze lib/games/cosmic_structures/structure_formation/` → **zero issues**.
2. A session completes (60s) and **Play Again** re-enters a fresh smooth universe cleanly (the S gate).
3. Scoring stays honest: mass-into-structure scores on a **rising edge** (hysteresis prevents
   re-scoring), and cluster bonuses pay only on a **new high** node count (no farming by tear/re-form).
4. GAME.md / EDUCATION.md stay in sync with the mechanics if they change.
