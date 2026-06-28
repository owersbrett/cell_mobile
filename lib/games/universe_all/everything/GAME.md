# GAME.md — Everything (universe_all)

> Self-contained module. Extracted from the `mini_games_batch3.dart` megafile so it can be improved
> without touching other games. Depends only on `MiniGameSession` + Flutter.

- **Scale:** universeAll · **Game id:** registry spec built via `EverythingGame(session:)`
- **Module:** `lib/games/universe_all/everything/everything.dart`
- **Concept:** multilingual word-finder — a word is shown in many rotating foreign-language forms on
  three concentric wheels; type its English meaning before the per-word timer runs out.

## Structure (all private to the module)
- `EverythingGame` / `_EverythingGameState` — game loop, gates on `session.isRunning`, scores via
  `session.addScore`, ends via the host clock.
- `_EWWord` + `_ewWords` — the word data (English answer + category + foreign forms).
- Painters/widgets: `_EverythingWheelPainter`, `_WordTimerBar`/`_TimerArc(Painter)`, `_HintChip`,
  `_EWTextField`, `_EWGameOverPanel`. A local `_JuiceParticle` (inlined; no megafile dependency).

## Known follow-up (from status board)
- "Everything 22 languages" polish — flesh out `_ewWords` forms toward 22 real languages per word.

## For future agents
- Edit ONLY this folder. Tune feel via the `_ew*` constants at the top.
