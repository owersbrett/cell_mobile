# AGENT.md — Cosmic Timeline

> The A in GAMES. This game has a dedicated agent spec so its redesign/bug-fix work can be dispatched in
> isolation without touching other games, the registry, the catalog, or the host.

## Identity
You are the **Cosmic Timeline** agent. You own exactly one folder:
`lib/games/universe_all/cosmic_timeline/`. You do not edit the registry, the catalog, the host, or any
other game. If a change needs a registry/catalog edit (e.g. spec fields), report it back — do not make it.

## Mandate
Keep the ORDER-THE-EPOCHS mechanic crisp, correct, and educational. The lesson lives in the mechanic:
chronological order of the universe + the real "when" of each epoch + the logarithmic deep-time intuition.

## Dependency rule (hard)
Import ONLY: `dart:math`, `package:flutter/material.dart`, `../../mini_game.dart`, `../../fx.dart`,
`../../../theme/potatuhs.dart` (transitively via fx). NEVER import another game or a `mini_games_batch*`
file. Inline any tiny shared helper you need (isolation beats DRY here).

## Contract with the host
- Take a `MiniGameSession`; gate all play on `session.isRunning`.
- Report points via `session.addScore`; report combo via `session.noteStreak`.
- The host owns the clock, 3-2-1 countdown, score HUD, and results screen. Render ONLY the play area.
- Ready state must look calm and alive (juice decays pre-run); auto-start on `isRunning`.

## Performance budget
One `AnimationController` (Ticker) → one `CustomPainter`. No per-frame `setState` over big widget trees.
Drag updates mutate card x/y directly and let the ticker repaint. Keep a full run under ~80s of build work.

## Scientific-accuracy gate
The `when` labels and the chronological `rank` are load-bearing education — do not break them. If you add
or refine epochs, keep `rank` strictly chronological and `tSec` (seconds after the Big Bang) consistent
with `when`. Never invent a fake date to fill a gap; surface missing data loudly.

## Definition of done
`flutter analyze lib/games/universe_all/cosmic_timeline/` → ZERO issues. The four GAMES docs in this folder
(GAME.md, AGENT.md, EDUCATION.md) plus POTATUHS.md stay in sync with the code.
