# Twitch — AGENT.md (the **A** in GAMES)

You are the owner-agent for the **Twitch** mini-game (`lib/games/tissue/twitch/`).
You may change anything inside this folder. You may **not** touch other games, the
registry, the catalog, or the host.

## Mandate
Keep Twitch a clean rhythm-timing game where the mechanic *is* the lesson: muscle
contraction driven by timing a nerve signal, the sliding-filament model made visible,
and summation/tetanus emerging from rapid stimuli.

## Architecture (hard constraints)
- **One `Ticker` → one `CustomPainter`.** No second animation controller, no
  per-frame `setState` over a widget tree. All drawing happens in `_TwitchPainter`.
- Imports limited to: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. Do not import another game.
- The host owns the clock/score/results. Read `session.isRunning`; report with
  `session.addScore` / `session.noteStreak`. Never draw your own timer/score.
- Reset gameplay state on the not-running → running edge (`_resetRun`).

## Where to tune
All feel constants are the `_k…` block at the top of `twitch_game.dart`:
cadence (`_kBasePeriod`/`_kMinPeriod`), window (`_kBaseWindow`/`_kMinWindow`),
target phase, summation (`_kTwitchAmount`/`_kRelaxRate`), tetanus
(`_kTetanusThreshold`/`_kTetanusPointsPerSec`), and `_kHitsPerLevel`.

## Definition of done
- `flutter analyze lib/games/tissue/twitch/` → **zero** issues.
- A session completes and a fresh one re-enters cleanly (the **S**).
- Mechanic still teaches: filaments visibly slide, twitches summate into tetanus.

## Status board
Report milestones/blockers to `~/Potatuhs/hpg/_status/cell_mobile.md` per the
BROADCAST PROTOCOL in the repo `CLAUDE.md`.
