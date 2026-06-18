# AGENT.md — Accelerator

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** this game's code + docs. Code: `lib/games/arcade/accelerator.dart`
  (`AcceleratorGame`); docs: `lib/games/particles/accelerator/`. Shared: `../PARTICLE_TIMELINE.md`.
- **Read-only shared kit:** fx/design helpers, `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games, the router, or the registry beyond an explicit task.

## Scene / exit contract
- Isolated scene; never trap the player. Exit/timer/results host-owned. Error boundary keeps exit alive.

## Files
- Widget: `lib/games/arcade/accelerator.dart` → `AcceleratorGame`
- Spec: `GAME.md` · Manual: `MANUAL.md` · Scale education: `../EDUCATION.md` · Timeline: `../PARTICLE_TIMELINE.md`

## Tunable constants (current)
- `_kDrainBase = 0.18/s`, `_kDrainStep = 0.04/s`, `_kTapBoost = 0.12`
- `_kBandWidthL1 = 0.28`, `_kBandShrinkPerLevel = 0.03`, `_kBandMinWidth = 0.06`, `_kBandCentre = 0.62`
- `_kLevelUpDwell = 2.5 s`; collision score `30 + level² × 8`; in-band drip `+4/s`

## To build
- **Discovery flare:** shared `particle_timeline.dart`; advance one entry per collision; brief
  dismissible card (`name · year · who`); non-scoring; persist timeline index.
- **Explore reachability:** this game is NOT on Explore today (Explore returns Collider only).
  Needs the per-scale game picker (registry `gamesForScale()` + Explore chooser) — escalate; touches navigation.

## Known bugs / TODOs
- Tap sparks spawn at `Offset.zero` (canvas top-left) rather than the gauge/tap point — fix origin.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
