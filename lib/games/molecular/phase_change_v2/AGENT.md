# Phase Change v2 — Agent (A)

The owning agent for `phase_change_v2`. Improve THIS game only; do not touch the
registry, catalog, host, or sibling games.

## Charter
Keep the lesson (added energy → temperature through two latent-heat plateaus;
solid/liquid/gas; per-substance boundaries) while holding the Fun-Multiplayer UX
bar. This module is the UX-pass alternative to `phase_change` — the original
stays playable alongside it.

## Invariants (do not regress)
- **Fair, capped scoring.** The teardown's fatal flaw was
  `(60+level*12)*(1+0.12*streak)` with a `_level` that NEVER reset → a runaway
  leader decided the standing early. v2 scores each lock on THIS-attempt
  precision + speed only, hard-capped (`_kScoreBase + _kScorePrecision +
  _kScoreSpeed`, plus a flat climax bonus). `_level` ramps difficulty ONLY and
  must never feed score. `_streak` feeds `noteStreak` (mastery award) ONLY —
  never a score multiplier. Do not reintroduce any compounding term.
- **Lesson at the action.** When `_stateOf(energy) == -1` (on a plateau) the
  molecule box must shout **BREAKING BONDS** — the stalled thermometer has to
  read as physics, not a broken control. Keep the callout at the box, not buried
  on the bottom curve.
- **Active dwell.** Success comes from the `_lock` meter filling while you keep
  energy centred in `_targetE ± _bandHalf` against the ambient `_lossRate`
  bleed. No passive "reach it and wait" timer. The band hugs a plateau edge
  (`_newTarget` edge bias) so the climax of each target is precise feathering.
- **The Keep.** Preserve the latent-heat model (`_temp` flat plateaus), the live
  heating curve, the 36-molecule lattice that locks/flows/flies with snapping
  bonds, the state-colored thermometer, and the per-substance set
  (water/wax/mercury/glass/iron).
- **One Ticker → one CustomPainter.** No second AnimationController; no per-frame
  allocations in the hot path beyond the particle/pop lists.

## Tuning knobs (top of file)
Rates: `_kHeatRate`, `_kCoolRate`, `_kLossBase/_kLossStep/_kLossMax`. Band:
`_kBandBase/_kBandMin/_kBandStep`. Lock: `_kLockBase/_kLockMin/_kLockStep/
_kLockDecay`. Score: `_kScoreBase/_kScorePrecision/_kScoreSpeed/_kScoreClimax`
and `_kSpeedFull/_kSpeedZero`. Climax: `_kClimaxRemaining/_kClimaxLoss/
_kClimaxBand`. `humanMax` / `starThresholds` live in the registry spec —
playtest to tune.

## Test
`flutter analyze lib/games/molecular/phase_change_v2/` → zero. Session re-entry:
the host owns the clock; on a fresh run `_startRun()` re-arms from `isRunning`
(`_wasRunning` edge) and reseeds substance/level/streak/target — close and
re-enter must start clean.
