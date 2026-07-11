# Board Render Recon — how the party board is actually drawn

> Read-only reconnaissance for the "breathe life into the boards" overhaul, starting with
> Down the Hole. Every claim carries a file/symbol anchor. Line numbers are as of
> 2026-07-10 on `feature/online` (same session that landed the 7.2× canvas spread,
> equal-arc spacing, and zoom buttons — this report describes the post-change state).

## 1. Rendering stack

**Plain Flutter, no engine.** `pubspec.yaml` has no Flame, Rive, Lottie, or any game/
animation engine — deps are firebase, bloc, sensors_plus, url_launcher, shared_preferences.
The board is a widget `Stack` with two `CustomPainter`s:

- **`_BoardView`** (`lib/party/screens/party_page.dart:2501`) — a `StatelessWidget` that
  builds the whole board scene inside an `InteractiveViewer` (`:2588`).
- The board world is a `SizedBox` of `viewport × kCanvasSpread` (**7.2×**, `:2545`);
  positions are `Positioned` widgets and canvas draws in that world space.
- **Pan/zoom:** stock `InteractiveViewer` with `constrained: false`,
  `minScale: kMinZoom = 1/7.2 ≈ 0.139`, `maxScale: kMaxZoom = 5.0` (`:2550`),
  `boundaryMargin: 240`. The transform lives in a `TransformationController` owned by
  `_BoardScreenState` (`_boardTransform`, `:780`) so it survives per-step rebuilds.
- **Programmatic camera:** every scripted move goes through `_driveCamera(focus, zoom)`
  (`:859`) which writes a clamped `Matrix4` — used by `_centerOn` (`:832`, re-frame /
  walk tracking at `_frameZoom = 1.45`) and `_zoomBy` (`:841`, the +/− buttons, 1.5×
  steps, animated via a 230 ms `Matrix4Tween` on `_camCtrl`).
- **The counter-scale trick (load-bearing):** node/link/token sizes divide by the live
  zoom (`nodeRadius = base / viewScale`, `_BoardGeometry:3056`; strokes `3 / z` etc.), so
  zooming spreads the LAYOUT while everything stays constant size on screen. `_onZoom`
  (`:901`) rebuilds the whole board subtree on every *scale* change (gated to ±0.001) —
  pans don't rebuild, zooms do.

**Existing animation infrastructure in the board layer** (all standard Flutter, no shaders
beyond one `MaskFilter.blur` on the legacy ring `:3179`):

| What | Mechanism | Where |
|---|---|---|
| Camera glide | `AnimationController` `_camCtrl` (230 ms) + `Matrix4Tween` | `:882` region |
| Token slide | `AnimatedPositioned` (230 ms, easeInOut) per token | `_tokens:2957` |
| Dice tumble | `AnimationController` `_diceCtrl` (720 ms) + `_DiePainter:2152` | `:772` |
| Landing "+5 💎" pop | `TweenAnimationBuilder` one-shot (1100 ms) | `_landingPop:2662` |
| Op/ghost drift | `AnimatedPositioned` (600 ms) | `_opToken:2732`, `_ghostToken:2711` |

There is **no ticker-driven ambient loop** on the board: nothing animates while the board
idles. Everything above is event-triggered. (Mini-games have ticker canvases; the board
does not.)

## 2. Board data model

- **All three maps are procedural**, defined in `lib/party/maps/game_map.dart`:
  `buildDownTheHole():201` (spiral), `buildIntoTheVoid():272` (boustrophedon lane grid +
  entry/exit stubs), `buildThroughTheAether():350` (vertical S-curve). Each supplies a
  closed-form `xy(order)` curve; the spiral and S-curve are resampled through
  `_equalArcSamples():133` so consecutive spots sit at constant arc-length spacing. The
  spiral runs ~3.5 turns from outer rim to a floored inner radius (0.24); the anchor
  (order 87) is special-cased to the dead center. Coordinates are **normalized [0..1]**
  and stretched to the (portrait, 2.2:1) board rect — the spiral is actually an ellipse
  on screen.
- **Tile schema:** `BoardSpace` (`lib/party/party_models.dart:292`) — `index`, `order`
  (0..87), `sectionIndex`, `type`, `nexts` (successors; 2 = fork), `isShortcut`, `x`, `y`,
  `jumpTo` (snakes/ladders/slides). Types are the Dart enum `SpaceType`
  (`party_models.dart:265`): `gain` (+), `lose` (−), `powerUp` (⚡), `event` (?, legacy
  board only — the three GameMaps never emit it), `shop` (market, and order 87 = the
  anchor/DESTINATION), `cardCommon` (Tater card), `cardWild` (Void card). Everything is
  Dart constants — no JSON.
- **Regions ARE in the data model:** `BoardSection` (`party_models.dart:196`) —
  `BioScale`, name, `color`, icon, themed power-up. Each GameMap carries its own list
  (8 for Hole/Aether, 10 for Void); a tile's tint = `sections[space.sectionIndex].color`.
  Down the Hole's 8 bands: SURFACE → FLESH → WEAVE → CHAMBER → ENGINE ROOM → BONDS →
  GRAINS → THE FLOOR, 11 spots each (`game_map.dart:202-219`).
- **Edges are implicit:** a link is drawn from each space to each entry of `nexts`;
  jumps (`jumpTo`) get separate green/red accent lines. There is no edge object to hang
  data on (no per-edge width/decoration/curve — links are straight `drawLine` segments).
- **Shared vs board-specific:** one data format, one renderer. `_assembleSpaces()`
  (`game_map.dart:155`) builds all three from per-map masks (powerUps/cards/shops/loses/
  forks/jumps sets). The only per-board branching in the renderer is `useXY` (GameMap
  x,y layout) vs the legacy 52-space ring (`kMainLoopLength`, rounded-rect path
  metrics). **A visual overhaul of Down the Hole lands in shared code paths** unless
  explicitly keyed off `GameMap.id`.

## 3. Visual layer inventory (paint/build order)

Stack order inside `_BoardView.build` (`:2600` region), bottom → top:

1. **Background: nothing.** `Scaffold(backgroundColor: Colors.black)` — the board floats
   on flat black. No scenery layer exists.
2. `_BoardPathPainter` (`:3153`), one `Positioned.fill` CustomPaint drawing, in order:
   region-tinted straight links (`_paintTopology:3243`), direction chevrons (every 3rd
   link), region name labels at section centroids (`TextPainter`), the DESTINATION and
   MARKET labels, snake/ladder accent lines, and path diamonds (`_paintDiamonds:3324` —
   the cyan gems perched at each tile's top-right).
3. **Tiles:** one `_node()` widget per space (`:2824`) — a `Container` circle
   (`BoxDecoration` + `boxShadow` glow, section-tinted fill at 0.22 alpha over near-black)
   with a Material `Icon`, wrapped in a `GestureDetector` (tap-to-inspect) and a
   `foregroundPainter: _NodeDecorPainter` (`:4140`) for type decor: market awning
   (annular stripes), event swirl, wild-card sparks. **Size hierarchy already exists:**
   anchor 2.1×, shop 1.6×, shortcut 0.85×, base radius capped at 24 world px.
4. START text label.
5. **Player tokens** (`_tokens:2941`): `AnimatedPositioned` circles with character
   portrait `Image.asset` clipped oval (the one raster exception; assets in
   `assets/characters/*.png`), white ring + glow for the active player, fan-out when
   co-located.
6. Op tokens (Peeler/Masher, `CustomPaint`), ghosts (`_GhostPainter:4091`).
7. Landing delta pop (`_landingPop:2662`).
8. UI chrome outside the InteractiveViewer: top bar (close / ROUND n / center-me /
   standings), zoom buttons overlay (`_zoomButtons:1198`), scoreboard chips, turn panel,
   space inspector sheet (`_SpaceInspector:2276`).

Everything except the character portraits is **drawn in code** (vector/canvas/widgets).

## 4. Performance envelope

- 88 spaces per map ⇒ ~88 node widgets + ~90 links + tokens/ops/ghosts, all built every
  `setState` of `_BoardScreenState` (the controller notifies per step/phase).
  **No culling** — offscreen nodes still build/layout (paint is clipped by the viewer).
  **No RepaintBoundary anywhere in the board layer** (grep: only `shouldRepaint`
  overrides). `_BoardPathPainter.shouldRepaint` (`:3404`) only fires on canvas-size or
  diamond-count change; node decor painters are static.
- The scene is effectively static between events, so today's cost profile is fine. The
  documented perf law (CLAUDE.md rule 6, `docs/…` memory: harvest-jitter, black-screen)
  is the constraint for the overhaul: **continuous motion must live on ONE ticker-driven
  CustomPainter, not in per-frame widget rebuilds**; in `AnimatedBuilder`, hoist static
  subtrees into `child:`. The "screen goes black mid-game" class of bug is render-cost
  overload (widget-tree animation), not exceptions.
- One quirk: `_onZoom` rebuilds the entire board subtree continuously **during pinch**
  (every 0.001 scale delta). Cheap now; an expensive per-node build would make pinch
  jank first.

## 5. Turn/game-loop hooks

All game logic is `PartyController` (`lib/party/party_controller.dart`, ChangeNotifier,
host-authoritative lockstep — every mutation must replay identically, so **visual life
must live in the view layer, never the controller**):

- **Roll:** `roll()` (`party_controller.dart:454`) → `PartyPhase.moving`.
- **Walk pacing (view-side):** `_syncMovement` (`party_page.dart:942`) starts a 240 ms
  `Timer.periodic` → `_onStepTick` (`:968`) calls `actions.advanceStep()` then
  `_centerOn(position, animate: true)` — the camera walks WITH the token, one node per
  beat. Hook point for per-step effects (footfall particles, node pulse underfoot).
- **Step/land (logic-side):** `advanceStep()` (`controller:567`) → `_stepTo` (`:601`,
  diamond pickup, market pass-by offer, op collisions) → `_finishStep` (`:660`, jumps
  resolve, `LandingEffect` stamped with `++_landingSeq`) → `_resolveSpace` (`:707`, the
  type switch). The view already keys one-shot FX off `controller.lastLanding.seq`
  (`_landingPop`) — **the same seq is the natural trigger for landing particles**.
- **Camera:** `_driveCamera` (`party_page.dart:859`) is the single choke point for all
  programmatic camera moves (re-frames, walk tracking, zoom buttons) — add shake/
  drift/punch-ins there. Phase transitions (`PartyPhase` enum, `controller:76`) are
  observable in the view's `AnimatedBuilder` for cutscene-grade beats.

## 6. Constraints & opportunities for the overhaul

- **(a) Idle/ambient tile animation — cheap IF done right.** There is no board ticker
  today; add ONE `Ticker`/`AnimationController` driving a repaint of `_BoardPathPainter`
  (or a new ambient painter layered under the nodes) and keep the 88 node *widgets*
  static. Animating the `Container` nodes per-frame is the documented black-screen
  failure mode.
- **(b) Path ribbon under tiles — cheap.** `_paintTopology` already draws per-link
  lines; replacing straight `drawLine`s with a glowing ribbon `Path` through consecutive
  node centers is a localized painter change. Caveat: links are derived from `nexts`
  pairs, not a polyline — building a smooth ribbon means reconstructing the order-walk
  (trivial: spaces are order-sorted) and handling forks/jumps separately.
- **(c) Per-region scenery layers — open field.** Background is flat black; anything
  (parallax starfield, strata bands for the descent, dust) slots under the path painter.
  Region data (8 named, colored `BoardSection` bands) already exists to key scenery off.
  The board rect is 7.2× the viewport (~2800×6100 world px on a phone) — scenery must be
  painted procedurally per visible region, not as one giant raster.
- **(d) Tile size hierarchy — already in place** (anchor 2.1× / shop 1.6× / shortcut
  0.85×), trivially extensible in `_node()`'s radius multiplier.
- **(e) Landing particles — cheap.** Trigger off `LandingEffect.seq` exactly like
  `_landingPop`; a short-lived ticker CustomPaint at the landing node. `lib/games/fx.dart`
  (`GameFx`) is the shared premium-rendering kit mini-games use — reusable here.
- **Hard-coded assumptions a redesign will collide with:**
  - Node radius capped at 24 world px and **divided by live zoom** everywhere
    (`_BoardGeometry:3056`); any new decor must do the same `/z` counter-scale or it will
    balloon/shrink against the tiles while pinching.
  - Normalized coords stretch to a portrait rect — circles in map-space are tall
    ellipses on screen; scenery drawn in normalized space inherits the distortion.
  - `_NodeDecorPainter` is a `foregroundPainter` painting OVER the node (awning bug
    history: an opaque "cutout" there erases the tile).
  - Z-order is fixed by Stack child order in `_BoardView.build`; there's no z-index
    concept — new layers are inserted by position in that list.
  - The legacy 52-space ring shares this renderer via `useXY == false` branches — don't
    break it (regression-guarded in `test/party/board_play_test.dart`).
  - Labels (region names, MARKET, DESTINATION) are painter-drawn `TextPainter` calls
    inside `_BoardPathPainter`, not widgets.

## Renderer Reality Check

1. No engine, no shaders, no Rive/Lottie: the board is Flutter widgets + two
   CustomPainters on flat black, panned by a stock `InteractiveViewer`.
2. All 88 tiles are individual widgets rebuilt on every phase/step notify AND
   continuously during pinch-zoom; there is no culling and no RepaintBoundary — ambient
   motion must go on a single ticker-driven canvas layer, never on the tile widgets.
3. Everything counter-scales by live zoom (`/viewScale`) to hold constant on-screen
   size; new visuals that skip this will visibly breathe against the board while zooming.
4. The board idles completely still today — every existing animation (camera, token,
   dice, pops) is event-triggered; there is zero ambient-motion infrastructure to reuse,
   so the overhaul creates that layer from scratch.
5. Down the Hole's geometry is one closed-form spiral curve resampled at equal arc
   length (`game_map.dart:226`) — the inward pull is parametric and can be re-shaped in
   one function without touching topology (order/forks/jumps stay fixed; MAPS_SPEC locks
   those, not the x,y presentation).
6. Region identity already exists in data (8 colored, named bands per map) but is only
   expressed as node tint + one centroid label — scenery/atmosphere per band has a ready
   key and an empty canvas.
7. Links are per-`nexts` straight lines, not a polyline path object — a ribbon/river
   treatment must reconstruct the walk order (easy) and decide fork/jump styling.
8. Game state is lockstep-replayed (`PartyController` input log + random tape): visual
   life may read the controller but NEVER mutate it or introduce nondeterminism.
9. Landing/step hooks are clean: 240 ms step timer in the view (`_onStepTick`),
   `LandingEffect.seq` for one-shot landing FX, `_driveCamera` as the single camera
   choke point.
10. World scale check: the board rect is ~2800×6100 world px, node diameter 48, gaps
    ~200–440 (Hole) — there is real empty space between tiles now; decor has room but
    must be procedural (a full-board raster would be enormous).

**Uncertainties:** none material. The only unverified guess above is exact world-pixel
figures (derived for a 390×844 viewport; other viewports scale proportionally), and
`SpaceType.event`'s absence from the three GameMaps was verified by reading their
`_assembleSpaces` masks (no `events` set exists in the assembler), not by runtime trace.
