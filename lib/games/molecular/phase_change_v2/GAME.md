# Phase Change v2 — Manual (M)

> UX-passed alternative to `phase_change`. Same lesson (latent heat, plateaus,
> solid/liquid/gas), dialed-up fun. Ships as a sibling spec (`phase_change_v2`)
> so both are A/B-comparable in-app.

## One-liner
Pour ENERGY into a substance and **feather HEAT/COOL to lock it inside a tight
target band** for SOLID, LIQUID, or GAS — while ambient cooling constantly
bleeds the energy away.

## Scale
`BioScale.molecular` · scoreUnit: `locks` · ~60s.

## Rules
1. HOLD **HEAT** to add energy, **COOL** to remove it. Energy is **not**
   temperature — at the melting and boiling points the thermometer goes flat
   (the latent-heat plateaus).
2. The header names the target state; a colored **band** on the thermometer and
   the energy curve shows exactly where to sit.
3. Energy **bleeds away** constantly, so you must FEATHER the buttons to keep the
   column inside the band. Staying centred fills the **LOCK** meter.
4. Fill the LOCK meter to score the target, then a new substance and target
   appear. Overshoot onto a plateau and the matter shouts **BREAKING BONDS** —
   energy is going into bonds, not heat.
5. Final 12 seconds = **FLASH POINT**: faster bleed, tighter band, and a flat
   bonus on every lock.

## How to win
Most locks (highest score) when time runs out wins. Pass-and-play: every player
gets the same substances and bands; scores cluster because each lock is capped —
the standing stays legible and a trailing player can still catch up.

## Scoring (fair — no runaway)
- Per lock: `50` base + up to `30` for precision (how dead-centre you held) +
  up to `20` for speed (how fast you locked). Hard-capped at **100**.
- FLASH POINT adds a flat `+25` per lock (same for everyone, no compounding).
- **No level or streak multiplier on score.** Difficulty ramps (band tightens,
  bleed quickens) but score-per-target stays bounded → no early runaway leader.
- A streak of locks reports `noteStreak` for the mastery award only.

## Controls
- **HEAT** / **COOL** press-and-hold buttons. One verb each; feathering them
  against the bleed is the whole skill.

## Perf
One `Ticker` → one `CustomPainter`. Atmosphere, beaker, 36-molecule lattice with
snapping bonds, thermometer + target band, live heating curve, particle bursts
and "+N" pops all paint in a single pass. `shouldRepaint => true` (animated).
