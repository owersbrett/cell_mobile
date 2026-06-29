# AGENT.md — Reflex

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)
- **Work only within:** `lib/games/organ_system/reflex/` — `reflex_game.dart` and the four docs
  (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`.
  Read as needed; **no edits**.
- **Do not touch** the registry, catalog, host, `mini_game_page.dart`, or any other game. Wiring this
  game into the registry/catalog is a lead task, not an in-game task.

## Dependency rule (EXTRACTION_RECIPE)
Imports are limited to: `dart:math`, `package:flutter/*`, `../../mini_game.dart`, `../../fx.dart`,
`../../../theme/potatuhs.dart`. Self-contained — no import of another game's code. Keep it that way.

## Scene / exit contract
- `ReflexGame` mounts inside an isolated scene managed by `MiniGameHost`. The host owns the timer,
  countdown overlay, results screen, and exit affordance — the game never reimplements these.
- `widget.session.isRunning` gates gameplay. The trial state machine only advances when running; the
  run (re)starts on the rising edge of `isRunning` (`_startRun`). Do not advance state when paused.
- Let exceptions surface to the host's error boundary; never swallow them.

## Architecture (one ticker → one painter)
- Single `Ticker` (`_onTick`) computes `dt`, advances the trial machine, decays juice, then one
  `setState`. One `_ReflexPainter` (RepaintBoundary-wrapped). No per-frame setState over a big tree,
  no second animation source. Keep this shape for performance (web target, < 80s rounds).

## State machine (`_Phase`)
`idle → ready → fired → reacted → ready …`, with `ready → ready` on false start and
`fired → damaged → ready` on timeout. Key fields: `_waitRemaining`, `_sinceStimulus` (= reaction
time), `_damageLimit`, `_signalProgress` (impulse travel), `_decoyFireAt/_decoyVisible`.

## Tunable constants (top of `reflex_game.dart`)
| Constant | Value | Tune for |
|---|---|---|
| `_kDifficultyTrials` | 12 | How fast difficulty ramps (lower = steeper). |
| `_kWaitMin/MaxEasy/Hard` | 1.3/2.8 → 0.6/1.4 | Pre-stimulus delay window across the ramp. |
| `_kDamageLimitEasy/Hard` | 1.15 → 0.72 | Reaction window before a trial fails. |
| `_kDecoyChanceMax` | 0.55 | Peak decoy frequency. Lower if decoys feel unfair. |
| `_kScoreBudgetMs` / `_kScoreDivisor` / `_kScoreMax` | 620 / 5 / 110 | Speed-score curve & cap. |
| `_kFalseStartPenalty` | 15 | False-start / decoy penalty. |

## Known TODOs / ideas
1. **[LOW] Stimulus variety.** Currently one receptor site. Could rotate stimulus types (knee-tap vs
   hot-stove vs loud-sound) with matched receptor icons — cosmetic, edu-positive. Keep canvas-only.
2. **[LOW] Audio cue.** A click on stimulus onset would sharpen reaction feel, but stay silent unless
   the host exposes an audio channel.
3. **[INFO] humanMax/starThresholds** (1700 / [500,1000,1500]) are first-pass; retune by playtest.

## Canvas-only rule
All rendering is `CustomPainter` via `GameFx` primitives (`atmosphere`, `orb`, `glowLine`, `text`,
`FxBurst`). **No PNG/JPEG/raster assets.** Keep it procedural.
