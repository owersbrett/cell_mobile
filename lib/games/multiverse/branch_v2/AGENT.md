# Branch v2 — Agent (A)

The owning agent for `branch_v2`. Improve THIS game only; do not touch the
registry, catalog, host, or sibling games.

## Charter
Keep the many-worlds lesson (every quantum choice splits the world; both
outcomes happen; you can't prune the abandoned world, only navigate amplitude)
while holding the Fun-Multiplayer UX bar. This module is the UX-pass alternative
to `branch` — the original stays playable alongside it.

## Invariants (do not regress)
- **Amplitude IS the score, Born weight IS the visual.** Node radius/brightness
  encode |ψ|²; score scales with the amplitude you bank. Don't sever that link.
- **The decision must stay non-trivial.** The original's fatal flaw was "tap the
  bigger number." v2's choice weighs *heavy + keep coherence* against *dive for
  resonance + lose coherence*, with a one-step lookahead so resonance can be
  ROUTED onto a heavy world. Never collapse this back to a max() of two %s.
- **Passivity must be punished.** No default selection — you must commit each
  fork or DECOHERE (keep only `min(amp)`, halved, streak reset). An idle player
  must score far below an active one. Do not reintroduce a silent up-default.
- **Coherence is a streak, not a runaway lever.** Multiplier `1 + streak×0.15`
  capped at `×4`. Keep the cap; report via `noteStreak`.
- **The abandoned world keeps splitting (decoherence) — but DIM.** One short
  non-recursive `_abandonedSplit`, background alpha. The live fork is the only
  bright thing. Don't bring back the recursive ghost fan that out-painted it.
- **Climax from the host clock.** `_climax` reads `session.remaining`; the host
  owns the clock. Don't add a second timer.
- **One Ticker → one CustomPainter.** No second AnimationController; no per-frame
  allocations beyond the particle/pop lists.

## Tuning knobs (top of file)
`_bAmpPoints`, `_bMultStep`/`_bMultMax`, `_bSpreadLo/Hi`, `_bClimaxWindow`,
`_bTrailCap`, the `_speed`/`_gap`/`_genFrac` curves, and resonance probability
/ bonus in `_makeNode`. `humanMax` / `starThresholds` live in the registry spec
— playtest to tune.

## Test
`flutter analyze lib/games/multiverse/branch_v2/` → zero. Session re-entry: the
host owns the clock; the tree only advances while `session.isRunning`, so a
fresh run resumes from the held tree and ticks cleanly — close and re-enter must
start clean.
