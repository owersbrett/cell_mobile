# GAME.md — Spiral Arms

> Canonical spec for the second Galactic-scale game. Where **Dark Matter** is about the unseen mass that
> binds a galaxy, **Spiral Arms** is about the unseen *wave* that shapes it.

- **Scale (cell):** galactic
- **Game id:** `spiral_arms` (widget `SpiralArmsGame`, self-contained module)
- **One-line concept:** A spinning galaxy shears its own spiral arms apart — keep them crisp by pulsing on
  the beat to reinforce the density wave.
- **Role:** solo high-score / party round

## The science (this IS the mechanic)
A galaxy disk rotates **differentially**: inner stars orbit much faster than outer stars. Anything drawn
on the disk should therefore wind up tighter and tighter every rotation and smear into a featureless blur
within a few orbits (this is the real "winding problem" / "winding dilemma"). Yet spiral arms persist for
billions of years. The resolution: **the arms are density waves**, not fixed groups of stars. Stars stream
*through* a slowly-rotating compression pattern — like a traffic jam that holds its shape while individual
cars pass through it. The player feels both halves of this: the disk constantly shears (differential
rotation is always running), and a slow pattern (the wave) is what keeps the arms coherent.

## Core loop
- A disk of ~170 stars orbits a bright core; **inner stars visibly outrun outer stars** (differential).
- The visible arms are tied to a **slow-rotating density wave** (the pattern speed) — far slower than the
  stars themselves.
- **Coherence** (a 0–1 meter) is how crisp the arms read. It **always bleeds away** as the disk shears.
- A **beat ring** shrinks onto a target ring each beat. **Tap on the beat** to pulse the wave: coherence
  jumps, the stars snap back onto crisp arms, and you score a timing bonus.
- Let coherence fall and the render shows the **raw sheared orbital positions** — the arms wind up and
  smear into a uniform disk. (That is literally the orbital truth showing through.)

## Escalation (accelerate)
Over the 60s round the level climbs (every ~12s, to LV5):
- **Faster differential rotation** — the disk shears harder, coherence bleeds faster.
- **More arms** — 2 → 3 → 4.
- **Tighter timing windows** and a shorter beat period — the pulse demands sharper rhythm.

## Scoring
- **Points per second** scaled by current coherence (crisp arms pay continuously).
- **On-beat bonus** = base × streak-multiplier × timing accuracy (PERFECT pays most).
- **Streak multiplier** (up to ×5) for consecutive on-beat pulses; an off-beat tap or a missed beat
  resets the streak and dents coherence.
- `scoreUnit`: "coherence".

## How to win
Highest score when the 60s run ends — keep the arms crisp and chain clean on-beat pulses.

## Spec (registered in `mini_game_registry.dart` — DO NOT edit from this module)
- `humanMax: 1600`, `starThresholds: [450, 1000, 1600]` (seed values; tune by playtest).
- `durationSeconds: 60`, `accent: Color(0xFFE1A636)`, `icon: Icons.blur_circular`.

## Implementation notes
- ONE `Ticker` drives all physics; ONE `CustomPainter` (`_SpiralPainter`) draws disk, arms, stars, core,
  beat ring, sparks, HUD and popups. No per-frame setState over a big widget tree — the only child is the
  painter.
- Stars keep a fixed radius + arm membership; a live `orbitAngle` advances under differential rotation.
  Display position = `lerp(orbitalPos, crispWavePos, coherence)` — the entire visual thesis in one line.
- Calm ready state: when `!session.isRunning`, coherence eases back to crisp and the disk drifts slowly;
  the run resets the moment `isRunning` flips true (host owns the clock/countdown/score/results).
