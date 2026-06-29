# POTATUHS — Pollination Dash

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Pollination Dash — the farmSystem-scale **bee-steering** game. Drag a bee around
  a meadow to carry pollen flower-to-flower and set fruit (little potatoes). Self-contained module
  at `lib/games/farm_system/pollination/`; framework deps only (`mini_game.dart`, `fx.dart`,
  `theme/potatuhs.dart`).
- **O — Objectives:** set the most **fruit** (highest score) in the 60 s round. Sub-goals: load
  pollen from one bloom, pollinate **other same-species blooms before they wilt**, chain quick
  flower-to-flower visits for a **combo**, and survive pesticide clouds and wind gusts.
- **T — Tasks (the play to-do list):** steer toward a flower → pick up its pollen · sweep to other
  same-color flowers to pollinate them · keep the **chain-life bar** alive by moving fast · switch
  pollen by touching a new species · dodge drifting pesticide clouds · ride out wind gusts.
- **A — Automations (firing in the background):** one **Ticker** advancing every flower's lifecycle
  (seed → bud → bloom → fruit/wilt → regrow), the bee's **seek-the-finger** steering, drifting
  **pesticide clouds**, periodic **wind gusts**, particle/score-pop FX · difficulty derived from
  the host clock (more flowers, more species, faster wilt, more hazards) · MiniGameHost's host-owned
  clock, 3-2-1 countdown and results.
- **T — Testing (experimental / in-flight):** `flutter analyze` clean. First-pass calibration
  (`humanMax 2000`, stars `[500, 1000, 1600]`, wilt window `7.5 → 3.4 s`) needs a playtest pass.
  Steering feel and hazard frequency are the main dials to tune. Session re-entry verified by
  design — stateless per run, calm ready state, auto-start on `isRunning`.
- **U — UX:** a living **meadow** on a green atmosphere · flowers in distinct species colors with a
  draining **wilt ring** so time pressure reads at a glance · a fuzzy striped **bee** with flapping
  wings that follows your finger and glows in its carried-pollen color · **potatoes** popping out as
  fruit sets · a top-left **pollen chip** and a top-center **combo meter**. Canvas-drawn only.
- **H — Heuristics (how you actually win):** load pollen, then **work one color patch at a time** to
  bank a long chain · keep moving — chains die if you dawdle, and you can't score by camping one
  flower · pollinate the **most-wilted** blooms first · steer **around** pesticide clouds, never
  through them (a hit dumps your pollen and breaks the combo) · let go to hover when you need to read
  the field.
- **S — Systems (what makes the world feel alive):** the **pollinator loop** — pollen only counts
  when carried *between* two flowers of the same kind, the literal biology made into the score rule ·
  blooms that wilt and regrow so the meadow is never static · pesticide and wind as the real-world
  threats to bees · the payoff beat — every successful cross sets a **potato**, the farmSystem
  scale's "this is where food comes from" moment.
