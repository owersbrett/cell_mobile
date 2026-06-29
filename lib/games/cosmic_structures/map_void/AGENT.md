# AGENT.md — Map the Void

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/cosmic_structures/map_void/` (code + these docs).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/theme/potatuhs.dart`, Flutter/dart:math —
  do NOT modify without escalation.
- **Do not touch** other games, the router, `mini_game_registry.dart`, or `game_catalog.dart` beyond an
  explicit task. The registry/catalog entries for this game are owned by the orchestrator.

## Scene / exit contract
- Mounts inside an isolated host scene; must never trap the player. Exit / timer / score / results are
  host-owned (see `mini_game_host.dart`). This widget renders ONLY the play area.
- Auto-starts on `session.isRunning`; before that it shows a calm survey field (ambient drift, no
  urgency arc, no timers advancing).
- Reports via `session.addScore(award)` + `session.noteStreak(streak)`. Never calls `endEarly`.

## Files
- Widget: `map_void_game.dart` → `MapVoidGame` (+ private `_SkyPainter`, `_Region`, `_Galaxy`,
  `_Particle`).
- Rules (canonical): `GAME.md` — change rules THERE first.
- Education ledger: `EDUCATION.md`.
- POTATUHS profile: `POTATUHS.md`.

## Architecture (performance-critical)
- **One `Ticker`** (`_onTick`) → advances clocks/sim/particles → a single `setState(() {})` per frame.
- All scene visuals (background, galaxies, scope reticle, urgency arc, particle bursts) are painted by
  **one `CustomPainter` (`_SkyPainter`) under a `RepaintBoundary`**. No per-frame setState over a heavy
  widget tree. Only three lightweight buttons + an overlay banner sit outside the painter.
- Galaxy positions are normalized to the scope radius (`_Galaxy.rel`), so generation is size-independent.

## Tunable constants (current implementation)
- Scoring: `_kMaxPoints = 100`, `_kFloorPoints = 20`, `_kStreakStep = 3`.
- Ramp: `_kRampSeconds = 42`; decision window `_kWindowEasy 2.6 → _kWindowHard 1.05`; sweep
  `_kSweepEasy 0.46 → _kSweepHard 0.22`.
- Region mix: void share `0.54 + 0.06·d`, filament `0.28 − 0.02·d`, cluster = remainder.
- Cluster members `18 → 10`; filament members `13 → 8`; void strays `0–1 + round(3·d)`.
- `_kFeedbackDur = 0.34`, `_kBurstCount = 16`.

## Known TODOs / tuning notes
- `humanMax` / `starThresholds` in the spec are first-pass estimates — re-tune by playtest.
- The void-share growth could be made adaptive (raise it if a player over-tags structure) to push the
  lesson harder; currently it's purely time-driven.
- Possible juice: a one-frame "scale tally" on results showing how lopsidedly void the run was.

## Assets
- Canvas-drawn / procedural ONLY (galaxy dots + halos, scope reticle, crosshairs, urgency arc, spark
  bursts, ambient glow, static cosmic-web backdrop). No PNG/JPEG.
