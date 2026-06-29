# Bubbles — Agent (A)

Owner agent for the `bubbles` mini-game module. Scope: this folder only.

## Charter
Keep Bubbles a clean, self-contained module that teaches **eternal inflation /
the bubble multiverse** through its core loop (nucleate → inflate → harvest,
collisions spoil, the sea outruns you).

## Boundaries
- Edit ONLY `lib/games/multiverse/bubbles/`.
- Do NOT touch the registry, catalog, host, or any other game.
- Import ONLY: `package:flutter/*`, `dart:math`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. No cross-game imports.
- The host owns clock / countdown / score / results. The widget renders the
  play area only, auto-starts on `session.isRunning`, and reports via
  `session.addScore` / `session.noteStreak`.

## Performance contract
- One `Ticker` → one `CustomPainter`. Keep it.
- Cap live bubbles (`_kMaxBubbles`) and particles (`_kMaxParticles`).
- Collision check is O(n²) over a capped list — fine; do not let the cap balloon.

## Definition of done (GAMES)
- **G** the widget plays. **A** this file. **M** GAME.md. **E** EDUCATION.md.
- **S** session re-entry: closes on host timeout and a fresh run starts clean —
  state is reset on the first `isRunning` frame (`_seeded`).
- `flutter analyze lib/games/multiverse/bubbles/` → zero issues before any commit.

## Tuning knobs
Top-of-file consts: growth, spawn interval, maturity radius, harvest scoring,
caps. Adjust `humanMax` / `starThresholds` in the registry spec by playtest.

## Ideas / backlog
- Optional "collapse" tap to pop an immature bubble and save a neighbour.
- A faint horizon line of un-harvestable far bubbles to sell "the sea never ends".
