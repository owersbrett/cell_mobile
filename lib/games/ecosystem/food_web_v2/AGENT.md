# Food Web v2 — Agent (A)

You are the dedicated agent for the **Food Web v2** mini-game
(`lib/games/ecosystem/food_web_v2/food_web_v2_game.dart`). You own this game's
design, balance, correctness and polish. Do not touch other games, the
registry, the catalog, or the host — coordinate those edits through the
orchestrator.

## Module contract
- Public surface is exactly:
  `class FoodWebV2Game extends StatefulWidget { final MiniGameSession session; const FoodWebV2Game({super.key, required this.session}); }`
- Imports allowed: `package:flutter/*`, `dart:math`/`dart:ui`,
  `../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`.
  **Never** import another game's code.
- One `AnimationController` (ticker) → one `CustomPainter`. The sim drains and
  the drag rubber-bands by mutating fields the painter reads each frame — no
  per-frame `setState` over the tree.
- The host owns clock/countdown/score/results. Gate all play on
  `session.isRunning`. Report via `session.addScore` and `session.noteStreak`.

## Educational invariant (do not break)
The teaching lives **in the mechanic**: energy flows up trophic levels one rung
at a time; valid feeds are the real predator-prey links in `_kRoster`; feeding
up costs the source more than it delivers (the 10% rule); decomposers accept
from anything. If you add organisms, keep `eats` lists one level below and
biologically defensible, and keep the roster connected (every predator's prey
revealed before/with it) so the pyramid is always feedable.

## Invariants to preserve
- `flutter analyze lib/games/ecosystem/food_web_v2/` → **zero** issues.
- The board is **deterministic** (fixed roster + fixed reveal schedule) — this
  is what makes the contest fair. Do not reintroduce randomised webs.
- Release **snaps** to nearest and **always** gives feedback (never silent).
- Re-entry: `_resetRun` rebuilds the starting pyramid on the running edge.

## Good next passes
- Thinner energy packets / faster drain higher up the pyramid to dramatise the
  10% rule visually.
- A keystone-species mode: starve a mid predator and watch a tier collapse.
- Difficulty tuning of `humanMax` / `starThresholds` from real playtest data.
