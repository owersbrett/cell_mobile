# POTATUHS — Spiral Arms

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Spiral Arms — the second galactic-scale game (companion to Dark Matter). Self-contained
  module (`SpiralArmsGame` in `lib/games/galactic/spiral_arms/`); on `BioScale.galactic`. Host owns the
  clock/countdown/score/results; the module renders only the play area.
- **O — Objectives:** post the highest score by keeping the galaxy's spiral arms **crisp** across the
  60s round. Sub-goals: chain clean on-beat pulses for the streak multiplier, and ride high coherence for
  the per-second drip.
- **T — Tasks (the play to-do list):** watch the incoming beat ring shrink onto the target · **tap on the
  beat** to pulse the density wave · stack consecutive on-beat hits to climb the multiplier · keep the
  coherence bar in the green (CRISP) · brace for the level-ups — faster shear, more arms, tighter windows.
- **A — Automations (firing in the background):** ONE Ticker driving differential rotation (inner stars
  faster than outer) · the slow density-wave pattern phase · the beat clock + hit-window check · constant
  coherence decay (the disk shearing toward a smear) · the per-second score drip and on-beat bonus · the
  difficulty ramp (level every ~12s to LV5).
- **T — Testing (experimental / in-flight):** tune `humanMax`/`starThresholds` from real playtests; tune
  the coherence decay vs on-beat boost so a skilled player can *just* hold CRISP at LV5; confirm the smear
  reads as genuinely featureless at low coherence; verify clean session re-entry.
- **U — UX:** Canvas-only — a glowing core, ~170 orbiting stars, slow-rotating arm spines, an incoming
  beat ring landing on a target ring, sparks + PERFECT popups on good pulses, and a top-bar coherence meter
  reading CRISP / SHEARING / SMEARING. Calm, still-armed ready state before the host starts the clock.
- **H — Heuristics (how you actually win):** treat it as a rhythm game — *feel* the beat, don't stare at the
  bar · go for PERFECT (center of the window) to bank both the bonus and the biggest coherence top-up ·
  never panic-tap off-beat (it consumes the beat AND dents coherence) · keep the multiplier alive; the
  streak is where the score really comes from at high levels.
- **S — Systems (what makes the world feel alive):** the galaxy *is* the living system — it visibly tears
  its own arms apart by spinning, and the player feels the slow density wave fighting to hold the pattern.
  The lesson (arms are traffic-jam **density waves**, not a fixed pinwheel — see EDUCATION.md) is embodied
  in the `lerp(orbital, crisp, coherence)` render, not narrated.
