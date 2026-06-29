# Tissue Type — POTATUHS.md

## Where it sits
- **Vertical:** hotpotatogames (Summer rip). Launch artifact: `cell_mobile` →
  explore-the-cell.web.app.
- **Scale:** `BioScale.tissue` — one rung up from the cell, one below the organ.
  Slots into the zoom ladder between cell-scale and organ-scale games.
- **Objective:** Summer moon cycle 1 — **GAMES**. This title is built to the
  five-part rubric so it counts toward the 4-complete-games needle.

## GAMES rubric status
- **G — Game:** `TissueTypeGame` — a playable speed-classify histology game.
- **A — Agent:** `AGENT.md` (dedicated maintainer agent + contract).
- **M — Manual:** `GAME.md` (rules, scoring, win condition).
- **E — Education:** `EDUCATION.md` (the four primary tissue types, in the mechanic).
- **S — Session:** host-owned clock/results; closes and re-enters cleanly with a
  reshuffled deck and reset difficulty. The widget never calls `endEarly`.

## Design notes (Potatuhs voice)
"Uhhh… is that a sheet or a scatter?" The whole game is one honest question asked
fast, over and over, until your eye just *knows*. No colour crutch — Butter would
say the stain has always been pink and purple; don't worry about it. Read the shape.

## Self-containment
Imports only `mini_game.dart`, `theme/potatuhs.dart`, `package:flutter/*`,
`dart:math`. Touches no registry/catalog/host/sibling-game code. Inlines its own
`_Particle`. Verified `flutter analyze lib/games/tissue/tissue_type/` → 0 issues.

## To enable in the app (NOT done here — owner step)
Add to `mini_game_registry.dart`:
```dart
import 'tissue/tissue_type/tissue_type_game.dart';
```
plus the `MiniGameSpec` (see the report / GAME.md), and a `CatalogGame` with
`specId: 'tissue_type'` in `game_catalog.dart`.
