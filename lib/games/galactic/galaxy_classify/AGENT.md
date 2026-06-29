# Galaxy Classifier — AGENT.md (the A: assigned agent)

You are the owning agent for **Galaxy Classifier** (`lib/games/galactic/galaxy_classify/`).
This game is a self-contained module. You may change anything **inside this
folder**; you must not edit the registry, catalog, host, or any other game.

## Charter
Keep this a **fast, legible snap-classification of galaxy morphology**. The fun is
in *reading* a shape and naming it under time pressure — never in chasing or
collecting. If a change makes the four types harder to tell apart for the *wrong*
reason (muddy rendering, ambiguous spawns), it's a regression.

## Scope (files you own)
- `galaxy_classify_game.dart` — the widget, the sim loop, procedural galaxy
  generation, the field painter, the type-button glyphs.
- `GAME.md` / `EDUCATION.md` / `POTATUHS.md` — keep them true to the code.

## Invariants — do not break these
1. **Class signature:** `class GalaxyClassifyGame extends StatefulWidget` with
   `final MiniGameSession session;` and `const GalaxyClassifyGame({super.key,
   required this.session})`. The registry builds it by this exact shape.
2. **Host owns the clock.** Render only the play area. No timer, no countdown, no
   results screen here. Gate the sim on `session.isRunning`; never call
   `endEarly`.
3. **One Ticker, one CustomPainter.** Every galaxy and particle draws on the
   single `_FieldPainter`, repainted via the `_FrameSignal` `Listenable`. Do
   **not** introduce per-frame `setState` over the widget tree, and do not give
   each galaxy its own animation/widget. `setState` is only for discrete events.
4. **Exactly four answers:** Spiral / Barred Spiral / Elliptical / Irregular. They
   are the Hubble tuning-fork classes; do not silently add or rename one without
   updating EDUCATION.md.
5. **Self-contained.** Import only `dart:math`, `package:flutter/*`, and
   `../../mini_game.dart`. No dependency on another game or a `batch*` megafile.
   Inline any tiny helper you need (the `_Star` / `_Particle` pattern).
6. `flutter analyze lib/games/galactic/galaxy_classify/` must report **zero
   issues** after any change.

## Good directions to take it
- Sharper procedural rendering that makes barred-vs-unbarred and tight-vs-loose
  spirals *fairly* readable (the difficulty should come from speed and subtlety,
  not from sloppy art).
- A "lenticular (S0)" stretch type or edge-on galaxies as an advanced, clearly
  flagged variant — but only if the four-button read stays clean.
- Tuning `humanMax` / `starThresholds` from real playtests (see the spec in
  `mini_game_registry.dart`).

## Tuning knobs (constants at the top of the file)
- `_kMaxPoints`, `_kFloorPoints`, `_kDecayWindow`, `_kStreakStep` — speed/streak feel.
- `_difficulty` ramp (`_playClock / 45`), `_lerp` speed/spawn bounds in `_simulate`,
  and `_pickType` weights — the acceleration and the spawn mix.
- Procedural generators `_genSpiral` / `_genElliptical` / `_genIrregular` — the look.
