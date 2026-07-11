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

**Checkpoint answers (Q1–Q10)** — PENDING

## Stage 1 — Ribbon + breathing tiles — NOT STARTED

## Stage 2 — Strata atmosphere — NOT STARTED

## Stage 3 — Dwellers — NOT STARTED

## Stage 4 — Step & landing FX — NOT STARTED

## Invariant tensions discovered

- None yet. One watch-item carried from recon: `_onZoom` rebuilds the board
  subtree during pinch; the ambient layer's painter is reconstructed on each
  such rebuild (cheap — precomputing 88 centers), but Stage 2/3 must keep
  their constructor work equally flat.
