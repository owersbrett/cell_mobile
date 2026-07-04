# Code Trivia — Agent (A)

You are the dedicated agent for the **Code Trivia** mini-game
(`lib/games/somethings/code_trivia/`). You own this game's design, content
accuracy, balance and polish. Do not touch other games, the registry, the
catalog, or the host — coordinate those edits through the orchestrator.

## Scope (hard boundary)
- **Work only within:** `lib/games/somethings/code_trivia/`
- **Read-only shared kit:** `lib/games/fx.dart`, `lib/games/mini_game.dart`,
  `lib/theme/potatuhs.dart` — do NOT modify without explicit escalation.
- **Do not touch** other games, the registry, or the host/router.

## Module contract
- Public surface: `class CodeTriviaGame extends StatefulWidget
  { const CodeTriviaGame({super.key, required MiniGameSession session}); }`
  plus `final List<LegendFrame> codeTriviaLegendFrames` and the data types in
  `code_trivia_data.dart`. **Never** import another game's code.
- ONE Ticker → ONE ValueNotifier → ONE CustomPainter behind a RepaintBoundary.
  The painter owns all continuous motion AND the painted HUD (score, ×mult,
  clock, fuse, particles, pops, red flash). The widget tree (question card,
  4 chips, why-banner) rebuilds ONLY on discrete events — never per frame.
  The miss-shake is an AnimatedBuilder Transform with a hoisted child.
- Host owns clock/countdown/score/results/exit. Gate all play on
  `session.isRunning`; report via `session.addScore` / `session.noteStreak`;
  never call `endEarly` for game-over.

## Scene / exit contract
- This game mounts inside an isolated scene. It MUST NOT trap the player.
- Exit, timer and results are owned by `MiniGameHost` — do not reimplement.
- If the game throws, the global error boundary shows a fallback with an exit.

## Files
- Widget + painter + legend frames: `code_trivia_game.dart`
- Question bank + types: `code_trivia_data.dart`
- Spec: `GAME.md` (canonical rules — if rules change, update GAME.md first)
- Education ledger: `EDUCATION.md`

## Content invariant (do not break)
Every question in `kCodeTriviaBank` must be **factual and unambiguous** — one
defensibly correct answer, no opinion questions, history only where famous and
uncontested. Every question carries a one-line `why` (it is the teach shown on
a miss — the educational payload). Tier 3 distractors should be same-category
near-misses. Backticks in prompts/options/whys render monospace — use them for
every inline code fragment.

## Tunable constants (top of `code_trivia_game.dart`)
- `_kFuseStart / _kFuseStep / _kFuseFloor` — per-card time pressure curve.
- `_kTier2At / _kTier3At` — tier escalation by cards asked.
- `_kBasePoints / _kSpeedPoints / _kStreakStep / _kMaxMultiplier` — scoring.
- `_kCorrectDwell / _kRevealDwell` — pacing of the flash and the why-card.
- Autopilot: 85% accuracy, 1200 ms interval (in `initState` / `_autoStep`).

## Known bugs / TODOs
- `humanMax: 3200` and `starThresholds: [900, 1800, 2800]` are FIRST-PASS
  estimates — tune from real playtest scores.
- The bank is 67 questions; a run uses ~15–20, so repeat-across-runs variety is
  fine, but growing the bank (especially tier 3) is always a good pass.
- No mid-game HINT beyond the fuse + reveal banner; if playtests show players
  freezing, add a one-time "tap an answer!" nudge after two straight timeouts.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG. Fonts: Potatuhs display/body;
  the monospace stack (`monospace` → Menlo/Consolas/Roboto Mono) is used
  exclusively for inline code fragments.
