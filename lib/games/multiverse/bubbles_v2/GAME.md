# Bubbles v2 — Manual (M)

> UX-passed alternative to `bubbles`. Same eternal-inflation lesson, one clean
> verb. Ships as a sibling spec (`bubbles_v2`) so both are A/B-comparable in-app.

## One-liner
A false-vacuum sea inflates forever, spontaneously nucleating bubble universes
that grow at light-speed. You can't make them and you can't fill the sea — you
can only HARVEST the ripe ones and triage the collisions before the cascade.

## Scale
`BioScale.multiverseAll` · scoreUnit: `universes` · ~55s.

## Rules
1. **The vacuum nucleates bubbles on its own** in open space — you never place
   them. Each inflates continuously and turns **gold (ripe)** when mature.
2. **TAP a gold bubble to HARVEST it.** One verb, forgiving hit radius, never an
   accidental nucleation. Tapping an immature/empty spot does nothing.
3. **Bigger ripe = worth more.** A ripe bubble keeps inflating, so waiting banks
   more — but a bigger bubble crowds its neighbours sooner. Ripen vs bank now.
4. **A red WARNING ARC** appears ~1.2s before two bubbles collide. Harvest
   either one to **DEFUSE** the collision and save the pair. Ignore it and both
   **COLLIDE and SPOIL** (0 points, combo broken). Universes stay causally
   separate.
5. **COMBO:** chain harvests within ~1.7s to compound a multiplier (capped ×3,
   no runaway). Any collision breaks it.
6. **Climax (last ~10s):** the vacuum CASCADES — nucleation and growth surge,
   warnings bloom everywhere, and you can no longer save them all.

## How to win
Most universes harvested (points) when time runs out wins. Read the warnings,
bank high-value bubbles mid-combo, and accept that the sea can't be tamed.

## Scoring
- Harvest: `(8 + sizeBonus + clutchBonus) × comboMult`, rounded.
  - `sizeBonus` = `(radius − maturity) × 0.7`, capped 16 — bigger ripe = more.
  - `clutchBonus` = +6 if the bubble was WARNED (rewards defusing a collision).
  - `comboMult` = `1 + (combo−1) × 0.25`, capped **×3**.
- Collision (SPOIL): 0 points, combo reset.
- Combo reported via `noteStreak` for the mastery award.

## Controls
- **Tap a gold bubble** to harvest. That is the only verb. Empty/immature taps
  give a harmless ripple, never an action.

## Tuning
`humanMax` 1100 · `starThresholds` [400, 700, 1000]. Re-tune by playtest.

## Perf
One `Ticker` → one `CustomPainter`. Atmosphere, inflation rings, every bubble
(+ warning arcs), particles, "+N" pops and the combo badge paint in a single
pass. Bubbles capped (`_kMaxBubbles`), particles capped (`_kMaxParticles`),
O(n²) collision over the cap. All geometry guarded finite.
