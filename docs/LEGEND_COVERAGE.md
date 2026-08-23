# GOAL — 100% visual how-to-play coverage (legendFrames)

**Definition of done:** every ENABLED registry spec in
`lib/games/mini_game_registry.dart` carries `legendFrames` (≥ 2 frames; aim
for 3–4) so the pre-game intro shows the visual manual carousel — never the
text-bullets fallback. Machine gate: `test/games/legend_coverage_test.dart`
(RED until 100%; the loop runs until it is green).

Baseline 2026-07-03: **1 / 124** enabled specs covered (`sort_spuds`, the
pilot). The host side (`_LegendCarousel` in `mini_game_host.dart`) is DONE —
this goal is purely per-game content + one-line registry wiring.

## The recipe (per game — mirror the sort_spuds pilot)

1. In the game's own file (or a sibling `*_legend.dart` inside the game
   folder), add top-level painters + the exported list:
   ```dart
   void _legendX(Canvas canvas, Size size) { ... } // reuse the game's OWN draw code
   final List<LegendFrame> <camelId>LegendFrames = [
     const LegendFrame(caption: '...', paint: _legendX),
     ...
   ];
   ```
2. Frames show the LITERAL components the player meets (the exact orb, tell,
   bin, enemy — drawn by the same code the game uses), not abstract diagrams.
   Caption = one imperative line. Cheap + self-contained: they render
   statically in the intro, never per-frame.
3. Frame arc: (a) the core objects/verbs, (b) how to score, (c) the danger /
   what loses points, (d) the twist or late-game escalation (if the game has
   one — e.g. sort_spuds' two-belt split).
4. Registry wiring (ORCHESTRATOR ONLY): add `legendFrames: <camelId>LegendFrames,`
   to the spec + the import already exists (specs already import each game file).

## Loop protocol (self-paced /loop)

Each iteration = one wave:
1. List uncovered enabled specs (gate test output or grep). Pick ~8, worst-
   ranked / most-confusing games first (they need the manual most).
2. Dispatch ONE agent per game, in parallel. Agent scope: that game's folder
   ONLY. The agent adds painters + the exported `LegendFrames` list, runs
   `flutter analyze` on its folder, and reports the exported symbol name.
   Agents NEVER touch `mini_game_registry.dart` / catalog / host.
3. Orchestrator wires all registry `legendFrames:` lines (surgical,
   append-style), runs `flutter analyze` + the gate test, logs
   `N/124 covered`.
4. Gate green → run `/deploy`, update `~/Potatuhs/hotpotatogames/_status/cell_mobile.md`,
   end the loop.

## Quality bar

- Painters must guard degenerate sizes (no NaN/zero-size draws — the
  black-screen bug class).
- Palette from the game's own accent + `lib/theme/potatuhs.dart`; no new hex.
- A frame that just draws text is a fail — it must SHOW the component.
- Captions ≤ ~60 chars, imperative ("Tap the crate…", not "The crate can be
  tapped…").
