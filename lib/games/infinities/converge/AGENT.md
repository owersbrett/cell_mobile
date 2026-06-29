# Converge — AGENT.md

Owning agent for the **Converge** mini-game. Self-contained module under
`lib/games/infinities/converge/`. Change this game without touching others.

## Charter
Keep Converge a fast, honest lesson in **limits of infinite series**: the player
should *feel* convergence (the curve leveling onto a line) vs divergence (the
curve running away) and learn to call it before it's visually obvious.

## Boundaries (the dependency rule)
- Import ONLY: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. Nothing from another game or a
  `mini_games_batch*` file.
- Do **not** edit the registry/catalog/host or any sibling game. The host owns
  the clock, countdown, score HUD, and results — render only the play area.
- Performance contract: **one Ticker → one CustomPainter**. No per-frame
  setState over a large tree (the tree here is header + 2–3 buttons + flare).

## Architecture
- `_Series` — data: streamed `display`, `term(n)` (n from 1), `converges`,
  `difficulty` (0–2), `behavior` reveal text, and for convergent series a
  `limit` / `limitLabel` / `limitOptions` for NAME-THE-LIMIT.
- `_kSeries` — the pool (8 convergent, 6 divergent). The game accumulates partial
  sums itself; series only supply the nth term.
- `_Mode` — `judge` (converge/diverge) or `limit` (name the value).
- `_ConvergeGameState` — one `Ticker` (`_onTick`), gated on `session.isRunning`;
  streams terms on `_termInterval` (accelerates with `_progress`); scores via
  `session.addScore` + `session.noteStreak`.
- `_ChartPainter` — atmosphere + the streaming partial-sum polyline + juice.
  Dashed asymptote drawn only on reveal of a convergent series.

## Invariants — do not break
- Every `term(n)` must be finite for n up to `_kMaxTerms` (40).
- A NAME-THE-LIMIT round only loads for a series where `canNameLimit` is true,
  and `limitOptions` MUST contain `limitLabel`.
- Never call `session.endEarly()` — this is a timed score-attack, no fail state.
- `flutter analyze lib/games/infinities/converge/` must report zero issues.

## Tuning knobs
- `_kMaxPoints` / `_kFloorPoints` / `_kDecayWindow` — the speed-bonus curve.
- `_kStreakStep` — correct-answers-per-multiplier step.
- `_termInterval` lerp endpoints — streaming speed / acceleration.
- `_pickSeries` difficulty gate — how fast subtle series enter the rotation.
- Add series by appending to `_kSeries` with an honest `difficulty` and
  `behavior`. Convergent additions should carry clean `limitOptions`.

## Verify
`flutter analyze lib/games/infinities/converge/` → No issues found.
