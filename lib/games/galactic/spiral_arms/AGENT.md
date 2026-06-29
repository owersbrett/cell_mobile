# AGENT.md — Spiral Arms

> The dedicated agent profile for this game (the **A** in GAMES). One agent owns this module and only this
> module. It may read framework pieces but must not touch other games, the registry, the catalog, or the
> host.

## Mandate
Own `lib/games/galactic/spiral_arms/` end to end: the `SpiralArmsGame` widget, its painter, and the four
docs (GAME / AGENT / EDUCATION / POTATUHS). Keep the module self-contained and `flutter analyze`-clean.

## Boundaries (hard)
- **Edit ONLY** files under `lib/games/galactic/spiral_arms/`.
- **MUST NOT** edit `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`, `mini_game.dart`,
  or any other game's folder. If the spec needs to change, hand the exact `MiniGameSpec` diff up to the
  orchestrator — do not edit the registry yourself.
- Allowed dependencies: `package:flutter/*`, `dart:math`, `../../mini_game.dart`, and stable shared utils
  (`lib/theme/potatuhs.dart`, `lib/games/fx.dart`). No imports of another game's code.

## Contract with the host
- Take a `MiniGameSession session`. The host owns clock, countdown, score total and results.
- Render ONLY the play area. Auto-start on `session.isRunning`; show a calm, legible ready state otherwise.
- Report via `session.addScore(delta)` and `session.noteStreak(currentStreak)`. Do not call `endEarly`
  (there is no fail state — the round is purely time-boxed).

## Design invariants (do not regress)
- The **lerp(orbital, crisp, coherence)** rendering is the soul of the game — it makes the winding problem
  and the density-wave resolution *visible*. Keep it.
- Differential rotation must stay visibly faster at the core than the rim, or the lesson collapses.
- The density wave (pattern phase) must rotate **much slower** than the stars. That contrast is the point.
- Performance: ONE Ticker, ONE CustomPainter, `setState(() {})` once per tick. ~170 stars is the budget;
  if you raise it, re-check frame cost on web (the black-screen failure mode is render-cost overload).

## Good change requests
- Tune `humanMax` / `starThresholds` from real playtests.
- Add a faint gravitational-lensing or compression shimmer at the wave crest (without breaking the budget).
- Improve the smear: when coherence is near zero, the disk should read as genuinely featureless.

## Verify before handing back
- `flutter analyze lib/games/galactic/spiral_arms/` → **zero** issues.
- Manually: arms are crisp at full coherence, smear as it drops, on-beat pulses restore them, streak
  multiplier climbs, and a fresh session re-enters cleanly (the **S** in GAMES).
