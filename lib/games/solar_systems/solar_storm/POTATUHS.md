# POTATUHS — Solar Storm

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Solar Storm — the solar-systems-scale space-weather game (`SolarStormGame` in
  `solar_systems/solar_storm/solar_storm_game.dart`). Manage an active Sun: quell building sunspots and
  deflect the flares / CMEs they launch at Earth's satellites and power grid across one 60s solar cycle.

- **O — Objectives:** post the highest score before time runs out. Sub-goals: quell sunspots **early**
  (before they erupt) for the size bonus; deflect every storm **high** for the clean-defense bonus; keep a
  streak alive through solar maximum (×4 combo); never let the grid take a hit.

- **T — Tasks (the play to-do list):** watch the roiling Sun for sunspots · tap a sunspot while its rim is
  still dim · spot the storm that just launched · tap an incoming CME / flare high up to raise shields ·
  triage simultaneous threats near solar maximum (urgent fast flares first) · protect the satellite belt.

- **A — Automations (firing in the background):** the solar-cycle ramp interpolating every spawn rate and
  speed from minimum → maximum · sunspot growth → eruption → CME launch · direct-flare spawner that ramps
  in late · the early-quell / early-deflect bonus math · the combo multiplier off the success streak · grid
  self-repair · the host clock, countdown, score HUD, results, best-streak award, and AI opponents.

- **T — Testing (experimental / in-flight):** `humanMax 850`, stars `[300, 550, 800]` — re-tune by playtest ·
  cycle-ramp constants (spawn/growth/speed) live at the top of the file for quick tuning · grid is currently
  visual + point cost with no early-end fail state (deliberately a score-attack); a hard fail state is an
  open option.

- **U — UX:** one tap verb everywhere (tap sunspots, tap incoming storms) for clean mobile play · building
  sunspots brighten and pulse so the "act now" window is legible · storms trail back to the Sun and draw a
  red aim line as they near the belt · left meter = solar cycle, right meter = grid integrity · a calm
  "SOLAR MINIMUM" ready state with a one-line how-to before the host starts the clock.

- **H — Heuristics (how you actually win):** prevention beats defense — quelling a sunspot early is cheaper
  than deflecting the CME it would launch · catch storms high, never at the belt · fast flares are more urgent
  than slow CMEs, tap them first · guard the streak: one belt hit wipes your ×4 multiplier · don't panic at
  solar maximum, triage by urgency.

- **S — Systems (what makes the world feel alive):** the magnetic Sun IS the system — convective granulation,
  sunspots as knotted field, flares as light-speed bursts vs CMEs as slow plasma, all ramped by an 11-year
  cycle compressed to 60s · the lesson is the mechanic: you feel why early forecasting matters because you're
  literally racing the warning window to shield satellites and the grid.
