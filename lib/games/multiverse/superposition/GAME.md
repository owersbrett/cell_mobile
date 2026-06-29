# Superposition — GAME.md (the Manual)

**Scale:** multiverseAll · **Verb:** MEASURE-AT-THE-RIGHT-MOMENT · **Score unit:** favorable collapses

## Premise
A qubit floats in a **superposition** of two states — |↑⟩ (up) and |↓⟩ (down). Its
wavefunction oscillates, so the probability of measuring "up" sweeps continuously
between 0% and 100%. One pole **glows** — that is your *target* outcome. Tap to
**MEASURE** and **collapse** the wavefunction: the system snaps to one definite
state, chosen at random and **weighted by the current probability**.

## Rules
- The state vector sweeps up and down the sphere; `P(↑) = ½ + ½·sin(phase)`, and
  `P(↓) = 1 − P(↑)` — they always sum to 1.
- The bottom **probability bar** shows `P(target)` right now. The right edge is the
  sweet spot (near 100%).
- **Tap anywhere = MEASURE.** The wavefunction collapses to a single outcome:
  - **Land your target** → score `≈ 100 × P(target)` points (+ a small streak bonus).
    Higher probability at the moment you measure = more points.
  - **Land the other state** → no points, streak resets (you measured too early).
- After a brief collapse, a **fresh superposition** spawns with a new random target.

## How to win
Score the most **favorable collapses** before time runs out. Measure when the wave
most favors the glowing state.

## Acceleration
- The oscillation **speeds up** each level (favorable windows pass faster).
- At level 4 a **second qubit** joins: both must collapse to their targets, and the
  **joint probability multiplies** (`P₁ × P₂`) — huge payoff, brutal timing.

## Teaches
Superposition, the wavefunction, measurement & collapse, probability amplitudes,
and that joint outcomes multiply.

## Session (the S)
Host-owned clock (~50s). Closes cleanly to the results screen; a fresh run resets
score, streak, level, and qubit count via `MiniGameSession.hostReset()`.
