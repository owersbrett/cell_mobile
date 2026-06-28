# POTATUHS — Corners

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Corners — the somethings-scale shape-reading game. Registry game on
  `BioScale.somethings` (`CornersGame`, `lib/games/arcade/corners.dart`); tap each shape exactly as
  many times as it has corners — flat polygons first, then 3D platonic solids.
- **O — Objectives:** post the highest score in the timed round. Sub-goals: match each shape's corner
  count exactly for the gold burst; resolve as many shapes as you can as they spawn faster; read the
  3D solids' vertices once they drift in.
- **T — Tasks (the play to-do list):** spot a spinning outlined shape with a draining life-ring · tap
  it once to claim it (extends life) · tap it exactly its corner count, then **stop** · let the
  life-ring empty to lock in and score · after ~40% in, count **vertices** on the rotating 3D solids
  that drift in.
- **A — Automations (firing in the background):** the continuous shape **spawner** (concurrency 1→5,
  interval 1.05→0.34 s) · each shape's **draining life-ring** (untouched lifetime 2.4→~1.0 s; claim
  +~1.5 s, each tap +~0.45 s, cap ~2.2 s) · the per-frame tick driving spin, corner-dot glows, drain
  rings, sparks · auto-scoring when a ring empties · the host clock / countdown / results and AI
  opponents from MiniGameHost.
- **T — Testing (experimental / in-flight):** consolidate Explore onto Corners — legacy `ThoughtCatcher`
  is what Explore routes to for somethings today (see AGENT.md) · the 3D-solids escalation (solids at
  40%, dodecahedra only after 60%) is the difficulty seam · optional end-game cameo still open: a
  **potato** drifts in as the no-clean-corners anti-platonic foil.
- **U — UX:** tap the nearest unresolved shape within radius · canvas-drawn 2D polygons + orthographically
  projected 3D wireframe solids · corner-dot glows that read the shape's structure · drain rings showing
  remaining life · 16-particle gold/orange burst + "EXACT +N" on a perfect match. No raster assets.
- **H — Heuristics (how you actually win):** claim a shape with the first tap to buy time, then count
  deliberately — exact match pays `corners × 5` vs falloff `~34%` per unit of miss · prioritize
  low-corner shapes when the field is crowded (fast, safe points) · learn the solids' vertex counts
  (tetra 4, octa 6, cube 8, icosa 12, dodeca 20) so 3D shapes aren't guesses.
- **S — Systems (what makes the world feel alive):** the "birth of form" theme — somethings is the first
  thing with an edge, and counting corners is how you read a shape · the ladder of form, flat polygons →
  perfect platonic solids, taught by their corner/vertex counts (names shown on resolve) · the rising
  pressure of more shapes spawning faster as the round heats up.
