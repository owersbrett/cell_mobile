# POTATUHS — Space Rush

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Space Rush — the solar-system-scale microgame gauntlet. Self-contained module
  (`SpaceRushGame` in `lib/games/solar_systems/space_rush/`); on `BioScale.solarSystems`; host owns the
  60s clock, score total and results, the module owns the round machine.
- **O — Objectives:** post the highest **clears** count — survive the longest string of ~2-second
  micro-challenges as they accelerate. Sub-goals: a clean no-miss streak, and surviving past each WARP
  UP into the near-subliminal-prompt late game.
- **T — Tasks (the play to-do list):** read the one-word prompt fast · DODGE asteroids by sliding your
  probe · CATCH comet grains with the scoop · LAND the lunar module gently with thruster taps · SPIN up
  the gas giant by swiping in circles · SORT out the little dwarf planets and leave the big planets
  alone · TILT a world's axis to the marked lean and hold it · pop the Sun's FLARES before they fade.
- **A — Automations (firing in the background):** the internal phase machine (instruction → playing →
  result → speedUp) · per-frame physics in each microgame (falling rocks/grains, lunar gravity vs
  thrust, oblate spin, drifting bodies, flare arcs) · the difficulty ramp shrinking timers and tightening
  every microgame's knobs · the no-repeat picker · particle bursts and the shared starfield.
- **T — Testing (experimental / in-flight):** tuning each microgame's clear-difficulty against the
  shrinking round timer so it's always *just* beatable; calibrating `humanMax`/`starThresholds`
  (28 / [10,18,26]) by playtest; confirming the 3-miss `endEarly` and a clean session re-entry.
- **U — UX:** Canvas-only, no raster assets · one ticker, one painter · a flashed prompt card with the
  word + how-to + a science fact · the active verb pinned small top-center while you play · a per-round
  timer bar that reddens as it drains · three life pips · green ✓ / red ✗ result flashes · WARP UP.
- **H — Heuristics (how you actually win):** commit to the verb the instant the card flashes — hesitation
  is the killer · keep your probe/scoop moving so you can react either way · on LAND, tap in short pulses
  rather than holding panic-taps · swipe circles, not lines, to SPIN fastest · on SORT, size is the tell
  (small + icy = dwarf) · leave headroom for the speed-up, don't burn lives early.
- **S — Systems (what makes the world feel alive):** the solar system as a **menagerie** — each
  microgame is the defining behavior of a different body, so the variety itself is the system. Asteroids
  spread thin, comet tails blown away from the Sun, a Moon you must rocket onto, a fast-spinning oblate
  giant, dwarf planets among the planets, tilt-driven seasons, and a Sun that erupts — each a true
  beat the player performs, not just reads.
