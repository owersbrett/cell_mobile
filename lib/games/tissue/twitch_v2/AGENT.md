# Twitch v2 — AGENT.md (the **A** in GAMES)

You are the owner-agent for the **Twitch v2** mini-game
(`lib/games/tissue/twitch_v2/`). You may change anything inside this folder. You
may **not** touch other games, the registry, the catalog, or the host.

## Mandate
Keep Twitch v2 a clean rhythm-timing game where the mechanic *is* the lesson:
muscle contraction driven by timing a nerve signal, the sliding-filament model
made visible, summation/tetanus emerging from firing rate, and **fatigue**
making sustained tetanus self-limiting. The fatigue mechanic is the load-bearing
fix for v1's runaway-leader tetanus drip — do not regress it into an
unbounded bonus.

## Architecture (hard constraints)
- **One `Ticker` → one `CustomPainter`.** No second animation controller, no
  per-frame `setState` over a widget tree. All drawing happens in
  `_TwitchV2Painter`.
- Imports limited to: `dart:math`, `package:flutter/*` (incl. `services` for
  `HapticFeedback`), `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`. Do not import another game.
- The host owns the clock/score/results and AI opponents. Read
  `session.isRunning` / `session.remaining` / `session.spec.durationSeconds`;
  report with `session.addScore` / `session.noteStreak`. Never draw your own
  timer/score HUD.
- Reset gameplay state on the not-running → running edge (`_resetRun`).

## Where to tune
The `_k…` constant block at the top of `twitch_v2_game.dart`: cadence
(`_kBasePeriod`/`_kMinPeriod`), window (`_kBaseWindow`/`_kMinWindow`), summation
(`_kTwitchAmount`/`_kRelaxRate`), tetanus (`_kTetanusThreshold`/`_kMaxDrip`),
fatigue (`_kFatigueRate`/`_kRecoverRate`/`_kRestLevel`), and `_kFinalBurstSecs`.

## Definition of done
- `flutter analyze lib/games/tissue/twitch_v2/` → **zero** issues.
- A session completes and a fresh one re-enters cleanly (the **S**).
- Mechanic still teaches: filaments slide, twitches summate into tetanus,
  tetanus fatigues. No runaway-leader compounding.

## Status board
Report milestones/blockers to `~/Potatuhs/hpg/_status/cell_mobile.md` per the
BROADCAST PROTOCOL in the repo `CLAUDE.md`.
