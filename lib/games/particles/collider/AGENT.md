# AGENT.md — Collider

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** this game's code + docs. Code: `lib/games/arcade/collider.dart`
  (`ColliderGame`); docs: `lib/games/particles/collider/`. Shared scale data:
  `lib/games/particles/PARTICLE_TIMELINE.md` (+ future `particle_timeline.dart`).
- **Read-only shared kit:** fx/design helpers, `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games, the router, or the registry beyond an explicit task.

## Scene / exit contract
- Isolated scene; never trap the player. Exit/timer/results host-owned. Error boundary keeps exit alive.

## Files
- Widget: `lib/games/arcade/collider.dart` → `ColliderGame`
- Spec: `GAME.md` · Manual: `MANUAL.md` · Scale education: `../EDUCATION.md` · Timeline: `../PARTICLE_TIMELINE.md`

## Tunable constants (current)
- `_kRingCount = 5`, speed `1.08^level`; `_kBaseSpeed1 = 1.4`, `_kBaseSpeed2 = 1.75` rad/s
- `_kPerfectSep = 10°`, `_kCloseSep = 25°`; scores `15 + level×8` / `6 + level×4`; miss `−5`
- Shake: `_kShakeThreshold = 12`, `_kMaxShakeBoost = 2.0`, `_kShakeDecay = 1.6/s`

## To build
- **Discovery flare:** shared `particle_timeline.dart` (const list from PARTICLE_TIMELINE.md);
  advance one entry per PERFECT; render a brief dismissible card (`name · year · who`).
  Non-scoring, never blocks input. Persist the timeline index for resume.

## Known bugs / TODOs
- Flash bloom uses `geom.radius` (legacy ring-0 accessor) instead of `radiusForLevel(level)` —
  the PERFECT flash renders at the innermost ring, not the active one. Fix to current ring.
- `userAccelerometerEventStream()` has no guard on devices without an accelerometer — add a
  try/onError so shake-boost degrades gracefully.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
