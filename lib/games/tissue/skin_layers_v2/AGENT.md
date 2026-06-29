# Skin Layers v2 — AGENT.md

You are the dedicated agent for the **Skin Layers v2** mini-game
(`lib/games/tissue/skin_layers_v2/skin_layers_v2_game.dart`). You own this game's
correctness, balance, and educational integrity. Do not touch other games, the
registry, the catalog, or the host — coordinate registry/catalog edits through
the orchestrator.

## What the game is
A tissue-scale, **real-time** skin-renewal game. Layer tiles dock one at a time
on a draining tempo bar; the player drags each into the band at its correct
depth (surface on top → deep at the bottom). Correct placements accelerate the
cadence; a fading glow hint teaches the order; completing a column triggers a
non-blocking "comes alive" flash and seeds a deeper column. It is the UX-pass
alternative to the static `skin_layers` memory sort: same lesson, real pace, a
climax, and fair scoring.

## Why it exists (the UX brief it answers)
The v1 teardown flagged: a static knowledge-gated sort with no accelerating arc
and a forced 1.6s celebration freeze between sections. v2 must keep:
- a **flowing/accelerating** mechanic (tempo bar + shrinking dock time),
- the **in-mechanic teaching** (glow hint that fades with streak),
- **split gestures** (drag to place, tap = read role only — never overload),
- a **non-blocking** come-alive (FX flash, instant reseed).
Do not regress any of these back toward the static design.

## Hard constraints (do not break)
- **Self-contained module.** Imports ONLY: `dart:math`, `package:flutter/*`,
  `../../mini_game.dart`, `../../fx.dart`. The layer catalog is an inlined copy —
  never import the v1 module or any other game.
- **Host owns the clock.** Render only the play area. Gate gameplay on
  `widget.session.isRunning`. Report via `session.addScore` /
  `session.noteStreak`. Never draw a timer/score/results.
- **Performance.** One `AnimationController` ticker → one `CustomPainter`. No
  per-frame `setState`; discrete events mutate fields and the always-running
  ticker repaints. Drag mutates `_dragPos` only.
- **Class signature is load-bearing.** `class SkinLayersV2Game extends
  StatefulWidget { final MiniGameSession session; const
  SkinLayersV2Game({super.key, required this.session}); }` — the registry builder
  depends on it.

## Educational contract (the E in GAMES)
Every layer's `role` string is the lesson, and depth order is biologically
correct (dead barrier on top, dividing cells below, fat deepest). Within any
composed column, **depths must stay unique** so each tile has exactly one correct
band — `_composeColumn` guarantees this; preserve it if you add layers.

## Where to tune
- `_composeColumn` — column length ramp and which structures appear.
- `_dockNext` — the tempo ramp (`2.6 - placed*0.045`, floor `0.85`).
- `_resolveDrop` / `_completeColumn` — scoring and streak rules.
- `_drawHint` — the teaching-hint fade curve.
- `MiniGameSpec` (in the registry) — `humanMax`, `starThresholds`,
  `durationSeconds`. Re-tune by playtest, not by guess.

## Verify before declaring done
`flutter analyze lib/games/tissue/skin_layers_v2/` → ZERO issues.
