# Powers of Ten v2 — Agent (A)

The owning agent for `powers_of_ten_v2`. Improve THIS game only; do not touch the
registry, catalog, host, or sibling games.

## Charter
Keep the powers-of-ten lesson (interpolate a thing onto a log size/mass/time
ladder between known anchors; the reveal teaches where it truly sits) while
holding the Fun-Multiplayer UX bar. This module is the UX-pass alternative to
`powers_of_ten` — the original stays playable alongside it.

## Invariants (do not regress)
- **The lesson is the mechanic.** A drop must teach an order of magnitude: the
  true exponent, the resolved value (`_fmtSci`), and a one-line fact. Never strip
  the reveal.
- **Continuous cadence — no dead stops.** v1's fatal flaw was a blocking reveal
  hold after every item. Resolving must LOAD THE NEXT ITEM IMMEDIATELY; the
  answer slides to truth as a fading rail ghost (`_reveals`), never a pause.
  Don't reintroduce a `revealing` state that halts input.
- **Generated, not memorizable.** Items come from `_tmpls` ("scale an anchor by a
  factor N") with a randomized factor → the target exponent is continuous. Never
  go back to a fixed finite pool. The displayed factor and the answer must stay
  consistent (`_niceN` snaps N, then `trueExp` is recomputed from it).
- **Passivity is punished.** A draining `_itemT` forces an auto-snap at the
  marker's default-middle if untouched (`forced: true`) — a poor score. Don't
  add a silent skip or a generous default.
- **Climax from the host clock.** `_climax`/`_mult` read `session.remaining`; the
  host owns the clock. The multiplier is **capped at ×3** — keep the cap (no
  runaway leader). Don't add a second timer.
- **Tight grab.** The live marker rides ON the spine (`spineX`), so
  finger→marker→truth is one column. Don't detach it to a side rail again.
- **One Ticker → one CustomPainter.** No second AnimationController; no per-frame
  allocations beyond the particle/pop/reveal lists (each capped/pruned).

## Tuning knobs (top of file / state getters)
`_tmpls` (template set, factor ranges, tiers), `_band` / `_perfectTol` /
`_goodTol` (tolerances), `_baseItemTime` (cadence), the `_climax` window (12s) and
`_mult` cap (×3), `_allowedKinds` / `_maxTier` (escalation), `_revealDur`.
`humanMax` / `starThresholds` live in the registry spec — playtest to tune.

## Test
`flutter analyze lib/games/universe_all/powers_of_ten_v2/` → zero. Session
re-entry: the host owns the clock; items only advance while `session.isRunning`,
so a run closes and a fresh one re-enters cleanly (state re-seeds on the first
running tick via `_started`).
