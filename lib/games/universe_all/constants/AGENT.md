# AGENT.md — Constants (the **A** in GAMES)

Single owner-agent for the `constants` mini-game module. Improve THIS game only;
never touch other games, the registry, the catalog or the host from here.

## Scope (you may edit)
- `lib/games/universe_all/constants/constants_game.dart`
- `GAME.md`, `EDUCATION.md`, `POTATUHS.md` in this folder.

## Hard constraints
- **Imports only:** `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart` (and theme via fx). No dependency on another game's code or any
  `mini_games_batch*` symbol (per `lib/games/EXTRACTION_RECIPE.md`).
- **Host owns the clock/score/results.** Render the play area only. Gate all
  logic on `session.isRunning`; report points with `session.addScore`, streaks
  with `session.noteStreak`. Do not draw a timer/score/countdown — the host does.
- **Performance:** exactly one `Ticker` driving one `CustomPainter`. No
  per-frame `setState` over a large widget tree, no per-frame allocations in
  `paint` (the star field is a cached, seeded list).
- **Self re-entry:** internal state re-initialises on the not-running → running
  edge (`_initRun`) so a fresh session starts clean. Keep that intact.

## Tuning knobs (top of the file)
`_kPointsPerSec`, `_kStabilizeBonus`, `_kHalfWidth{Start,End}` (band narrowing),
`_kDrift{Start,End}` (drift ramp), `_kUnlock3/_kUnlock4` (dial unlock timing).
The accelerate axis = bands narrow + drift faster + more dials. Keep it in the
"keep-in-band" feel of `arcade/accelerator.dart`: always humanly recoverable.

## Balance contract (calibrate by playtest)
Keep `MiniGameSpec.humanMax` / `starThresholds` (in `mini_game_registry.dart`,
edited by the registry owner — not you) honest against real play. If you change
scoring rates, report the new realistic per-round ceiling so they can re-tune.

## Education must stay IN the mechanic
The failure diagnostics (`_diagnose`) and the reactive preview ARE the lesson —
each out-of-band state shows the real cosmological consequence. Don't replace
them with a passive info panel.

## Definition of done for any change
`flutter analyze lib/games/universe_all/constants/` → **zero issues**, and the
game still auto-starts on `isRunning`, scores, streaks, and re-enters cleanly.
