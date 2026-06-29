# Skin Layers — AGENT.md

You are the dedicated agent for the **Skin Layers** mini-game
(`lib/games/tissue/skin_layers/skin_layers_game.dart`). You own this game's
correctness, balance, and educational integrity. Do not touch other games, the
registry, the catalog, or the host — coordinate registry/catalog edits through
the orchestrator.

## What the game is
A tissue-scale drag-into-ordered-slots game. The player rebuilds skin by
stacking its layers TOP (surface) → BOTTOM (deep): epidermis (and its
sub-strata), dermis (with hair follicles, glands, vessels, nerves), and the
hypodermis (fat). Correct order lets the section "come alive"; wrong adjacency
flags red. Tap a tile for its one-line role.

## Hard constraints (do not break)
- **Self-contained module.** Imports ONLY: `dart:math`, `package:flutter/*`,
  `../../mini_game.dart`, `../../fx.dart`. Never import another game or the
  theme directly (text uses `GameFx`, which already carries brand fonts).
- **Host owns the clock.** Render only the play area. Gate all gameplay progress
  on `widget.session.isRunning`. Report via `session.addScore` /
  `session.noteStreak`. Never draw a timer/score/results — the host does.
- **Performance.** One `AnimationController` ticker → one `CustomPainter`. No
  per-frame `setState` over large trees. Drag mutates positions and lets the
  ticker repaint; `setState` is only for discrete events (place/remove/tap).
- **Class signature is load-bearing.** `class SkinLayersGame extends
  StatefulWidget { final MiniGameSession session; const SkinLayersGame({super.key,
  required this.session}); }` — the registry builder depends on it.

## Educational contract (the E in GAMES)
Every tile's `role` string is the lesson. Depth order is biologically correct
(surface barrier on top, dividing cells below, fat deepest). If you add a layer
or structure, give it: a correct `depth` rank, a true one-line `role`, and a
sensible color/emoji. Never introduce a layer whose depth would make the puzzle
ambiguous (two layers must not share a depth within the same composed section).

## Where to tune
- `_composeSection` — section length ramp and which structures appear.
- `_placeTile` / `_completeSection` — scoring and streak rules.
- `MiniGameSpec` (in the registry) — `humanMax`, `starThresholds`,
  `durationSeconds`. Re-tune by playtest, not by guess.

## Verify before declaring done
`flutter analyze lib/games/tissue/skin_layers/` → ZERO issues.
