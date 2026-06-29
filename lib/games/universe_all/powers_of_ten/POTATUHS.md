# Powers of Ten — POTATUHS.md

## Where it sits
- **Vertical:** hotpotatogames (Summer rip) · **Cycle:** 1/3 — GAMES.
- **Launch artifact:** `cell_mobile` → explore-the-cell.web.app.
- **Scale:** `BioScale.universeAll` — the outermost rung of the Explore-the-Cell
  zoom, where the cell tour resolves into the whole cosmos.

## GAMES rubric status
- **G — Game:** `powers_of_ten_game.dart` — `PowersOfTenGame` widget, playable
  drag-to-place scale ladder. ✅
- **A — Agent:** `AGENT.md` (owns this folder only). ✅
- **M — Manual:** `GAME.md` (rules, scoring, win condition). ✅
- **E — Education:** `EDUCATION.md` (orders of magnitude; education is the
  mechanic). ✅
- **S — Session:** host-owned clock; stateless per run; calm ready state;
  auto-start on `isRunning`; clean close + re-entry. ✅

## Design intent (brand)
Distinct from the scale's existing `everything` game (purple/gold word-finder):
this one is a **cyan, scientific, log-ladder** placement game. It dramatizes the
"powers of ten" zoom that the whole Explore-the-Cell journey embodies — from the
inside of an atom out to the observable universe — turning the app's core
metaphor (zooming across scales) into a scored mechanic.

## Isolation
Self-contained module. Imports only `mini_game.dart`, `fx.dart`,
`theme/potatuhs.dart`, and Flutter. No dependency on any other game, the
registry, the catalog, or the host. `flutter analyze` on the folder: 0 issues.

## Status board
See `~/Potatuhs/hpg/_status/cell_mobile.md` for the consultant-facing status;
update it when goals/milestones change.
