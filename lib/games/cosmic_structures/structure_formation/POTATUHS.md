# POTATUHS — Structure Formation

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Structure Formation — the cosmic-structures-scale cultivation blitz. Self-contained
  module (`lib/games/cosmic_structures/structure_formation/structure_formation_game.dart`,
  `StructureFormationGame`); on `BioScale.cosmicStructures`, host-driven, 60s.

- **O — Objectives:** post the highest score by collapsing the most **mass into structure** and growing
  the richest **cosmic web** before time runs out. Sub-goals: many well-formed nodes (not one blob),
  filaments linking them, structure that survives the late dark-energy surge.

- **T — Tasks (the play to-do list):** tap to seed tiny density fluctuations · spread seeds across the
  field (gravity already concentrates — don't over-seed one spot) · don't starve a region · seed early
  so gravity has time to amplify · build clumps dense enough to keep collapsing as expansion ramps.

- **A — Automations (firing in the background):** the host-owned intro / countdown / results clock
  (play begins on `isRunning`) · the single per-frame ticker driving the density-field physics
  (mass-conserving accretion + expansion), seed-budget regen, particle bursts, and the canvas repaint ·
  rising-edge mass scoring with hysteresis · throttled flood-fill cluster scoring on a new-high node
  count · the dark-energy surge in the final seconds.

- **T — Testing (the gates):** `flutter analyze` on the folder = zero issues · a 60s session completes
  and **Play Again** re-enters a fresh smooth universe (the S) · scoring stays honest (no re-scoring a
  flickering cell; no farming clusters by tear/re-form) · performance: one ticker → one painter, typed
  arrays, no per-cell blur, NaN-guarded — no black frames.

- **U — UX:** calm ready state (a near-smooth field + "tap to seed" hint) → on countdown the universe
  comes alive · tap **anywhere** to seed · seed-budget dots up top, clear of the host quit/disruption
  chrome · colour ramp blue→violet→orange→white-hot reads sheets→filaments→collapse→cluster cores ·
  dark-energy warning badge late · a fixed education banner refreshing as nodes form.

- **H — Heuristics (how you actually win):** distribute fluctuations to grow a *web* of nodes, not a
  single lump · plant early — late seeds barely collapse before dark energy undoes them · feed regions
  enough to cross the collapse threshold but don't waste seeds piling onto an already-dense knot ·
  watch the expansion ramp and front-load your seeding.

- **S — Systems (what makes the world feel alive):** the density field is a real gravitational-
  instability simulation — seeds genuinely grow, merge, and weave filaments, while expansion dilutes
  and dark energy tears. The mechanic *is* the science: tiny CMB-scale ripples amplified by gravity
  into the cosmic web, racing the expanding universe.
