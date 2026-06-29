# Powers of Ten v2 — Manual (M)

> UX-passed alternative to `powers_of_ten`. Same log-ladder lesson, dialed-up
> fun. Ships as a sibling spec (`powers_of_ten_v2`) so both are A/B-comparable
> in-app.

## One-liner
A thing is named — *"a line of 12,000 sand grains"*, *"3× the Sun's mass"* — and
you drag a marker up/down a logarithmic ladder to its true order of magnitude.
Drop it, the answer slides to the truth on a fading rail, and the next thing is
already there. No dead stops; the clock tightens; the last 12s cascade.

## Scale
`BioScale.universeAll` · scoreUnit: `precision` · 60s.

## Rules
1. Read the named thing and the ladder (size · meters / mass · kilograms /
   time · seconds). The faint anchors on the right (atom, human, Earth,
   light-yr, galaxy) are the scaffold you interpolate between.
2. **Drag the marker — it rides ON the spine** — to where you think the thing
   sits, then **release to drop**. Tap-to-place + release also works. Closer to
   the true magnitude = more precision points.
3. **A per-item timer bar drains.** If it runs out you **auto-snap** at the
   marker's current spot — a forced estimate, still scored. Don't go passive.
4. Every item is **generated** ("scale a known anchor by a factor"), so the
   exponent is different every play — you must *reason*, never recall.
5. **Climax (last 12s):** per-item time collapses, items rapid-fire, and a score
   multiplier ramps to **×3** — a CASCADE finish spike.
6. Difficulty climbs: size → +mass → +time ladders rotate in, tolerances tighten,
   harder/obscurer factors appear.

## How to win
Most precision points when time runs out wins. (Pass-and-play: every player faces
generated items of the same difficulty band; per-drop feedback —
PERFECT / CLOSE / OK / OFF — is readable.)

## Scoring
- Per drop: `acc = (1 − error/band)` where `error` = decades off; base `100×acc`.
- `error ≤ perfectTol` → **PERFECT** (+50 base) and the streak grows.
  `error ≤ goodTol` → **CLOSE** (streak grows). Else **OK**/**OFF**, streak resets.
- Final points `= base × mult`, where `mult` is `1` normally and ramps to **×3**
  through the last-12s cascade (capped — no runaway).
- Streak reported via `noteStreak` for the mastery award.

## Controls
- **Drag / tap on the ladder** to move the marker; **release** to drop. One verb,
  one column: finger → marker (on the spine) → truth.

## Perf
One `Ticker` → one `CustomPainter` (`repaint:_ctrl`). Atmosphere, ladder,
gridlines, anchors, timer bar, live marker, up to three fading slide-to-truth
reveals, particles and "+N" pops all paint in a single pass. No second
controller; the climax reads `session.remaining` (host owns the clock). All
geometry is ladder-normalized and clamped finite.
