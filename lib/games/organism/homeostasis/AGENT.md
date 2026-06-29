# Homeostasis — Agent (A)

Owner agent for the Homeostasis mini-game. One self-contained module:
`lib/games/organism/homeostasis/homeostasis_game.dart`.

## Charter
Keep Homeostasis fun, fair, and faithful to **negative feedback**. The teaching
must live *in the mechanic* (counteract the deviation), never in a popup.

## Boundaries (do not cross)
- Edit ONLY this folder. Never touch the registry, catalog, host, or another
  game. New spec wiring is the orchestrator's job.
- Imports allowed: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. Nothing else.
- The host owns the clock/countdown/score/results. Render the play area only.
  Gate all drift + scoring on `session.isRunning`; auto-start, calm ready state.

## Performance contract
- One `Ticker` → one `setState` per frame → one `CustomPainter`. No widget tree
  per gauge, no per-frame allocation storms. `shouldRepaint` may return true.
- Keep frame work flat: a handful of `TextPainter`s and rects per frame.

## Invariants to preserve when tweaking
- Corrective directions stay physiologically correct (see GAME.md table).
- A fresh session re-initialises cleanly (`_beginRun` on `isRunning` rising;
  `_started` cleared in the intro phase) — the **S** in GAMES.
- Difficulty ramps with `_playElapsed / durationSeconds`; O₂ wakes at
  `_kO2WakeFrac`.

## Good first tasks
- Playtest-tune `humanMax` / `starThresholds` in the spec.
- Balance shock cadence/magnitude so 4-gauge juggling is tense but possible.
- Add a 5th system (e.g. pH/CO₂) behind the same dormant-then-wake pattern.
