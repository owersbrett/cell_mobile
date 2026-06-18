# GAME.md — Collider

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** particles
- **Game id:** collider
- **One-line concept:** Two particles race around a ring in opposite directions — tap the instant
  they cross. Every PERFECT collision **discovers the next particle in history.**
- **Role:** solo high-score
- **Six-in-one?** no

## Lore (learn the particles)
A collider smashes counter-rotating beams to reveal what's inside matter — exactly how real
particle physics was done. Here, each clean collision **surfaces the next entry in the discovery
timeline** (electron 1897 → … → Higgs 2012). The timing game is the toy; the discovery tour is the
teaching.

## Rules (canonical — as implemented in `ColliderGame`)
1. Two particles orbit a ring, one clockwise, one counter-clockwise.
2. **Tap anywhere the instant they cross:** PERFECT (< 10° apart) or CLOSE (< 25°).
3. Tapping while they're apart is a **miss** (−5).
4. Each successful hit **promotes** you to a faster outer ring; misses **demote** you.
5. **Shake the device to boost** particle speed (risk/reward — narrows the timing window).
6. **WOW:** every PERFECT reveals the **next particle in the discovery timeline** (see
   `../PARTICLE_TIMELINE.md`) — `name · year · who`. Non-scoring, auxiliary, dismissible.

## Controls
Tap to collide; shake to boost. Canvas-drawn only — ring beam-pipe, comet tails, convergence
glow, collision bloom + sparks, rotating detector ticks, shake-boost meter. No raster assets.

## Scoring
- PERFECT (< 10°): `15 + level × 8`. CLOSE (< 25°): `6 + level × 4`. Miss: `−5`.
- Hit → promote one ring (0–4 ladder, speed `1.08^level`); two misses in a row → reset to ring 0.

## Win / end condition
Timed score attack (~45 s). Most collision points wins.

## Difficulty curve
Ring ladder is the curve (each hit → faster ring). Shake-boost adds optional speed. Discovery
flare advances independently per PERFECT.

## Educational blocks engaged
- Quarks / Electrons / Photons / Neutrinos — ✅ via the discovery timeline flare (the full
  17-entry timeline is the richer layer).

## Potato angle
Light — subatomic bits that eventually build a potato's atoms. Don't force it.

## Session / resume
Persist score, elapsed time, ring level, miss streak, **timeline index** (which particle is next).

## Implementation
- Current: `lib/games/arcade/collider.dart` (`ColliderGame`) — registry game on
  `BioScale.particles`. Shake-to-boost already added.
- **Build:** the discovery-flare (import shared `particle_timeline.dart`, advance on PERFECT).
- **Bug:** flash bloom uses `geom.radius` (always ring 0) instead of `radiusForLevel(level)` —
  flash appears at the wrong ring (see AGENT.md).
