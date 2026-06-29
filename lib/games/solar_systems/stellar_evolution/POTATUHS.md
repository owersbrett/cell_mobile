# POTATUHS — Stellar Evolution

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Stellar Evolution — the solar-systems-scale star-life-cycle game
  (`StellarEvolutionGame`, `lib/games/solar_systems/stellar_evolution/`). Guide ONE star from a gas
  cloud to its grave, one quick action per phase, where the star's **mass branches the path**.
- **O — Objectives:** post the highest score in 60s by running as many star lives as possible and
  clearing each phase fast and clean. Sub-goals: nail the timed ignitions, hold the main-sequence
  balance, and reach the **dramatic endpoints** (supernova → neutron star / black hole) that pay big.
- **T — Tasks (the play to-do list):** mash to collapse the nebula (and accrete mass) · time the
  protostar ignition tap · tap to balance gravity vs fusion on the main sequence · mash to swell the
  giant · low mass: puff off the planetary-nebula shells → white dwarf · high mass: time the
  supernova → neutron star or black hole · then do it again with the next star.
- **A — Automations (firing in the background):** the `_Phase` state machine + mass-branch router ·
  per-phase timers, speed bonus and timing-accuracy bonus · the clean-clear combo feeding
  `session.noteStreak` · the difficulty ramp that tightens windows and timers each star life · the
  single-ticker sim+paint loop, all gated on the host's `session.isRunning`.
- **T — Testing (experimental / in-flight):** new build 2026-06-28 · `flutter analyze` clean ·
  calibration `humanMax 900` / thresholds `[300,600,900]` seeded, re-tune from real plays · open
  idea: a potato/star-stuff flare on each endpoint.
- **U — UX:** one star on screen, a clear text prompt per phase, and a single action surface (tap
  anywhere). The **mass → destiny** readout at the top telegraphs the fork before it happens. A calm
  idle star greets the player before the host starts the clock. Canvas-only, neon-on-ink.
- **H — Heuristics (how you actually win):** clear fast for the speed bonus, keep the combo alive
  (a 5+ streak doubles the endpoint payoff) · chase mass — accrete hard in the nebula to push a
  borderline star over 8 M☉ and onto the high-paying supernova branch · on the main sequence, tap in
  rhythm, don't spam (over-pushing destabilises as surely as gravity does).
- **S — Systems (what makes it feel alive):** the lesson IS the system — the balance mini-game is
  hydrostatic equilibrium, the fork is the mass-destiny law, the supernova is the violent death of a
  massive star. Pulsar beams, accretion disks and shed shells render the real physics; every star
  you detonate scatters the star-stuff that potatoes (and people) are made of.
