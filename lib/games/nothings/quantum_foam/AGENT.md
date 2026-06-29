# Quantum Foam — AGENT.md

You are the dedicated agent for the **Quantum Foam** mini-game
(`lib/games/nothings/quantum_foam/`). You own this game and only this game.

## Mandate
Keep Quantum Foam a complete, polished GAMES-rubric title: a fast, readable
tap-the-pairs reflex game that teaches the uncertainty / energy–time tradeoff
through its core mechanic.

## Hard constraints (do not violate)
- **Self-contained module.** Import ONLY: `package:flutter/*`, `dart:math`,
  `../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`. Never
  import another game or any `mini_games_batch*` file. Inline any helper you need.
- **Host owns the clock/score/results.** Render the play area only (<80s rounds).
  Gate all gameplay on `session.isRunning`; report via `session.addScore` and
  `session.noteStreak`. No internal countdown, no results screen, no navigation.
- **Performance.** One `Ticker` → one `CustomPainter`. Cap particle/pop/pair
  lists. No per-frame `setState` over large widget trees — the painter does the
  drawing; `setState(() {})` only nudges a repaint.
- **Registry/catalog/host edits are NOT yours.** If the `MiniGameSpec` needs to
  change, hand the exact spec to the orchestrator; don't edit shared files.

## The mechanic must stay honest to the physics
- Virtual pairs are created together, separate, and annihilate at end of life.
- **Shorter lifetime ⇒ more energy** (inverse). This is the teaching; never
  invert it.
- Untouched annihilation is free; only mis-tapping a *stable real* particle
  penalizes. Don't punish missed pairs.

## Tuning levers (playtest, then update GAME.md + report new spec)
- Spawn interval, pairs-per-spawn, lifetime range, real-particle cap → in the
  ticker's accelerate block.
- Energy formula `(36 / lifetime)` and streak bonus → `_harvest`.
- `humanMax` / `starThresholds` → reported to orchestrator for the spec.

## Definition of done
`flutter analyze lib/games/nothings/quantum_foam/` = 0 issues; the round
auto-starts, accelerates, and a fresh session re-enters clean.
