# POTATUHS — Forage

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Forage — the organism-scale energy-economy game. Self-contained module
  (`lib/games/organism/forage/`, widget `ForageGame`); registers on `BioScale.organism` and mounts in
  MiniGameHost. **Status: BUILT.**
- **O — Objectives:** bank the most energy over a 50-second run by keeping the energy meter high without
  starving. Sub-goals: eat **efficiently** (food value > travel cost) to build a streak, **rest** between
  meals to keep the next bite cheap, and stay above the thrive line (70) to earn passive points.
- **T — Tasks (the play to-do list):** drag to steer the animal → graze nearby food first → read whether
  each meal lands EFFICIENT or inefficient → rest (stop moving) when the basal drain is the only cost →
  skirt predator fear-rings → keep the meter off zero → recover fast after a starve-collapse.
- **A — Automations (firing in the background):** the three drains (movement cost, ramping basal
  hunger/cold, predator fear + bite) · the per-meal efficiency check that grades the streak · food
  scarcity + respawn-delay ramps · the predator count/speed/homing ramp · the thrive trickle above 70 ·
  particle/pop FX · the MiniGameHost session clock + intro/countdown/results + `_resetRun` on a fresh session.
- **T — Testing (in-flight knobs):** tunables `_kMoveCost`, `_kBasalStart/End`, `_kFoodValue*`,
  `_kFoodCount*`, `_kFoodRespawn*`, `_kPred*`, `_kStarvePenalty`, `_kThriveThreshold` are exposed for
  playtest tuning. The load-bearing invariant — **movement costs energy and resting must stay viable** —
  is fixed and must not be tuned away. `humanMax 600` / stars `[200,400,600]` (registry spec) are
  first-pass estimates to sharpen by real plays.
- **U — UX:** a dark ink field with a drifting cold vignette, gold food orbs (size hints value), red
  predators ringed by a faint fear zone, and an animal whose color shifts green→gold→red with its energy.
  The **energy meter** sits across the top with a thrive marker and a low-energy danger pulse. A calm
  "DRAG TO FORAGE" ready state precedes the run; a "STARVED — RECOVERING" overlay on collapse. Canvas-only
  `CustomPainter`, one ticker, capped particles.
- **H — Heuristics (how you actually win):** net energy is the whole game — graze **nearby** food and
  **rest** between meals so every bite lands EFFICIENT · don't sprint across the map for one orb · treat
  predators as an energy tax, not just a threat — give the red rings a wide berth · live above the thrive
  line for free points · a steady eat-rest rhythm beats panic chasing.
- **S — Systems (what makes the world feel alive):** the forager framed as an animal on a metabolic
  budget; optimal-foraging theory dramatised as a live EFFICIENT/inefficient verdict on every meal;
  basal metabolism + thermoregulation as the rising cold drain; predation-risk-vs-feeding as the fear
  ring; the potato hook — a tuber-critter digging up buried spuds, and a sprouting potato burning its own
  starch reserve against the clock before it reaches light.
