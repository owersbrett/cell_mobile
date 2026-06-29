# Tissue Type v2 — POTATUHS.md

## Where it sits
- **Vertical:** hotpotatogames (Summer rip). Launch artifact: `cell_mobile` →
  explore-the-cell.web.app.
- **Scale:** `BioScale.tissue` — one rung up from the cell, one below the organ.
  Slots into the zoom ladder between cell-scale and organ-scale games.
- **Objective:** Summer moon cycle 1 — **GAMES**. Built to the five-part rubric
  so it counts toward the 4-complete-games needle.
- **Lineage:** the UX-refined sibling of `tissue/tissue_type`. One of the
  "phenomenal five" — the original already hit; v2 is a light-touch lift, not a
  rebuild.

## GAMES rubric status
- **G — Game:** `TissueTypeV2Game` — a playable speed-classify histology game.
- **A — Agent:** `AGENT.md` (dedicated maintainer agent + contract).
- **M — Manual:** `GAME.md` (rules, scoring, win condition).
- **E — Education:** `EDUCATION.md` (the four primary tissue types, in the mechanic).
- **S — Session:** host-owned clock/results; closes and re-enters cleanly with a
  reshuffled deck and reset difficulty. The widget never calls `endEarly`.

## The refinement (what the UX pass bought)
The original gated every answer behind a 2.4s fact card that stopped the round —
~15 forced micro-pauses that turned the 7→3s ramp into a stop-start crawl. v2
makes confirmation **instant** (a ~0.4s correct/wrong flash, then straight to the
next slide) and exiles the fact to a **non-blocking bottom ticker** that fades on
its own clock. The streak multiplier is capped at ×4 so nobody runs away from the
table. Everything else — the uniform H&E stain, the four-answer taxonomy, the
procedural `_SamplePainter` histology — is preserved verbatim.

## Design notes (Potatuhs voice)
"Uhhh… is that a sheet or a scatter?" The whole game is one honest question asked
fast, over and over, until your eye just *knows* — and now nothing stops the
asking. No colour crutch — Butter would say the stain has always been pink and
purple; don't worry about it. Read the shape.

## Self-containment
Imports only `mini_game.dart`, `theme/potatuhs.dart`, `package:flutter/*`,
`dart:math`. Touches no registry/catalog/host/sibling-game code (not even v1).
Inlines its own `_Particle`. Verified
`flutter analyze lib/games/tissue/tissue_type_v2/` → 0 issues.

## To enable in the app (NOT done here — owner step)
Add to `mini_game_registry.dart`:
```dart
import 'tissue/tissue_type_v2/tissue_type_v2_game.dart';
```
plus the `MiniGameSpec` (see the report / GAME.md), and a `CatalogGame` with
`specId: 'tissue_type_v2'` in `game_catalog.dart`.
