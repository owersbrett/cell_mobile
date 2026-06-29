# Half-Life v2 — Manual (M)

> UX-passed alternative to `half_life`. Same lesson, dialed-up fun. Ships as a
> sibling spec (`half_life_v2`) so both are A/B-comparable in-app.

## One-liner
A radioactive sample decays as a **fuzzy glow cloud** — no counter. Tap to
measure when the glow hits **50%, 25%, 12.5%** in a row, then ride faster
samples to a triple-tap finish.

## Scale
`BioScale.atoms` · scoreUnit: `accuracy` · ~55s.

## Rules
1. A glowing sample decays continuously. There is **no number** — you estimate
   the fraction remaining from the cloud's size and brightness.
2. Each sample asks for three measurements: tap at **50%**, then **25%**, then
   **12.5%** still glowing (the highlighted target ring shows which is next).
3. Each halving takes the **same** amount of time. Nail the first beat by feel,
   then **ride the rhythm** for the next two.
4. Closer to the true moment = more points (perfect tap = bonus).
5. Each sample is faster than the last — the pace climbs to a finish.

## How to win
Most accurate measurements when time runs out wins. (Pass-and-play: same decay
for everyone; closest taps score highest — readable per-tap PERFECT/CLOSE/OFF.)

## Scoring
- Per beat: up to `60` pts, scaled by timing error (zero past `0.7` half-lives).
- Perfect (error < `0.08` half-life): `+30` bonus.
- A streak of "good" beats (error < `0.20`) reports `noteStreak` for the
  mastery award. Streaks never multiply score → no runaway leader.

## Controls
- **Tap anywhere** to measure the next un-captured target. One verb, whole-screen
  hit zone, pulsing "TAP TO MEASURE" affordance.

## Perf
One `Ticker` → one `CustomPainter`. Drifting motes, a blurred glow cloud, the
exponential curve, target rings, particle bursts and "+N" pops all paint in a
single pass. `shouldRepaint => true` (animated).
