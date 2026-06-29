# Powers of Ten v2 — Potatuhs notes

Part of the **GAMES** rubric pass (Summer · hotpotatogames · cycle 1/3). This is
the UX-refinement alternative to `powers_of_ten`, built to the Fun-Multiplayer UX
bar in `docs/UX_REFINEMENT_PASS.md` against the teardown in
`docs/ux_pass/teardowns/powers_of_ten.md`.

## GAMES coverage
- **G** — `powers_of_ten_v2_game.dart` (`PowersOfTenV2Game`), a playable
  mini-game widget.
- **A** — `AGENT.md` (owning agent + invariants).
- **M** — `GAME.md` (rules manual).
- **E** — `EDUCATION.md` (orders of magnitude, log scales, interpolating between
  anchors, factor = adding logs).
- **S** — Session: host owns the clock; items only advance while
  `session.isRunning`, so a run closes and a fresh one re-enters cleanly.

## Teardown → fix map
1. *Stop-start cadence, no climax (2/5 pace)* → continuous conveyor: a drop loads
   the next item instantly and the answer slides to truth on a fading rail. A
   per-item timer drives pace; the **last 12s cascade** (time collapses, items
   rapid-fire, multiplier → ×3) is the finish spike.
2. *Memorization ceiling (fixed pools, 3/5 depth)* → every item is **generated**
   from "scale a known anchor by a factor" templates with a randomized factor, so
   the target exponent is continuous and the reasoning is always required.
3. *Grab ambiguity (marker detached from spine)* → the live marker rides **ON the
   spine** with a live `10ⁿ` readout under the finger — finger→marker→truth is one
   column from the first frame.

## Kept (per the teardown's "Keep")
- The slide-to-truth error band and the reveal-with-value-and-fact.
- Size → mass → time rotation and tier escalation.
- Deterministic, luck-free precision scoring.

## Brand
Scientific cyan accent (→ brand gold in the cascade), ink/atmosphere background —
on-palette with `theme/potatuhs.dart`. One Ticker, one painter, finite-guarded
geometry, 60s (<80s).
