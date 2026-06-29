# POTATUHS — Bottleneck

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Bottleneck ("Keep the Line Moving") — the supply-chain **flow / Theory of
  Constraints** game. Self-contained module (`lib/games/supply_chain/bottleneck/bottleneck_game.dart`,
  `BottleneckGame`); on `BioScale.supplyChain`. Sits beside Delivery (routing/TSP) but teaches a
  different lesson — *flow*, not *route*.

- **O — Objectives:** ship the **most potatoes** out the end of a five-stage line (Farm → Wash →
  Process → Store → Ship) in 60 s (reported via `session.addScore` per shipped potato). Sub-goal: a
  long **smooth-flow streak** — consecutive shipments with zero overflow (`session.noteStreak`).

- **T — Tasks (the play to-do list):** read the line → find the bin that's **filling** (the
  `BOTTLENECK`) → **TAP it to BOOST** (×2.5 rate for ~1.3 s) → let it cool (~1.7 s) → re-read, because
  the slow stage **drifts**. Don't waste boosts on stages that are already keeping up, and don't let a
  bin overflow (rot).

- **A — Automations (firing in the background):** the host-owned 60 s clock (sim gates on
  `session.isRunning`) + a single-`Ticker` flow engine — per-frame inflow ramp into the Farm,
  snapshot-then-apply stage flows, overflow → waste clamping, drifting per-stage rates (each stage on
  its own sine), boost/cooldown timers, and a smoothed throughput EMA. Before the round, `_idleDrift`
  recycles product so the line looks alive during the ready/countdown state.

- **T — Testing (experimental / in-flight):** the flow engine is a clean snapshot→apply step, factored
  so demand and rates could later be **driven by other players** — the disruption seam for an online
  shared line where a rival could spike your demand or throttle one of your stages. Solo today.

- **U — UX:** a top **THROUGHPUT** meter (smoothed potatoes/sec, green when healthy), five station
  columns each with icon + name + live rate, a colour-coded **bin** (green ok → orange filling → red
  choke) with potatoes piling at the surface, a pulsing `BOTTLENECK` tag on chokes and `idle` on
  starved downstream stages, a tap/boost/cooldown footer pill per stage, a conveyor of drifting
  potatoes up top, and `+N` ship pops at the exit. All drawn in one canvas (perf-safe).

- **H — Heuristics (how you actually win):** **boost the bottleneck, never the fast stage** — a local
  win at a non-constraint is a global loss · watch for **starving** downstream bins, they point *up*
  the line to the real choke · spend cooldowns on the deepest pile first · keep product *moving* — an
  overflow both loses a potato and kills your streak · the bottleneck **moves**, so keep re-reading.

- **S — Systems (what makes the world feel alive):** a line that never stops — demand keeps ripening,
  rates keep drifting so the constraint wanders, and late-round double-chokes force triage with limited
  boosts. The tension is pure Theory of Constraints made physical: the slowest stage governs everything,
  and the player's whole job is to find it and feed it before it rots the harvest.
