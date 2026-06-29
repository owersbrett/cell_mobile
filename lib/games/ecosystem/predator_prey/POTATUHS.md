# POTATUHS — Predator & Prey

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Predator & Prey — the ecosystem-scale population-balance game. Module at
  `lib/games/ecosystem/predator_prey/predator_prey_game.dart` (`PredatorPreyGame`); registry game on
  `BioScale.ecosystem`.
- **O — Objectives:** post the highest survival-in-balance score by keeping a live Lotka–Volterra web
  off zero for the whole round. Sub-goals: hold a long balance STREAK (consecutive seconds both
  species sit near equilibrium); survive every shock; keep all THREE tiers alive once hawks arrive.
- **T — Tasks (the play to-do list):** read the phase label and graph to see which way the cycle is
  turning · release hares when prey crashes · cull or release lynx to relieve/restore predation ·
  PROTECT a patch to give hares a refuge · pre-empt shocks instead of reacting late.
- **A — Automations (firing in the background):** the per-tick ODE integrator (4 Euler substeps) ·
  the difficulty ramp (`speed = 1+1.3·frac`, `βEff = β·(1+0.5·frac)`) · the shock scheduler
  (drought/disease/bloom/hawk-swarm on a `13−6·frac` cadence) · the hawk introduction at 55% · the
  extinction watchdog that reseeds a wiped species at a −40 penalty · the continuous score accumulator.
- **T — Testing (experimental / in-flight):** the **drawn balance band** is the primary polish TODO
  (equilibria are computed for scoring but the healthy window isn't shaded on the graph) · hawks
  vanish silently when lynx collapse (wants a callout) · no in-session restart (host owns it).
- **U — UX:** a calm ready state (two flat lines + a plain-language hint) · one `CustomPainter`
  scrolling two/three-line graph with K line, extinction floor, phase label and live legend counters
  · two species panels (big −/+ cull/release keys) + a full-width PROTECT button with cooldown state
  · shock flashes and rising `FxPop`s for every intervention. One ticker, no per-frame setState.
- **H — Heuristics (how you actually win):** damp the oscillation, don't chase it — adding the species
  that's low often overshoots a cycle later · predators peak AFTER prey, so cull lynx *before* the
  hare crash, not during · respect carrying capacity (a hare bloom against K sets up the next crash) ·
  spend PROTECT on a real prey crisis, not idly · once hawks exist, you can't optimise one tier alone.
- **S — Systems (what makes the world feel alive):** the coupled boom-bust cycle that turns on its own
  · the carrying-capacity ceiling hares grow toward · the three-tier trophic cascade (hawks→lynx→hares)
  · the accelerating shock economy · the potato-field tie — balanced predator/prey dynamics ARE
  integrated pest management, the instinct that keeps a real crop productive.
