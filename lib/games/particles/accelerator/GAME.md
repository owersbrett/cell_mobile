# GAME.md — Accelerator

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** particles
- **Game id:** accelerator
- **One-line concept:** Pump the beam and hold it in the energy band — every triggered collision
  **discovers the next particle in history.**
- **Role:** solo high-score
- **Six-in-one?** no

## Lore (learn the particles)
Real accelerators ramp particles to just the right energy, then collide them to reveal new
matter. Here you pump energy, hold the green band, and each collision **surfaces the next entry in
the discovery timeline** — sharing the WOW layer with Collider.

## Rules (canonical — as implemented in `AcceleratorGame`)
1. **Tap anywhere** to pump energy into the beam bar; energy **drains constantly**.
2. Keep the needle **inside the green band**.
3. **Hold the band ~2.5 s** to trigger a collision and score (`+30` base plus a level bonus).
4. Each level the band **narrows** and drain **speeds up** — find the rhythm.
5. **WOW:** each collision reveals the **next particle in the discovery timeline**
   (`../PARTICLE_TIMELINE.md`) — `name · year · who`. Non-scoring, auxiliary, dismissible.

## Controls
Tap to pump. Canvas-drawn only — vertical energy gauge, orbiting particles that speed with energy,
band glow, dwell arc, level-up flash + sparks. No raster assets.

## Scoring
- `+4`/sec while in the band; collision (band held 2.5 s): `30 + level² × 8`.

## Win / end condition
Timed score attack (~45 s). Most points wins.

## Difficulty curve
Per level: drain `+0.04/s`, tap boost `× 0.95`, band width `−0.03` (floor 0.06). Discovery flare
advances per collision.

## Educational blocks engaged
- Quarks / Electrons / Photons / Neutrinos — ✅ via the shared discovery timeline flare.

## Potato angle
Light — keep the focus on the discovery WOW, not the potato.

## Session / resume
Persist score, elapsed time, energy, level, dwell progress, **timeline index**.

## Implementation
- Current: `lib/games/arcade/accelerator.dart` (`AcceleratorGame`) — registry game on
  `BioScale.particles`. **Not reachable from Explore today** (Explore returns only Collider) —
  needs the per-scale game picker. See `../EDUCATION.md`.
- **Build:** discovery flare (shared `particle_timeline.dart`, advance on collision).
- **Bug:** tap sparks spawn at `Offset.zero` (canvas top-left) instead of the gauge/tap point.
