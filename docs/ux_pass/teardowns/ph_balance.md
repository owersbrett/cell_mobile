# ph_balance — UX Teardown
scale: molecular · duration: 50s · scoreUnit: balance
## Scores (1–5)  → TOTAL: 25/35
- Instant legibility: 3 — Beaker with colored liquid, a 0–14 indicator strip with a white target band, big pH readout, and TARGET/LV/STREAK HUD. Rich and well-organized, but "land in the band AND hold" is two ideas you learn by playing, not at a glance; the strip-vs-beaker split divides attention.
- Affordance clarity: 4 — Two large bottom buttons, `ACID (H⁺ pH ▼)` / `BASE (OH⁻ pH ▲)`, with press-scale feedback. Clear. Minor: that the *needle eases* (so a tap's effect lands a frame later) isn't signaled and can feel like input lag.
- Juice & feedback: 4 — Rising bubbles, burst sparks, `+pts` popups, green success flash, miss flash, the green hold-ring around the readout, full color-ramp liquid. Rich, single-painter, taps mutate state without per-tap setState.
- Fair/readable competition: 3 — Hit points + in-band drip (`+4/s`) make scores comparable; no point loss on overshoot (only streak). Fair, but the drip-while-holding rewards camping a band, which is low-drama for spectators.
- Skill depth: 4 — The strongest ceiling in the set: `_steep(pH)` makes drops swing hard near pH 7, so restraint/anticipation near the equivalence point is a genuine learnable skill, layered with CO₂ drift (L3+) and a drifting target (L4+).
- Pace & climax: 3 — Real acceleration (tighter `tol`, shorter `hold`, stronger drops, steeper curve, drift). But "land then hold for ~1s" injects steady dead-hold time, flattening the per-target rhythm rather than spiking it.
- Polish: 4 — The beaker, indicator strip, and color ramp are the most polished art in the group; cohesive and jank-free.
## Top 2–3 UX failures (cite the mechanic)
1. Eased-needle vs. discrete tap: `_ph` chases `_phGoal` via `exp(-dt*14)`, so the visible response trails the tap. Combined with `_steep` near 7, players overshoot because the feedback they're reacting to is delayed — feels like lag, not skill.
2. Hold-to-score is passive: once in-band, the optimal play is to *stop touching* and let the `_kDripPerSec` drip and hold meter fill. The most skill-tested moment (landing) is immediately followed by a do-nothing hold — anticlimactic and spectator-flat.
3. Two-channel readout split: the steep-curve lesson lives in *button feel*, but the only visual of "the curve" is implicit; players feel the overshoot without seeing *why* pH 7 is steep, so the lesson is felt-but-not-shown.
## Redesign brief — what ph_balance_v2 MUST change
- Tighten input→feedback: either reduce the ease lag near the band or show a predictive "where this drop lands" ghost marker so overshoot is a read, not a surprise. Make the steepness *visible* (e.g. a titration-curve overlay that bulges at 7).
- Replace static hold with active hold: make holding require small corrective taps against drift (pull drift earlier, or add a wobble), so the climax of each target is sustained micro-control rather than hands-off camping.
- Add readable head-to-head tension for party mode (closest-to-target, or a shared moving target) so the standing reads moment-to-moment, not just on the score line.
## Keep (education + what works)
- The titration-curve lesson is the whole point and it works: `_steep(pH)` peaking near 7 makes the equivalence point *felt*, and the universal-indicator color ramp (red→green→violet) plus the 0–14 strip teach acids/bases/neutralization in the mechanic. Preserve all of it.
- The CO₂-creep drift and drifting target as escalating, chemistry-true difficulty levers.
- The clean host-driven `_startRound` session reset and the ACIDIC/NEUTRAL/BASIC tag.
