# POTATUHS — Collider

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Collider — the particles-scale timing game. Registry game on `BioScale.particles`
  (`ColliderGame`, currently `lib/games/arcade/collider.dart`); two counter-rotating beams cross a
  ring and you tap the instant they meet.
- **O — Objectives:** post the highest collision score in the ~45 s timed run. Sub-goals: land PERFECT
  hits to promote up the ring ladder; avoid the two-miss reset; walk the 17-entry discovery timeline
  (electron 1897 → … → Higgs 2012).
- **T — Tasks (the play to-do list):** watch the two particles orbit (one clockwise, one counter) ·
  tap the instant they cross — PERFECT (< 10°) or CLOSE (< 25°) · don't tap while they're apart (−5
  miss) · ride promotions to faster outer rings · optionally **shake the device** to boost speed for
  more risk/reward.
- **A — Automations (firing in the background):** the two beams orbiting at the current ring's speed
  (`1.08^level`) · the per-frame tick driving comet tails, convergence glow, collision bloom, rotating
  detector ticks, and the shake-boost meter · auto-promote on hit / auto-reset to ring 0 on two misses
  in a row · auto-advance of the discovery index on PERFECT · the host clock / countdown / results and
  AI opponents from MiniGameHost.
- **T — Testing (experimental / in-flight):** the discovery-flare on the shared
  `particle_timeline.dart` is the build target (import + advance on PERFECT) · shake-to-boost is
  already wired · open bug: the flash bloom uses `geom.radius` (always ring 0) instead of
  `radiusForLevel(level)`, so it appears at the wrong ring.
- **U — UX:** a single full-screen tap surface over a ring beam-pipe · counter-rotating comets with
  tails · a convergence glow as they near crossing · collision bloom + sparks on a hit · the
  shake-boost meter · the dismissible discovery card. Canvas-drawn only — no raster assets.
- **H — Heuristics (how you actually win):** tap on the glow as it peaks, not after the cross · chase
  PERFECTs to climb rings — payout grows with level (`15 + level × 8`) · never panic-tap when they're
  apart; one miss is recoverable, two resets you · save shake-boost for when you're confident — it
  speeds points but narrows the timing window.
- **S — Systems (what makes the world feel alive):** the WOW discovery layer — every PERFECT reveals
  the next real particle in history, the full 17-entry tour shared with Accelerator · the ring ladder
  that visibly accelerates as you succeed · the detector-ring theming of counter-rotating beams smashed
  to reveal what's inside matter, exactly how real particle physics was done.
