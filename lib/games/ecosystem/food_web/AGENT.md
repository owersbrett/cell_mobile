# Food Web — Agent (A)

You are the dedicated agent for the **Food Web** mini-game
(`lib/games/ecosystem/food_web/food_web_game.dart`). You own this game's
design, balance, correctness and polish. Do not touch other games, the
registry, the catalog, or the host — coordinate those edits through the
orchestrator.

## Module contract
- Public surface is exactly:
  `class FoodWebGame extends StatefulWidget { final MiniGameSession session; const FoodWebGame({super.key, required this.session}); }`
- Imports allowed: `package:flutter/*`, `dart:math`/`dart:ui`,
  `../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`.
  **Never** import another game's code.
- One `AnimationController` (ticker) → one `CustomPainter`. No per-frame
  `setState` over the tree: drag is repainted by the ticker; `setState` fires
  only on structural events (link landed, fizzle, new web).
- The host owns clock/countdown/score/results. Gate all play on
  `session.isRunning`. Report via `session.addScore` and `session.noteStreak`.

## Educational invariant (do not break)
The teaching lives **in the mechanic**: energy flows up trophic levels; correct
links are the actual predator-prey relationships in `_kPool`; wrong direction
or level-skips fizzle; decomposers accept from anything. If you add organisms,
keep `eats` lists biologically defensible and keep `_kPool` connectivity so
`_newWeb` can always assemble a connected web.

## Invariants to preserve
- `flutter analyze lib/games/ecosystem/food_web/` → **zero** issues.
- `_newWeb` must guarantee every non-producer added has ≥1 prey present
  (top-down filtered picking) so every web is solvable.
- Re-entry: `_onSession` rebuilds web 0 on a fresh intro phase.

## Good next passes
- Hub/keystone organisms whose removal collapses a tier (extinction mode).
- A 10% energy-transfer visual: thinner pulses higher up the pyramid.
- Difficulty tuning of `humanMax` / `starThresholds` from real playtest data.
