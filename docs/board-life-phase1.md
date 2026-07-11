# Board Life — Phase 1 (Down the Hole)

> Running record of the board-life overhaul. Per stage: what was built, the
> tooling-truth evidence, and the user's checkpoint answers recorded verbatim.
> Spec + architectural anchors: docs/board-render-recon.md.

## Stage 0 — Ambient infrastructure (built 2026-07-10, commits 2a5cd65 + tests)

**What was built**

- `BoardAmbientClock` (`lib/party/screens/board_ambient.dart`) — the single
  ambient clock: one `Ticker` accumulating elapsed seconds (continuous across
  stop/start), exposed as a `ChangeNotifier`. Owned by `_BoardScreenState`;
  created + started only when the map is in `kBoardLifeMaps`. Pauses on app
  background (`WidgetsBindingObserver.didChangeAppLifecycleState`); route
  visibility is free because `_BoardScreen` unmounts during mini-games and
  cutscenes (phase switch), disposing the clock's owner.
- `BoardAmbientPainter` — the first ambient canvas layer, inserted in
  `_BoardView.build`'s Stack directly BELOW `_BoardPathPainter`, wrapped in
  `RepaintBoundary`, repainting via `super(repaint: clock)` — node widgets
  never rebuild for ambient frames. Receives spaces, sections, precomputed
  world-space centers + the same counter-scaled `nodeRadius` the tiles use,
  the live `TransformationController`, and the viewport size.
- **First-ever board culling:** the painter derives the viewport rect in
  world space from the live camera matrix each frame (correct during pans
  between rebuilds) and AABB-skips everything outside it, padded by
  `kAmbientCullPadNodeRadii` (4 node radii).
- **Bounded per-frame work:** per-tile phase = `index * kGoldenPhase` (no
  stored per-frame state); the `Paint` + `MaskFilter` are instance fields
  (no allocations in the hot loop).
- `board_life_tuning.dart` — every ambient/FX tunable as named constants
  (pulse period/amplitude/alpha/blur, cull pad, map gating). Checkpoint
  feedback = constant edits here.
- **Placeholder content** (Stage 1 refines it): a soft section-tinted
  under-glow disc per visible tile, breathing at `kTilePulsePeriodSec` with
  golden-angle phase offsets, matching each tile's size multiplier
  (anchor 2.1× / shop 1.6× / shortcut 0.85×).

**Gating / invariants**

- `kBoardLifeMaps = {'down_the_hole'}` — legacy 52-space ring and the other
  two GameMaps get no clock, no layer, zero cost.
- Controller untouched; the layer is read-only over controller state and
  never hit-tests (taps pass through to tiles).

**Tooling truth (agent-verifiable portion)**

- `flutter analyze`: clean on all touched files (repo-wide: 0 new issues).
- `flutter test test/party/`: 66/66 pass, including end-to-end playthroughs
  of all three maps and the legacy-ring regression guard.
- New `test/party/board_ambient_test.dart`: clock stop/start accumulation;
  painter paints Down the Hole at zoom 0.139 / 1.45 / 5.0 without throwing.
- Widget-repaint isolation is architectural (RepaintBoundary + repaint
  listenable, no setState per tick); repaint-rainbow visual confirmation and
  on-device frame times are the user's checkpoint (run in `--profile`,
  DevTools → Performance overlay / debug paint).

**Checkpoint answers (Q1–Q10), round 1 — 2026-07-10 — FAILED, fixes applied**

Verbatim: (1) "when the board is idle, nothing appears to be happening."
(2) "no idle ambient motion - also, massive issue when i roll dice, which was
apparent before this - the camera and the movement of dice are not together.
when a character moves, the camera should follow the character, and settle
with the character, on each node, like how a board game would play, going one
node by one node at a time. i am not sure if that was in the deposition but
it is necessary to fix." (3) "returns fine but no ambient motion" (4) "there's
no way to 'navigate to a menu'. if i try to go back, i am asked if i am ready
to quit the game." (5) "still no ambient motion" (6) "no ambient motion"
(7) "token slide and camera tracking are still awful." (8) "legacy 52 space
ring board? how ?" (9) "no online mode yet - not until we figure out what this
phase was even for."

**Root causes + fixes (same day):**

- *Invisible ambient (Q1–Q6):* wiring was live (clock ticking, layer mounted
  — every `PartyController` construction passes a non-null `gameMap`, and the
  spiral rendered), but the placeholder glow peaked at alpha 0.15 through a
  0.55-radius blur on a near-black board — below the perceptual floor
  (~RGB 6,25,23 over black). Tuning boost: alpha 0.10–0.40, glow 2.1×,
  blur 0.35, period 3.6 s.
- *Walk feel (Q2/Q7):* pre-existing, now in scope by user order. The 240 ms
  step timer vs 230 ms slide left ZERO settle — continuous gliding, "a chase,
  not a journey" (PARTY UX LAW violation). Fix: `kWalkHopMs = 240` (token hop
  + camera glide, started same tick, arrive together) inside
  `kWalkStepPeriodMs = 520` (each node gets a visible ~280 ms rest), plus the
  camera now glides to the walker when the moving phase BEGINS, before the
  first hop.
- *Q4:* not a defect — the board screen has no side menu by design; it
  unmounts on mini-game entry (that transition is the visibility test).
- *Q8:* the legacy ring is UNREACHABLE from the UI (all construction sites
  pass `gameMapById(...)`, never null); its regression coverage is the
  automated `board_play_test.dart` guard, not a manual check.
- *Q9:* deferred by user until the phase proves itself.

**Checkpoint answers, round 2 — 2026-07-10 — glow PASSED, walk desync found**

Verbatim: "the glow is actually a massive improvement, feels a lot better. i
just hit roll though, and then it moves the camera to where i 'will' be
moving to. then, if i pinch the map, all of the sudden my character goes
there. i should be navigating to it. otherwise, all the tests pass"

**Diagnosis + fix:** the camera and the token had different drivers. The
camera is timer-driven (`_centerOn` writes the transform directly — needs no
widget rebuild); the token's `AnimatedPositioned` retargets only when the
board REBUILDS, which relied on the controller-notify → AnimatedBuilder
chain. When that chain stalls, the camera marches node-by-node to the
destination while the character stands still — until any foreign rebuild
(the pinch's `_onZoom` setState) snaps it there. Fix: `_onStepTick` now wraps
`advanceStep()` in its own `setState`, so the SAME tick drives both the hop
and the glide — they can no longer desync. Regression guard:
`test/party/walk_visual_test.dart` drives a real autopilot game and asserts
tokens move through many WORLD positions (measured relative to the
board-fixed START label so camera motion cancels out — absolute positions
would mask a frozen token).

The harness also caught three real phone-size overflows (390×844), fixed:
the LEADER'S TERRITORY badge (party_page), the mini-game HUD name row
(mini_game_host), and the wheel-ceremony overlay (wheel_screen — now
centers-until-overflow-then-scrolls). Same class as the PotatuhsButton
overflow fixed earlier today.

**Checkpoint answers, round 3 — 2026-07-10 — walk close, residual jerk**

Verbatim: "its close, still feels jerky. i tap roll, the character animates
up a little bit, then back to the circle (not sure whats going on there) i
hit move, i recenter, then the first move is jerky, hard to explain how -
then the rest of the movements seem accurate"

**Diagnosis + fix:** the board world was sized off the Expanded area LEFT
OVER by the turn panel, and the panel changes height on every phase (ROLL
button → dice panel → walking panel). Each change rescaled the whole 7.2×
world, re-positioning every node and token; AnimatedPositioned animated the
shift — the ROLL bounce ("up a little bit, then back") — and the first hop
rode still-moving geometry while later hops had stable geometry ("rest of
the movements seem accurate"). Fix: the canvas now derives from
`MediaQuery.sizeOf` (the screen), which is constant for the whole match;
panel changes no longer touch board geometry at all.

**Checkpoint round 4 — 2026-07-10 — STAGE 0 PASSED**

Verbatim: "much better now" (world-stability fix) · "i cut that in half and
it's a lot better now" (walk camera zoom — user tuned kWalkCameraZoom to
0.3 directly in board_life_tuning.dart; the tuning-file-as-dial workflow
works as designed). Glow passed in round 2 ("massive improvement"). Gate
closed: ambient spine live and visible, board-game walk confirmed.

## Stage 1 — Ribbon + breathing tiles (built 2026-07-10, commit 6fa3b6f)

**What was built**

- **The ribbon** (`_BoardPathPainter._paintTopology`): GameMap per-link
  straight lines replaced by one smoothed road through the walk order
  (midpoint quadratic smoothing) — a dark groove pass (`0xFF16161F`,
  0.85×r wide) under per-node glow+core strokes whose linear gradients BLEND
  section colors across band boundaries (no seams). Fork arms render as thin
  dashed curved tributaries; ladders/snakes/slides as arcing curves (green/
  red preserved); chevrons ride the road tangent. Applies to all three
  GameMaps (shared renderer, per spec); legacy ring untouched.
- **Traveling pulse** (`BoardAmbientPainter._ribbonPulse`): a three-slice
  fading comet moving along the walk-order polyline START → DESTINATION
  (inward on Down the Hole), one lap per `kRibbonPulsePeriodSec` (12 s).
  Arc-length table precomputed per painter; per-frame cost is a few lerps.
- **Breathing variants** (`_breathe`): ⚡ power-ups pulse faster/brighter
  (2.1 s, +35% alpha); the anchor gets a slow deep GOLD heartbeat (sin³
  thump, 2.9 s) at 2.1×1.35 radius — the destination as gravity well.
- **Gem glints** (`_gemGlints`): each remaining path diamond flashes a brief
  white cross-sparkle once per 6.5 s on golden-phase offsets; positions
  identical to `_paintDiamonds`.
- All new params in `board_life_tuning.dart` (ribbon widths/alphas, pulse
  period/window, heartbeat, glint cadence). Ambient content remains gated to
  `kBoardLifeMaps` (down_the_hole).

**Checkpoint answers (Stage 1), round 5 — 2026-07-10**

Ribbon continuous ✓ ("things have improved… oddities and general ui
improvements later"). Walking smooth ✓. Idle good ✓. No new jank ✓ (notes
first-animation jank → shader warmup at MVP). Bands fine ✓ ("the board
should feel a bit chaotic… the ux should just be smooth so the user can be
confident that there are rules being followed"). Fixed same-day from this
round: oval board → SQUARE world (circle spiral); zoom-out couldn't fit the
map → kZoomOutMin 0.05 + counter-scale floor (minimap of dots); fork/jump
long-distance moves get a 700 ms glide (token + camera, build-time
detection); comet never seen → 2 comets, wider/brighter; anchor's odd "gold
arc" was the shop awning (removed — flag + heartbeat is its identity) and
heartbeat made visible (stronger glow + expanding ring); "floating
rhombuses" → faceted brilliant-cut gems; ops (Peeler/Masher) at character
size.

**Backlog captured from round 5 (gameplay/lockstep — NOT view-layer; needs
controller work + Brett's design sign-off):**

- Fork destinations "link back" — clicking to return through a fork
  (topology/gameplay; MAPS_SPEC is locked — awaiting clarification).
- Comet "boof": dawdling on your turn costs ATP/diamonds when the comet
  passes (needs host-authoritative timing — wall-clock is banned in the
  controller).
- Card pile / discard pile players can review; finite deck = counting intel.
- Market → "Potato Shack" restyle; anchor → "the Hole": throw diamonds in
  with risk tiers (x = 1 potato guaranteed; 2x = 90% chance of 2; 3x = 2
  guaranteed + 80% of a third).
- Landing-on-occupied pushes the occupant back one space (cascading until an
  empty node).
- Landing on ANY tile should be more exciting → Stage 4 (landing FX) covers
  the visual half.
- Shader warmup pass at MVP for first-animation jank.

## Stage 2 — Strata atmosphere — NOT STARTED

## Stage 3 — Dwellers — NOT STARTED

## Stage 4 — Step & landing FX — NOT STARTED

## Invariant tensions discovered

- None yet. One watch-item carried from recon: `_onZoom` rebuilds the board
  subtree during pinch; the ambient layer's painter is reconstructed on each
  such rebuild (cheap — precomputing 88 centers), but Stage 2/3 must keep
  their constructor work equally flat.
