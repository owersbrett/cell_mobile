# GAME.md — Corners

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** somethings
- **Game id:** corners
- **One-line concept:** Count the corners. Tap each shape exactly as many times as it has
  corners — flat polygons first, then the perfect 3D solids.
- **Role:** solo high-score
- **Six-in-one?** no

## Lore (geometry = the first form)
Somethings is the birth of **form** — the first thing with an **edge**. A corner is the smallest
unit of form: where two edges turn. Counting corners is how you "read" a shape. The game walks the
ladder of form: flat polygons (2D) → platonic solids (3D), the perfect forms defined purely by how
many corners (vertices) they have.

## Rules (canonical — as implemented in `CornersGame`)
1. Outlined shapes appear, spinning, with a draining life-ring.
2. **Tap a shape exactly as many times as it has corners**, then **stop**.
3. Your **first tap claims** the shape (extends its life ~1.5 s); each further tap adds ~0.45 s
   (capped ~2.2 s) so a claimed shape lasts long enough to finish.
4. When the life-ring empties, your tap count is compared to the true corner count to score.
5. After ~40% into the round, **rotating 3D platonic solids** drift in — count their **vertices**.
6. **Closer counts score more; an exact match scores most.**

## Controls
Tap (nearest unresolved shape within radius). Canvas-drawn only — 2D polygons and orthographically
projected 3D wireframe solids, corner-dot glows, drain rings, spark bursts. No raster assets.

## Scoring
- **Exact match:** `corners × 5`.
- Off by 1+: `corners × 4`, reduced ~34% per unit of miss (floor 0).
- Never-claimed shapes: 0, no penalty.
- Exact hit → 16-particle gold/orange burst + "EXACT +N".

## Win / end condition
Timed score attack — shapes resolve continuously until the round timer expires. Most points wins.

## Difficulty curve
Concurrent shapes **1 → 5**; spawn interval **1.05 → 0.34 s**; untouched lifetime **2.4 → ~1.0 s**.
3D solids begin at **40%** progress; dodecahedra only after **60%**.
True vertex counts taught: triangle 3, square 4, pentagon 5, hexagon 6; **tetrahedron 4,
octahedron 6, cube 8, icosahedron 12, dodecahedron 20**.

## Educational blocks engaged
- **The Angle / Corner:** ✅ corner-counting is the whole mechanic.
- **Polygons:** ✅ flat forms by corner count.
- **Platonic Solids:** ✅ the perfect solids by vertex count (with names shown on resolve).
- **The Point / The Line:** ⚠️ implicit (edges = lines meeting at corners = points).

## Potato angle
End-game cameo idea: a **potato** drifts in — the anti-platonic solid with *no clean corners* —
as a playful "count that!" foil to the perfect forms. (Optional; don't force.)

## Session / resume
Persist score, elapsed time, current shape field + claim/tap state.

## Implementation
- Current: `lib/games/arcade/corners.dart` (`CornersGame`) — registry game, already on
  `BioScale.somethings`. Matches this spec. Also legacy `ThoughtCatcher` is what Explore routes to
  for somethings today; consolidate Explore onto Corners (see AGENT.md).
