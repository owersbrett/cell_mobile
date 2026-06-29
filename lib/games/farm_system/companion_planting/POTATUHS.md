# POTATUHS — Companion Planting

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives,
> Tasks, Automations, Testing, UX, Heuristics, and Systems. One profile per game.

- **P — Project:** Companion Planting — the farmSystem-scale garden-grid adjacency puzzle.
  Game id `companion_planting` on `BioScale.farmSystem`; the "arrange the bed so neighbours
  help, not hurt" placement game.
- **O — Objectives:** score by planting each crop tile next to its allies and never its
  antagonists, then harvest flawless (foe-free) plots for the big bonus. Sub-goal: keep a
  clean-placement combo alive for the escalating multiplier.
- **T — Tasks (the play to-do list):** read the hand in the tray · drag a tile onto an empty
  cell · watch the predictive green/red cell tint · land friendly adjacencies (corn+beans,
  marigold+tomato) · keep fennel and nightshade clusters apart · fill the whole plot before
  the growth phase.
- **A — Automations (firing in the background):** the tray auto-refills until the plot is
  full · the growth phase auto-tallies each plant's net neighbours and thrives/wilts it · the
  level auto-climbs every harvest, growing the plot (3×3 → 5×5) and widening the crop palette ·
  early plots auto-restrict to friend/neutral crops, foes phasing in by tier.
- **T — Testing (experimental / in-flight):** weighted-deck dealing (guarantee a solvable
  foe-free arrangement exists) and a toggleable relationship legend — both noted in AGENT.md
  as low-priority ideas, not yet built. A pollinator crop (buffs every neighbour) is a
  candidate fifth mechanism.
- **U — UX:** `CustomPainter` soil beds · shaded `GameFx.orb` crops with 2-letter badges ·
  green/red relationship beams flashing between new neighbours · "+helps/−hurts" pop cues ·
  a predictive cell tint while dragging · thriving plants that swell and glow, wilting plants
  that shrink and brown.
- **H — Heuristics (how you actually win):** build the Three Sisters trio first — it's all
  mutual friends · plant the saboteurs (fennel) and nightshade pairs in opposite corners ·
  never break a clean combo for a marginal tile · chase the flawless-plot bonus on small
  early beds where a perfect layout is easy.
- **S — Systems (what makes the world feel alive):** a garden bed as a tiny ecosystem where
  every plant reacts to who's beside it · real companion-planting biology (nitrogen fixing,
  pest repulsion, Three Sisters support, allelopathy) encoded as the adjacency matrix · a
  ramp that turns a gentle 3×3 of allies into a dense 5×5 web where one careless fennel can
  wilt half the plot.
