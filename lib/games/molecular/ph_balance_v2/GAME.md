# pH Balance v2 — Manual (M)

> UX-passed alternative to `ph_balance`. Same lesson (acids/bases, the 0–14 pH
> scale, the steep-near-7 titration curve, neutralization, CO₂ acid-creep),
> dialed-up fun. Ships as a sibling spec (`ph_balance_v2`) so both are
> A/B-comparable in-app.

## One-liner
Tap **ACID (H⁺)** to lower the beaker's pH and **BASE (OH⁻)** to raise it,
landing the needle in a target band and **feathering taps against the constant
CO₂ acid-creep** to fill the LOCK ring.

## Scale
`BioScale.molecular` · scoreUnit: `locks` · ~55s.

## Rules
1. The beaker has a live **pH** (0–14): a big readout over the liquid and a
   marker on the right-edge 0–14 indicator scale. Liquid + scale are colored by
   a universal-indicator ramp (red acid → green neutral → violet base).
2. A **target pH** is named each round (white band on the scale). **Tap ACID**
   to lower pH, **BASE** to raise it.
3. The curve is **steep near pH 7** — a drop near neutral leaps the needle
   across the equivalence point. **GHOST ticks** on the scale show exactly where
   the next ACID / BASE drop would land, so the leap is a read, not a surprise;
   a shaded **STEEP zone** marks the danger band around 7.
4. **CO₂ constantly acidifies** the liquid (the pH slides down on its own), so
   holding a target is **active**: feather taps to keep the needle CENTRED and
   fill the green **LOCK ring**. Near pH 7 you can't sit still — you *pump*
   (tap, let the drift sweep you through the band, tap again).
5. Final 12 seconds = **SURGE**: faster creep, tighter band, and a flat bonus on
   every lock.

## How to win
Most locks (highest score) when time runs out wins. Pass-and-play: every player
gets the same chemistry; scores cluster because each lock is capped — the
standing stays legible and a trailing player can still catch up.

## Scoring (fair — no runaway)
- Per lock: `45` base + up to `30` for precision (how dead-centre you held) +
  up to `20` for speed (how fast you locked). Hard-capped at **95**.
- SURGE adds a flat `+20` per lock (same for everyone, no compounding).
- **No level or streak multiplier on score.** Difficulty ramps (band tightens,
  creep quickens, curve steepens) but score-per-target stays bounded → no early
  runaway leader.
- A streak of locks reports `noteStreak` for the mastery award only.

## Controls
- **ACID (H⁺ · pH ▼)** / **BASE (OH⁻ · pH ▲)** tap buttons. No drag, no aim —
  the skill is *timing and restraint* near the steep zone, plus feathering the
  drift to hold the band.

## Perf
One `Ticker` → one `CustomPainter`. Atmosphere, beaker + colored liquid +
bubbles + wobble surface, the 0–14 indicator strip (STEEP zone, target band,
neutral-7 line, predictive ghost ticks, current marker), the LOCK ring, HUD
badges, particle bursts and "+N" pops all paint in one pass. Taps mutate fields
without `setState`; the running ticker repaints next frame. `shouldRepaint =>
true` (animated).
