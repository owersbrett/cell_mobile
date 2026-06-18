# AGENT.md — Corners

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** this game's code + docs. Code lives at `lib/games/arcade/corners.dart`
  (`CornersGame`); docs at `lib/games/somethings/corners/`.
- **Read-only shared kit:** fx/design helpers, `lib/theme/potatuhs.dart` — do NOT modify without
  escalation.
- **Do not touch** other games, the router, or `mini_game_registry.dart` beyond an explicit task.

## Scene / exit contract
- Mounts inside an isolated scene; must never trap the player. Exit/timer/results are host-owned.
- If it throws, the scene error boundary must still let the player exit and continue the session.

## Files
- Widget: `lib/games/arcade/corners.dart` → `CornersGame`
- Spec: `GAME.md` (canonical rules — obey it; change rules there FIRST)
- Manual: `MANUAL.md`
- Education ledger (scale): `lib/games/somethings/EDUCATION.md`

## Tunable constants (current implementation)
- `_kClaimLife = 1.5 s`, `_kTapGrant = 0.45 s`, `_kMaxLife = 2.2 s`
- Concurrent shapes 1 → 5; spawn interval 1.05 → 0.34 s; untouched lifetime 2.4 → ~1.0 s
- 3D solids begin at 40% progress; dodecahedra after 60%
- Vertex counts: tetra 4, octa 6, cube 8, icosa 12, dodeca 20
- Scoring: exact = `corners × 5`; off-by reduces ~34% per unit; exact burst = 16 particles

## Known bugs / TODOs
- `_solidByCorners` uses `firstWhere` **without an `orElse`** — will throw if ever called with a
  corner count not in the solid table. Add a safe fallback.
- `_pickSolid` late-game distribution is uneven (dodecahedron falls through a straight `else`),
  so solid variety is lopsided near the end. Tune the probability ladder.
- **Explore routing (verified):** Explore already shows `CornersGame` for somethings — the
  registry intercepts before the legacy `_buildGame` (which would return `ThoughtCatcher`, now dead
  code for this scale). No consolidation needed; just retire the dead legacy entry during cleanup.
- Optional: end-game "potato" foil shape (see GAME.md potato angle).

## Assets
- Canvas-drawn / procedural ONLY. 2D polygons + projected 3D wireframe solids, corner-dot glows,
  drain rings, spark bursts. No PNG/JPEG.
