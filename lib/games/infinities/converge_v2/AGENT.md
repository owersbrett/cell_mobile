# Converge v2 — AGENT.md

Owning agent for the **Converge v2** mini-game. Self-contained module under
`lib/games/infinities/converge_v2/`. UX-passed sibling of `converge` — change
this game without touching others (including v1).

## Charter
Keep Converge v2 a fast, honest lesson in **limits of infinite series** that a
**party player can enter**: the player should *feel* convergence (the curve
leveling onto a line) vs divergence (running away) and learn to call it early.
The lift over v1 is a **gentler on-ramp** (a fading coach cue + an honest trend
readout) — never at the cost of the lesson or the standout chart.

## Boundaries (the dependency rule)
- Import ONLY: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. Nothing from another game.
- Do **not** edit the registry/catalog/host or any sibling game. The host owns
  the clock, countdown, score HUD, and results — render only the play area.
- Performance contract: **one Ticker → one CustomPainter**. The tree is header +
  2–3 buttons + flare; everything per-frame (chart, cue, trend, juice) is drawn
  in `_V2ChartPainter`.

## Architecture
- `_Series` — data: `display`, `term(n)` (n from 1), `converges`, `cue` (the
  fading on-ramp heuristic — NEW vs v1), `difficulty` (0–2), `behavior` reveal
  text, and convergent-only `limit` / `limitLabel` / `limitOptions`.
- `_kSeries` — the full v1 pool (8 convergent, 6 divergent), each given a `cue`.
- `_Mode` — `judge` (converge/diverge) or `limit` (name the value). The climax is
  forced to `judge` so the finish reads instantly.
- `_ConvergeV2GameState` — one `Ticker`, gated on `session.isRunning`; streams
  terms on `_termInterval` (accelerates with `_progress`, faster in `_isClimax`);
  scores via `session.addScore` + `session.noteStreak`.
- `_V2ChartPainter` — atmosphere + streaming partial-sum polyline + the honest
  trend readout (reference line + rising/leveling tag) + the fading coach cue +
  juice. Dashed asymptote on reveal of a convergent series.

## The v2 lift — invariants
- **Coach cue fades and dies.** `_cueAlpha` is full early, 0 by `_progress ≥ 0.5`,
  and forced 0 in the climax or once answered. Never let it persist into skilled
  play — that would dumb the lesson down.
- **Trend readout is honest.** The rising/leveling tag and reference line are
  derived from the actual `sums` (slope over `_kTrendLookback`), never from the
  hidden answer.
- **Fair score.** `_multiplier()` is clamped to `_kMaxMult` (×3). Streak still
  feeds the mastery award via `noteStreak`.
- **Streaks chain.** Correct → `_kRevealCorrect` (0.7s) hold; wrong →
  `_kRevealWrong` (1.9s) full teaching reveal.

## Invariants — do not break
- Every `term(n)` finite for n up to `_kMaxTerms` (40).
- A NAME-THE-LIMIT round only loads where `canNameLimit` is true, and
  `limitOptions` MUST contain `limitLabel`.
- Never call `session.endEarly()` — timed score-attack, no fail state.
- `flutter analyze lib/games/infinities/converge_v2/` must report zero issues.

## Tuning knobs
- `_kMaxMult` — multiplier cap (anti-runaway).
- `_kRevealCorrect` / `_kRevealWrong` — chain speed vs teaching hold.
- `_kClimaxAt` — when the FINAL BURST opens.
- `_cueAlpha` fade window (the `/ 0.5`) — how long the on-ramp lasts.
- `_kTrendLookback` — sensitivity of the rising/leveling read.
- `_kMaxPoints` / `_kFloorPoints` / `_kDecayWindow` — the speed-bonus curve.

## Verify
`flutter analyze lib/games/infinities/converge_v2/` → No issues found.
