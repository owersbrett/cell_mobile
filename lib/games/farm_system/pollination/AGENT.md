# AGENT.md — Pollination Dash

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/farm_system/pollination/` — `pollination_game.dart` + these docs.
- **Do NOT touch** other games, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, the router, or any shared file. The registry wiring (a `MiniGameSpec` with
  id `pollination`) and the import line are owned by whoever integrates this module — see the
  bottom of this file for the EXACT spec to paste, but do not edit the registry from here.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart`. Do not modify without explicit escalation.

## Host contract (do not reimplement)
- The widget is `PollinationGame({required MiniGameSession session})`.
- **Score scoring only while `session.isRunning`.** Report points via `session.addScore(delta)` and
  the chain via `session.noteStreak(combo)`. Never draw the timer, score, countdown or results —
  the `MiniGameHost` owns all of those.
- **Calm ready state:** before `isRunning`, flowers still bloom and the bee follows the finger, but
  there is no wilt, no hazards and no scoring — an inviting pre-roll. Auto-starts when the host
  flips `isRunning` (difficulty is derived from `session.remaining`).
- Must never trap the player: if it throws, the scene's error boundary still lets the player exit.

## Architecture
- **One `Ticker`** (`createTicker`) → `_onTick` computes `dt`, advances flowers / bee / hazards /
  FX, then a single `setState`. The widget tree is just `LayoutBuilder → GestureDetector →
  CustomPaint` — no per-frame setState over a large tree. All visuals live in `_PollinationPainter`.
- Flowers are stored in **fractional coordinates** so they survive canvas resizes.
- FX reuse the shared `fx.dart` kit (`FxParticle`/`FxBurst`/`FxPop`, `GameFx.orb/atmosphere/text`).

## Tunable constants
All feel constants are a single banner block at the top of `pollination_game.dart` (bee steering,
flower lifecycle, combo, hazards). Tune there; game logic reads them.

## Key invariants (don't break these)
- **Pollination requires travel:** `_lastFlowerId` gates scoring so you must visit a *different*
  flower than the one just touched. This is the educational core — preserve it.
- **Same-species cross only:** you pollinate only when carried `_pollenType == flower.type`;
  otherwise you load that flower's pollen. Keep the load-vs-pollinate branch intact.
- Difficulty must come from the host clock (`_diff`), not a private timer, so the ramp matches the
  60 s round and pauses correctly outside play.

## Known TODOs / ideas
- Audio hooks (project is visual-first; none wired).
- Optional: a "super-pollinator" pickup, or bonus fruit for clearing a full same-species patch.
- Playtest `humanMax`/`starThresholds` and the wilt window — first-pass values only.

## Assets
- Canvas-drawn / procedural ONLY (bee sprite, flowers, fruit, pesticide clouds, gust streaks,
  particle bursts). No PNG/JPEG.

## EXACT registry spec (paste into `mini_game_registry.dart`, do not edit it from here)
```dart
import 'farm_system/pollination/pollination_game.dart';

MiniGameSpec(
  id: 'pollination',
  name: 'Pollination Dash',
  scale: BioScale.farmSystem,
  tagline: 'Carry pollen flower to flower before the blooms wilt',
  rules: [
    'Drag to steer the bee — it flies toward your finger.',
    'Touch a flower to pick up its pollen.',
    'Touch ANOTHER flower of the same color to pollinate it and set fruit.',
    'Chain same-color flowers for a combo; dodge pesticide clouds and wind.',
  ],
  howToWin: 'Most fruit set when time runs out wins.',
  durationSeconds: 60,
  scoreUnit: 'fruit set',
  enabled: true,
  accent: const Color(0xFFEF5DA8),
  icon: Icons.local_florist,
  builder: (context, session) => PollinationGame(session: session),
  humanMax: 2000,
  starThresholds: const [500, 1000, 1600],
),
```
