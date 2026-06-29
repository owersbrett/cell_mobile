# Quantum Foam v2 — AGENT.md

You are the dedicated agent for the **Quantum Foam v2** mini-game
(`lib/games/nothings/quantum_foam_v2/`). You own this game and only this game.

## Mandate
Keep Quantum Foam v2 a complete, polished GAMES-rubric title: a readable
tap-at-peak reflex+timing game that teaches the energy–time uncertainty tradeoff
through its core mechanic — and keeps that tradeoff **legible and decision-
driven**, never degrading back to v1's reflex tapping.

## Hard constraints (do not violate)
- **Self-contained module.** Import ONLY: `package:flutter/*`, `dart:math`,
  `../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`. Never
  import another game or any `mini_games_batch*` file. Inline any helper you need.
- **Host owns the clock/score/results.** Render the play area only (<80s rounds).
  Gate all gameplay on `session.isRunning`; report via `session.addScore` and
  `session.noteStreak`. No internal countdown, no results screen, no navigation.
- **Performance.** One `Ticker` → one `CustomPainter`. Cap particle/pop/pair
  lists. No per-frame `setState` over large widget trees — the painter draws;
  `setState(() {})` only nudges a repaint.
- **Registry/catalog/host edits are NOT yours.** If the `MiniGameSpec` needs to
  change, hand the exact spec to the orchestrator; don't edit shared files.

## The mechanic must stay honest to the physics
- Virtual pairs are created together, separate to an apex, and annihilate at end
  of life. Separation = `maxSep · sin(t·π)`; the live value tracks `sin(t·π)`.
- **Shorter lifetime ⇒ more energy** (inverse). This is the teaching; never
  invert it.
- The value must be **legible before the tap** (the live number + reticle) and
  the **apex must be the optimal tap** (peak harvest). Do not flatten these back
  into "tap anything alive."
- Untouched annihilation is free; only mis-tapping a *stable real* particle
  penalizes. Don't punish missed pairs.

## Tuning levers (playtest, then update GAME.md + report new spec)
- Spawn `interval` / `perSpawn` / lifetime range → ticker accelerate block.
- Energy formula `(26 / lifetime)`, peak band `_kPeakQ`, peak bonus → `_harvest`.
- Climax: `_kSurgeWindow`, `_fireSurge`. Spectacle: `_kBarFull` / `_kMilestone`.
- `humanMax` / `starThresholds` → reported to orchestrator for the spec.

## Definition of done
`flutter analyze lib/games/nothings/quantum_foam_v2/` = 0 issues; the round
auto-starts, the live value/reticle make the apex obvious, peak streaks reward
precision, the surge fires once near the end, and a fresh session re-enters clean.
