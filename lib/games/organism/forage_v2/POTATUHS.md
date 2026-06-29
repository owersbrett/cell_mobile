# POTATUHS — Forage v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Forage v2 — the UX-refinement sibling of the organism-scale energy-economy game.
  Self-contained module (`lib/games/organism/forage_v2/`, widget `ForageV2Game`); registers on
  `BioScale.organism` and mounts in MiniGameHost. **Status: BUILT.** v2 is a light-touch lift over the
  cohort reference build — soul preserved, the one named gap (invisible cost ledger) closed.
- **O — Objectives:** bank the most energy over a 50-second run by keeping the energy meter high without
  starving. Sub-goals: eat **efficiently** (food value > travel cost) to build a streak, **rest** between
  meals to keep the next bite cheap, and stay above the thrive line (70) for passive points. v2 adds the
  objective made *legible*: keep the COST SINCE MEAL bar under break-even before each bite.
- **T — Tasks (the play to-do list):** drag to steer → read the shrinking food halos to pick a still-
  efficient orb → graze nearby first → watch the cost tether redden as a warning → rest (stop moving) when
  the bar is climbing → skirt predator fear-rings → keep the meter off zero → recover fast after a collapse.
- **A — Automations (firing in the background):** the three drains (movement cost, ramping basal
  hunger/cold, predator fear + bite) · the per-meal efficiency check that grades the streak · food
  scarcity + respawn-delay ramps · the predator count/speed/homing ramp · the thrive trickle above 70 ·
  the v2 ledger render layer (cost tether, value-halos, COST-SINCE-MEAL bar, burn flecks, streak flourish)
  driven purely off existing state · particle/pop FX · the MiniGameHost session clock + intro/countdown/
  results + `_resetRun` on a fresh session.
- **T — Testing (in-flight knobs):** the `forage` tunables (`_kMoveCost`, `_kBasal*`, `_kFoodValue*`,
  `_kFoodCount*`, `_kFoodRespawn*`, `_kPred*`, `_kStarvePenalty`, `_kThriveThreshold`) are unchanged and
  exposed; v2 adds `_kLedgerRef`, `_kStreakFlourish`, `_kFleckSpeed`, `_kFleckEvery`. The load-bearing
  invariant — **movement costs energy, resting stays viable, and the visible ledger never diverges from
  the scoring** — is fixed. `humanMax 600` / stars `[200,400,600]` (registry spec) carry over.
- **U — UX:** a dark ink field with a drifting cold vignette, gold food orbs (size hints value) now ringed
  by **net-value halos** that shrink as you travel, red predators with faint fear zones, and an animal
  whose color shifts green→gold→red with its energy. A **cost tether** trails from the last meal; **burn
  flecks** shed off a sprinting animal; the **energy meter** sits across the top with a thrive marker and a
  **COST SINCE MEAL** ledger bar beneath it; a chained-efficient run blooms a screen-edge **EFFICIENT ×N**
  flourish. Calm "DRAG TO FORAGE" ready state; "STARVED — RECOVERING" overlay on collapse. Canvas-only
  `CustomPainter`, one ticker, capped particles.
- **H — Heuristics (how you actually win):** net energy is the whole game — read the halos, graze the orb
  that's still green, and rest between meals so every bite lands EFFICIENT · don't sprint across the map
  for one orb (the tether will turn red telling you so) · treat predators as an energy tax · live above the
  thrive line for free points · a steady eat-rest rhythm beats panic chasing — and now you can *see* the
  rhythm in the ledger.
- **S — Systems (what makes the world feel alive):** the forager framed as an animal on a metabolic
  budget; optimal-foraging theory dramatised as a live, *predictive* verdict — shrinking value-halos and a
  cost bar that say "this orb is no longer worth it" *before* you chase; basal metabolism + thermoregulation
  as the rising cold drain; predation-risk-vs-feeding as the fear ring; the potato hook — a tuber-critter
  digging up buried spuds, a sprouting potato burning its own starch reserve against the clock.
