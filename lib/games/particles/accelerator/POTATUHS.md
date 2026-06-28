# POTATUHS — Accelerator

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Accelerator — the particles-scale energy-ramp game. Registry game on
  `BioScale.particles` (`AcceleratorGame`, currently `lib/games/arcade/accelerator.dart`); pump the
  beam, hold the band, trigger collisions that discover real particles.
- **O — Objectives:** post the highest score in the ~45 s timed run. Sub-goals: hold the green band to
  fire collisions; climb levels (each narrows the band + speeds drain); walk the discovery timeline
  one particle at a time (`name · year · who`).
- **T — Tasks (the play to-do list):** tap anywhere to pump energy into the beam · keep the needle
  inside the green band as it constantly drains · hold the band ~2.5 s to trigger a collision · adapt
  the tap rhythm as the band narrows and drain speeds each level · read the discovery reveal, then
  dismiss it.
- **A — Automations (firing in the background):** the constant **energy drain** on the beam bar · the
  per-frame tick driving orbiting particles (speed tracks energy), band glow, dwell arc, level-up
  flash + sparks · auto-advance of the discovery-timeline index on each collision · the host clock /
  countdown / results and AI opponents from MiniGameHost.
- **T — Testing (experimental / in-flight):** the discovery-flare on the shared
  `particle_timeline.dart` is the build target (advance on collision) · reachability bug — Explore
  routes only to Collider today, so Accelerator needs the per-scale game picker · open bug: tap sparks
  spawn at `Offset.zero` instead of the gauge/tap point.
- **U — UX:** a single full-screen tap surface · vertical energy gauge with a green target band ·
  orbiting particles that visibly speed up with energy · a dwell arc filling toward collision ·
  level-up flash + spark burst · the dismissible discovery card. Canvas-drawn only — no raster assets.
- **H — Heuristics (how you actually win):** tap in short bursts to ride the band rather than
  overshooting · bank `+4/sec` band time while you wait out the 2.5 s dwell · chase the
  `30 + level² × 8` collision payout — higher levels are worth far more · slow your tap cadence as the
  band narrows so you don't blow past it.
- **S — Systems (what makes the world feel alive):** the WOW discovery layer — every collision
  surfaces the next entry in the history of matter (quarks, electrons, photons, neutrinos…), shared
  with Collider · escalating drain + narrowing band that make the beam feel harder to tame each level ·
  the "ramp it to just the right energy, then smash it" theme of a real accelerator.
