# POTATUHS — Dark Matter

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Dark Matter — the galactic-scale galaxy-binding game (reworked from "Star Collector").
  Self-contained module (`GalaxyCollectorGame` in `mini_games_batch3.dart`, spec'd in
  `lib/games/galactic/dark_matter/`); on `BioScale.galactic`, internal timer/results/restart.
- **O — Objectives:** post the highest score by holding the galaxy together — keep its visible stars in
  bound orbits across the round. Sub-goals: hit the Goldilocks balance so it neither disperses nor
  collapses, and hold a stable rotation curve through escalating chaos.
- **T — Tasks (the play to-do list):** watch which stars are drifting outward and escaping · drag to
  place / grow an **invisible dark-matter halo** where they're escaping · add gravity to pull them back ·
  trim mass when stars start spiraling in · re-center and re-balance after perturbations · keep the
  rotation curve flat.
- **A — Automations (firing in the background):** the internal round clock · per-frame orbital physics
  (stars orbiting the core at real-ish radii, visible gravity deliberately too weak) · the escape check
  that flings + loses outer stars · escalation drivers — star formation spawning more stars, spin
  speeding up, and **perturbations** (a passing galaxy tugging the halo off-center, a supernova shoving a
  region).
- **T — Testing (experimental / in-flight):** rework of the legacy tap-to-collect loop into the
  orbital-binding + dark-matter-placement loop; tuning the Goldilocks band (too little disperses / too
  much collapses), the invisible-halo feedback (effect-only, optional faint shimmer/lensing while
  placing), and the perturbation cadence.
- **U — UX:** Canvas-only — glowing orbiting stars, a bright core, escaping-star streaks · drag to place
  an **invisible** halo you see *only by its effect* (bent paths, then it goes invisible — true to life) ·
  HUD with a bound-stars count, a stability meter, and fact flares at beats.
- **H — Heuristics (how you actually win):** place mass *just* outside the stars that are escaping, not on
  the core · add gravity in small increments and watch the curve — over-massing collapses you · keep the
  rotation curve flat for the stability bonus · pre-empt perturbations by leaving headroom to re-balance ·
  fuller, stable galaxies score more per second, so save stars early.
- **S — Systems (what makes the world feel alive):** the galaxy *itself* is the living system — it
  constantly tries to fly apart, and you feel the unseen 85% holding it together · fact flares (galaxies
  spin too fast; dark matter never directly seen) teach the real mystery the mechanic embodies, with
  Milky Way / Galaxy Types / Stellar Recycling flavor cards.
