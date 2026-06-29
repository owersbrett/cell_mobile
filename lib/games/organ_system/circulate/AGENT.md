# Circulate — AGENT.md

Owner agent for the `circulate` mini-game. One game, one folder, one agent.

## Scope (what you may touch)
- `lib/games/organ_system/circulate/` ONLY: `circulate_game.dart` and the
  `.md` docs in this folder.
- You MUST NOT edit the registry, catalog, host, theme, fx, or any other game.
  If the `MiniGameSpec` needs to change, hand the exact spec back to the
  orchestrator — do not edit `mini_game_registry.dart` yourself.

## Contract
- Public surface is exactly:
  `class CirculateGame extends StatefulWidget { final MiniGameSession session;
  const CirculateGame({super.key, required this.session}); }`
- Imports limited to: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. No other-game imports.
- The host owns clock / countdown / score HUD / results. This widget renders
  ONLY the play area and reports via `session.addScore` / `session.noteStreak`.
- ONE `AnimationController` (days:1) → ONE `CustomPainter`. No per-frame
  setState over a large tree. FX animate even in the calm ready state.
- Auto-start on `session.isRunning`; rising-edge reset so a fresh session
  replays clean (the S in GAMES). Calm, readable ready state.

## Design intent (don't regress)
- Education lives IN the mechanic: red = oxygenated arterial delivery; blue =
  deoxygenated venous return; the recharge step IS pulmonary circulation; the
  reserve gate teaches "no return to lungs → no O₂ to deliver".
- Distinct from "Heartbeat" (single-beat chamber game). This is body-wide
  DELIVERY across the systemic + pulmonary loops.

## Tuning knobs (playtest these)
`_deliverAmt`, `_deliverCost`, `_rechargeAdd`, `_pulseSpeed`, `_lowO2`,
organ `drain` values, `_nextOrgan` cadence, demand ramp in `_simulate`.
Keep a round reachable but tense; recalibrate `humanMax` / `starThresholds`
in the spec after retuning.

## QA
`flutter analyze lib/games/organ_system/circulate/` → ZERO issues.
Session re-entry: finish a round, start a fresh one — must replay clean.
