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
- **Bold, always-visible logarithmic spiral arm lanes** wind out of the core (dust-lane shadow + a hot,
  star-forming ridge). A faint spiral **ghost is drawn even at zero coherence**, so the field always reads
  as a *spiral galaxy* — never a generic disk of dots.
- The visible arms are tied to a **slow-rotating density wave** (the pattern speed) — far slower than the
  stars themselves.
- **Coherence** (surfaced on screen as the **ARM DEFINITION** meter, 0–1) is how crisp the arms read. It
  **always bleeds away** as the disk shears (`CRISP → WINDING UP → SMEARED`).
- A **beat ring** shrinks onto a target ring each beat. **Tap on the beat** to pulse the wave: definition
  jumps, the stars snap back onto crisp arms, and you score a timing bonus.
- Let it fall and the render shows the **raw sheared orbital positions** — the arms wind up and smear into
  a uniform disk (the lanes go dark, only the ghost remains). That is literally the orbital truth showing.

## On-screen legibility (the clarity contract)
- **Always-visible identity + objective** top-left: `SPIRAL GALAXY` / `PULSE THE BEAT · KEEP THE ARMS WOUND`
  — so a player instantly knows this is galactic spiral-arm formation, not an abstract merge/coherence puzzle.
- **Live score-driver readout** — a `+N/s` figure floats above the core, greening as coherence (and thus the
  per-second drip) rises. Winning behaviour is discoverable: crisp arms visibly pay.
- **Unmissable how-to hint** — a large centered `TAP ON THE BEAT` + sub-line appears at run start and **fades
  out after the player lands ~2 pulses** (`_hintFade`). In-context, self-retiring.

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
  beat ring, sparks, HUD, the score-driver `+N/s`, the fading hint and popups. No per-frame setState over a
  big widget tree — the only child is the painter.
- The spiral arm lanes are drawn as smooth log-spiral `Path`s (`_armPath`) in three passes — dust-lane
  shadow, persistent ghost, hot density-wave ridge — so the galaxy silhouette reads at every coherence level.
- Stars keep a fixed radius + arm membership; a live `orbitAngle` advances under differential rotation.
  Display position = `lerp(orbitalPos, crispWavePos, coherence)` — the entire visual thesis in one line.
- Calm ready state: when `!session.isRunning`, coherence eases back to crisp and the disk drifts slowly;
  the run resets the moment `isRunning` flips true (host owns the clock/countdown/score/results).
