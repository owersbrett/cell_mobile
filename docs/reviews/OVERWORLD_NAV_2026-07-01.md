# Overworld Navigation Evaluation — Party Board (3 maps)

**Date:** 2026-07-01 · **Method:** 3 Fable-model design evaluators, one per map (DOWN THE HOLE / INTO THE VOID / THROUGH THE AETHER), read-only. All three independently converged. Triggered by a real player: *"mid-game I couldn't pan to a part of the map — unplayable. How do I decide which items to use if I don't know where I'm going?"*

---

## THE ROOT-CAUSE BUG (all 3 agents, HIGH confidence)

`InteractiveViewer` at `party_page.dart:2016` **never sets `constrained: false`** → defaults to `true`. Its child `SizedBox` is drawn at `kCanvasSpread = 1.8`× the viewport (`:1979/:1988`, `Clip.none` at `:2025`), but `constrained: true` clamps the *laid-out* child back to viewport size. `InteractiveViewer` then computes its **pan boundary from the clamped child + `boundaryMargin: 240`** — so the reachable scene is only `viewport + 240px`, while tiles are positioned across the full 1.8× canvas (`_BoardGeometry.nodeCenter`).

**Consequence:** a dead band of `~0.8·viewportDim − 240px` per axis that **no drag can reach — at any zoom**. The unreachable band *grows with viewport*, so it's worst on tablet/desktop web (this ships to explore-the-cell.web.app). On **all three maps the board's end — the boss/anchor at order 87, i.e. the win target — sits inside that dead zone.** "Can't pan to a particular part" is literally true. Tap-to-inspect also silently dies out there (hit-testing stops at the clamped bounds).

**Compounding (all 3):** `_centerOn` (`:578-588`) writes `_boardTransform.value` **unclamped**, so late-game it frames a player inside the forbidden band; the first drag snaps the camera back into the legal region and "refuses to return" → the "fighting the camera" feel.

**Fix (map-agnostic, S):** `constrained: false` on the InteractiveViewer + clamp `_centerOn`'s output matrix to the same pan boundary. This one change unbricks pan, far-tile inspection, and the camera fight on **all three maps at once.**

---

## LIVE CRASH — fork chooser on GameMaps (DOWN THE HOLE, confirmed; VOID dodges it by having no forks)

`_pathOption` (`party_page.dart:1372-1394`):
1. `space.isShortcut` is **never set** by `_assembleSpaces` (game_map.dart) → both fork buttons render identically as *"STAY THE COURSE / The main path onward"* — the press-your-luck decision is two identical buttons.
2. `space.section.color` resolves via `kBoardSections[sectionIndex]` (`party_models.dart:303`) — a **6-entry legacy list**. DOWN THE HOLE has **8 sections**, so the fork at 58 (→ section 6) and checkpoint 66 throw a **RangeError rendering the choice panel.** That fork moment is itself an "unplayable" event.
3. `kBoardBranches.firstWhere` (`:1382`) would also throw if a GameMap space ever set `isShortcut`.

**Fix (S):** use `controller.sectionOf` (crash fix), gate the legacy `kBoardBranches` lookup on `controller.gameMap == null`, and label forks by order-delta: `next == order+1` → "PRESS ON (deeper)", `next > order+1` → "CUT-THROUGH — skip a band, risky", `next < order` → "BAIL UP — retreat". Show the destination tile's type + region.

---

## Shared legibility gaps (all 3 maps)

- **Region/section labels skipped for GameMaps** — watermarks render only `if (controller.gameMap == null)` (`:2029`). The station/band names (each map's whole cosmogony, and what determines which mini-game a tile fires) never appear on the board; you learn a region only by tapping tiles one at a time.
- **No direction arrows on xy-map links** — `_paintTopology` (`:2520`) draws arrows only on `jumpTo` edges; ordinary links are identical faint lines. Direction of travel is ambiguous (catastrophic on VOID's boustrophedon and DTH's spiral).
- **Camera never follows the token** — framed once on first layout (`_framed`, `:567`); tokens walk off-screen on any multi-step roll; the only recovery is an **undocumented double-tap** (`:690`) with zero on-screen affordance.
- **No spin/route preview** — at roll time you get "Move 5" but nothing highlights the reachable path or landing tile. On the two forkless maps (VOID, AETHER) item/ATP timing is the *only* strategic input — exactly the decisions the UI gives zero info for. This is the player's literal complaint.
- **Pan jank (DTH + AETHER)** — `_onZoom` (`:608`) `setState`s on *every* transform tick incl. pure pans, rebuilding 88 nodes + recomputing geometry; counter-scaling only depends on *scale*. Plus `_BoardPathPainter.shouldRepaint` compares only `geo.size` (`:2593`) → stale stroke widths after zoom.

---

## Per-map specifics

**DOWN THE HOLE (Archimedean spiral, 88 nodes, 3 forks + 3 bail-ups):** inner-band density is backwards vs importance — orders ~75+ sit ~9px apart in canvas coords but render ~30px, so GRAINS+FLOOR + the **anchor (the win target) collapse into an unreadable blob** at frame zoom. Forks invisible on-board. *Map-specific fix (M): arc-length-equalized spiral / radius floor so inner spacing ≥ node diameter.*

**INTO THE VOID (boustrophedon, 10 lanes × 8 rows, 4 ladders + 4 snakes, no forks):** direction ambiguity is worst here — adjacent lanes flow opposite. Snakes/ladders unplannable: **trigger nodes have no marker** (`_node` never reads `jumpTo`), endpoints off-screen, 8 straight diagonals overlap into spaghetti. Entry/exit stubs use 0.02 spacing → **orders 84-87 overlap into one blob** in the top-right, hiding the anchor. *Map-specific fixes (S): stub spacing 0.02→≥0.05; ▲/▼ badges on jump nodes + bowed jump curves.*

**THROUGH THE AETHER (linear switchback ribbon, 88 tiles, no forks, 3 auto-slides):** simplest and most legible locally. But the **rainbow slides are illegible** (a 2.5px line + one chevron, identical to VOID's ladders) and **teleport the token 12-16 tiles with no camera follow** — the most disorienting moment on the map. Forkless → look-ahead tooling matters *more*, not less. *Map-specific: dashed rainbow-gradient slide styling + pan-and-hold when a slide fires; consider flipping y so the "ascent" travels upward.*

---

## Consolidated build plan (priority order)

| P | Fix | Effort | Scope | Solves |
|---|-----|--------|-------|--------|
| **0** | `constrained: false` + clamp `_centerOn` to boundary | **S** | agnostic | THE unplayable bug, every map/viewport |
| **0** | Fork chooser repair (crash fix + `sectionOf` + real order-delta labels + gate `kBoardBranches` on legacy) | **S** | agnostic mech | DTH RangeError + identical-button forks |
| **1** | Spin/roll-reach preview (highlight reachable path + landing tile; glow fork edges; resolve jumps) | **M** | agnostic | "which item do I use" |
| **1** | Follow-cam during movement + visible snap-to-me button (replaces secret double-tap) | **S/M** | agnostic | token off-screen, post-mini-game disorientation |
| **2** | `_onZoom` rebuild-only-on-scale-change + `shouldRepaint` includes `viewScale` | **S** | agnostic | pan jank/freeze, stale strokes |
| **2** | Region labels + direction chevrons for GameMap boards | **S** | agnostic | invisible geography + direction ambiguity |
| **3** | Jump-node markers + bowed jump curves; slide styling + pan-on-fire | **S/M** | agnostic | snakes/ladders/slides illegible |
| **3** | Spiral de-congest (DTH); stub spacing (VOID); y-flip (AETHER) | **S/M** | per-map | endgame blobs |
| **4** | Corner minimap (dots + player/op + viewport rect, tap-to-jump) | **M/L** | agnostic | global orientation — *may be unnecessary after P0-P2* |

**All three agents' independent "fix only three things" collapsed to the same set: P0 (constrained + fork crash), spin preview, follow-cam + snap button.** Minimap deliberately deferred — with the pan fix + a progress/label layer it's likely redundant on these order-linear maps.

**Note:** everything P0-P2 lives in the single file `party_page.dart` (+ tiny touches to `game_map.dart` for per-map geometry) — do as ONE serial pass, not parallel agents, to avoid collisions.
