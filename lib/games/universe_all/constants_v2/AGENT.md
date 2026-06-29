# AGENT.md — Constants v2 (the **A** in GAMES)

Single owner-agent for the `constants_v2` mini-game module. Improve THIS game
only; never touch other games, the registry, the catalog or the host from here.

## Scope (you may edit)
- `lib/games/universe_all/constants_v2/constants_v2_game.dart`
- `GAME.md`, `EDUCATION.md`, `POTATUHS.md` in this folder.

## What v2 is
A UX-pass refinement of `constants` (sibling, not a replacement). It KEEPS the
4-dial fine-tuning depth, the live cosmos preview + named failure diagnostics,
the continuous life-permitting scoring + streak, and the accelerating climax. It
FIXES three teardown failures:
1. **Input = mental model** — `_grab` locks to the row's knob and `_dragTo` is a
   *relative* drag (knob tracks the finger 1:1 from its current value): no
   teleport, no cross-row hijack. Do not regress to a "paint a value onto the
   row" (`_pickAndSet`) model.
2. **Telegraphed surges** — `_stepSurges` charges a surge first (amber warning
   ring + direction chevron) so it can be CAUGHT; keep the telegraph window
   (`_kChargeStart/End`) generous enough to feel fair.
3. **Spectator legibility** — the full-width UNIVERSE HEALTH meter
   (`_paintHealthMeter`, product-of-dials habitability). Keep it the headline.

## Hard constraints
- **Imports only:** `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart` (theme via fx). No dependency on another game's code.
- **Host owns clock/score/results.** Render the play area only. Gate logic on
  `session.isRunning`; report points with `session.addScore`, streaks with
  `session.noteStreak`. Do not draw a timer/score/countdown.
- **Performance:** exactly one `Ticker` driving one `CustomPainter`. No per-frame
  `setState` over a large tree; the star field is a cached, seeded list.
- **Self re-entry:** state re-initialises on the not-running → running edge
  (`_initRun`). Keep that intact.

## Tuning knobs (top of the file)
`_kPointsPerSec`, `_kStabilizeBonus`, `_kHalfWidth{Start,End}` (band narrowing),
`_kDrift{Start,End}` (drift ramp), `_kUnlock3/_kUnlock4` (unlock timing),
`_kSurgeGap{Start,End}` (surge cadence), `_kCharge{Start,End}` (telegraph window),
`_kClimaxFrom` (crunch start). Accelerate axis = bands narrow + drift faster +
surges quicker. Always keep it humanly recoverable.

## Balance contract (calibrate by playtest)
Keep `MiniGameSpec.humanMax` / `starThresholds` (in `mini_game_registry.dart`,
edited by the registry owner — not you) honest. If you change scoring rates,
report the new realistic per-round ceiling so they can re-tune.

## Education must stay IN the mechanic
The failure diagnostics (`_diagnose`), the reactive preview, and the
product-of-dials health meter ARE the lesson. Don't replace them with a passive
info panel.

## Definition of done for any change
`flutter analyze lib/games/universe_all/constants_v2/` → **zero issues**, and the
game still auto-starts on `isRunning`, scores, streaks, and re-enters cleanly.
