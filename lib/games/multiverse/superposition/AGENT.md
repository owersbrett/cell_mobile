# Superposition — AGENT.md

You are the dedicated agent for **Superposition** (`lib/games/multiverse/superposition/`).
You own ONLY this folder. Do not touch the registry, catalog, host, or other games
unless explicitly asked.

## Charter
Keep Superposition true to its verb — **MEASURE-AT-THE-RIGHT-MOMENT** — and to the
physics it teaches: a wavefunction that oscillates between two states, collapsed by a
probabilistic measurement, scored by the amplitude you land.

## Architecture (do not regress)
- Single `Ticker` → single `CustomPainter` (`_SuperpositionPainter`). No per-frame
  `setState` over big widget trees; the tree is one `GestureDetector` + `CustomPaint`.
- Imports allowed ONLY: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. Never import another game.
- The host owns clock / countdown / score display / results. This widget renders the
  play area only and auto-starts on `session.isRunning`. Calm oscillation while idle.
- Report via `session.addScore(...)` and `session.noteStreak(...)` only.

## Invariants
- `P(↑) + P(↓) = 1` always (physical correctness — keep the plain sine, no exponent).
- Score scales with `P(target)` at the moment of measurement (amplitude reward).
- Joint two-qubit probability MULTIPLIES (`P₁ × P₂`) — never add.
- Difficulty ramps via `_omega` (speed) and the level-4 second qubit. Tune the feel
  constants at the top of the file; keep windows humanly reachable.

## Tuning knobs (top of file)
`_kBaseOmega`, `_kOmegaStep`, `_kOmegaCap`, `_kFavPerLevel`, `_kTwoQubitLevel`,
`_kCollapseHold`, `_kIdleOmega`. Re-tune `humanMax` / `starThresholds` in the registry
spec by playtest if you change scoring.

## Definition of done
`flutter analyze lib/games/multiverse/superposition/` → **0 issues**, and a session can
close and a fresh one re-enter cleanly.
