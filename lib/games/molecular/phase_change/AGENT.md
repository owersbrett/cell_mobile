# AGENT — Phase Change

You are the dedicated agent for the **Phase Change** mini-game
(`lib/games/molecular/phase_change/phase_change_game.dart`). You own this game's
design, balance, bugs and polish. Do **not** touch other games, the registry,
the catalog, or the host — coordinate registry/catalog edits through the
orchestrator.

## Charter
A molecular-scale **control-to-target** game: the player drives a substance's
energy with HEAT/COOL to reach and hold SOLID / LIQUID / GAS. The non-negotiable
teaching idea is **latent heat** — the temperature plateaus at the melting and
boiling points. If a change ever removes the plateau, it has broken the game.

## Dependency rule (hard)
Import ONLY: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
`../../fx.dart`, `../../../theme/potatuhs.dart`. Never import another game or any
`mini_games_batch*` file. Keep all private helpers inside this file.

## Architecture
- **One `Ticker` → one `CustomPainter`.** All sim state lives in
  `_PhaseChangeGameState`; the painter is pure render. Never add a second ticker
  or per-frame `setState` over a widget subtree.
- Energy (0..1) is the underlying continuum; **temperature is a piecewise
  function of energy** with two flat plateaus (`_temp` / `_tempFor`). State of
  matter is classified from energy (`_stateOf`), with `-1` = mid-plateau.
- The host owns clock / countdown / score / results. This widget renders ONLY
  the play area, auto-starts on `session.isRunning`, shows a calm ready state,
  and reports via `addScore` / `noteStreak`.

## Tuning knobs (top of file)
`_kHeatRate`, `_kCoolRate`, `_kLossBase/_Step/_Max`, `_kHoldBase/_Min/_Step`,
`_kPointsBase`, `_kPointsPerLevel`, and the `_kSubstances` table (per-material
melt/boil fractions). Playtest before shipping numeric changes.

## Guardrails
- `flutter analyze lib/games/molecular/phase_change/` must report **zero** issues.
- Keep a round under the host clock (~52s) reachable and re-enterable: a session
  must end and a fresh one start cleanly (the S in GAMES).
- Education stays **in the mechanic** — the plateaus and the molecule
  lock/flow/fly-apart are the lesson, not a text overlay.
