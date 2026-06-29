# Pattern Lock — AGENT.md (the A in GAMES)

Owner agent for the `pattern_lock` mini-game. You may change THIS folder only.
Do not touch the registry, catalog, host, or any other game.

## Scope
- `pattern_lock_game.dart` — the playable widget + all its private helpers
  (`_Puzzle`, `_Elem`, family generators, `_BgPainter`).
- `GAME.md`, `EDUCATION.md`, `POTATUHS.md`.

## Dependency rule (EXTRACTION_RECIPE.md)
Import ONLY: `dart:math`, `package:flutter/*`, `../../mini_game.dart`. (May add
`../../fx.dart`, `../../../theme/potatuhs.dart` if needed.) MUST NOT import
another game's code. Keep helpers private and inlined.

## Contract with the host
- `PatternLockGame({required MiniGameSession session})`.
- The host owns the clock/countdown/score/results. Render ONLY the play area.
- Gate all simulation on `session.isRunning`. Never call `session.endEarly`.
- Report points via `session.addScore`; report the running streak via
  `session.noteStreak`.
- Auto-start on `isRunning`; show the calm ready/disclaimer state before play.

## Performance guardrails
- ONE `Ticker` → ONE `CustomPainter` (`_BgPainter`). No second animation loop.
- `setState` once per tick; never rebuild a heavy tree per frame.
- Pattern generation is procedural and allocation-light; no asset loads.

## Design intent
- Theme = "somethings": structure emerging from a simple rule (the first order
  out of the void).
- Education lives IN the mechanic — every answer reveals the rule and a one-line
  teach. Do not bolt on a separate quiz screen.
- Difficulty must ramp with `_level()` (time-based). Keep early puzzles trivial
  and welcoming; push subtlety/length/speed/odd-one-out only later.

## Tuning knobs
- `_kMaxPoints` / `_kFloorPoints` — speed-bonus band.
- `_kStreakStep` — streak multiplier cadence.
- `_decayWindow(lvl)` — how fast you must answer for max points.
- `_allowed(lvl)` — which families appear at each level.
- `humanMax` / `starThresholds` live in the registry spec (out of scope here);
  recommend re-tuning from playtest, not guesswork.

## Do / Don't
- DO keep distractors plausible but unambiguous (one correct continuation).
- DO keep number magnitudes readable (FittedBox guards overflow).
- DON'T introduce two correct answers (e.g. an ambiguous 2-term start).
- DON'T add network, audio, or shared mutable singletons.
