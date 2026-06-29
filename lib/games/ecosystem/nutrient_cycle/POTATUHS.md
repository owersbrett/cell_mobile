# POTATUHS — Nutrient Cycle

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Nutrient Cycle ("Route the Matter Round the Loop") — the ecosystem-scale
  **biogeochemical cycling** game. Self-contained module
  (`lib/games/ecosystem/nutrient_cycle/nutrient_cycle_game.dart`, `NutrientCycleGame`); on
  `BioScale.ecosystem`. Its VERB is **CYCLE-ROUTE** — a closed loop, the deliberate counterpart to
  Bottleneck's one-way *flow* line and Delivery's one-way *route*.

- **O — Objectives:** cycle the **most matter** in 50 s — `session.addScore(1)` per valid transfer of
  the atom between reservoirs, plus a `+5` bonus each time a **full loop closes** (the atom returns to
  where it began). Sub-goal: a long **flow streak** of consecutive valid transfers
  (`session.noteStreak`).

- **T — Tasks (the play to-do list):** read the cycle map → from the current reservoir, find a pool the
  atom can legally travel to (a named **process** edge — photosynthesis, respiration, fixation, …) →
  **TAP it** → repeat all the way round to close the loop → then read the NEW element when the cycle
  switches (carbon → water → nitrogen). Don't tap pools with no process from here (dead end), and don't
  stop moving (the flow drains).

- **A — Automations (firing in the background):** the host-owned 50 s clock (scoring gates on
  `session.isRunning`) + a single-`Ticker` engine — the flow meter draining (faster as the round
  progresses), per-frame atom-slide interpolation along edges, loop-closure detection, the
  every-two-loops element switch, and a calm `_autoStep` preview that auto-routes the loop before the
  round starts.

- **T — Testing (experimental / in-flight):** the cycle is pure data (`_Cycle` = reservoirs + directed
  process edges), so new elements (phosphorus, oxygen, sulphur) or **mixed-element rings** drop in
  without touching the engine — the disruption seam for an online mode where a rival could sever one of
  your process edges or spike your flow drain. Solo today; whole-element rotation stands in for the
  brief's "pick a cycle."

- **U — UX:** a ring of reservoir orbs (icon + name + sub-pool), the full cycle drawn as faint
  process-named edges with the **current node's options brightened and labelled**, a soft pulse on
  reachable pools, the travelling atom carrying the element symbol, a top **FLOW** meter ("energy
  dissipates — keep matter moving"), a `ELEMENT CYCLE` header with "matter cycles · energy flows", and a
  `LOOPS` / flow-streak readout. All drawn in one canvas (perf-safe; `motes: 24`).

- **H — Heuristics (how you actually win):** **keep moving** — a settled atom bleeds flow toward a stall
  · read the **process labels**, not just the pulse, so a faster cycle map doesn't catch you out · aim
  to **close loops** (the +5 is most of the score) rather than wandering branches · when the element
  switches, re-orient to the new ring fast — the clock and drain don't pause.

- **S — Systems (what makes the world feel alive):** a world that literally never stops recycling —
  matter goes round forever while energy pours one way and dissipates. The tension is the second law of
  thermodynamics made physical: the atom is conserved, but you must keep feeding the cycle energy
  (moves) or it grinds to a halt. Carbon, water, and nitrogen are the actual stuff a potato is built
  from, pulled out of air, soil, and rain — so routing the cycle is routing the potato's own matter.
