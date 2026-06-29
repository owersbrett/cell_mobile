# Crop Rotation — Agent (A)

This game is a **self-contained module**. An agent assigned here may change
anything under `lib/games/farm_system/crop_rotation/` and nothing else.

## Ownership
- **Owned:** `crop_rotation_game.dart`, `GAME.md`, `AGENT.md`, `EDUCATION.md`,
  `POTATUHS.md`.
- **Do NOT touch:** the registry (`mini_game_registry.dart`), catalog
  (`game_catalog.dart`), the host, or any other game. The `MiniGameSpec` lives
  in the registry and is owned by the orchestrator, not this agent.

## Dependency rule (from EXTRACTION_RECIPE.md)
Allowed imports only:
- `../../mini_game.dart` — `MiniGameSession` (score/clock/phase)
- `../../fx.dart` — `GameFx`, `FxParticle`, `FxBurst`, `FxPop`
- `../../../theme/potatuhs.dart` — brand palette/type
- `package:flutter/material.dart`, `dart:math`

Never import another game's code. If you need a tiny shared helper, inline a
private copy — isolation beats DRY here.

## Architecture contract
- **One `AnimationController`** (`_ticker`, `Duration(days: 1)`) drives the whole
  scene. All art renders through a **single `CustomPainter`** (`_FarmPainter`),
  which reads live state and `shouldRepaint => true`.
- No per-frame `setState` over a large widget tree — the play area is one
  `CustomPaint`. Keep it that way.
- The **host owns the clock**: render only the play area. Gate all game logic and
  input on `widget.session.isRunning`. Report points via `session.addScore`, the
  rotation streak via `session.noteStreak`. Never draw a timer/score HUD — the
  host does.

## Mechanic invariants (don't break the education)
- Legumes (`_Family.legume`) must **restore** nitrogen (`nDelta > 0`); cereal
  (corn) must be the heaviest feeder; roots (potato) must **reset pests**.
- Monoculture (same family on a field two seasons running) must visibly hurt
  yield, soil, and pests. Rotation must be rewarded.
- These are the load-bearing learning beats; balance numbers freely, but keep
  the *direction* of every effect.

## Verify before done
```
flutter analyze lib/games/farm_system/crop_rotation/   # ZERO issues
```
Hand-test: plant the same crop twice on one field (watch yield/soil/pests
crash), then rotate (watch recovery), confirm 4→6→8 fields unlock, confirm the
run ends at 60s and a fresh run re-enters clean.
