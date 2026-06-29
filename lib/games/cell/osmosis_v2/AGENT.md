# AGENT.md — Osmosis v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/cell/osmosis_v2/` — the widget
  (`osmosis_v2_game.dart` → `OsmosisV2Game` / `_OsmosisV2GameState` / `_OsmosisV2Painter`) and these
  docs (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`, `FxParticle`, `FxBurst`, `FxPop`), `lib/theme/potatuhs.dart`. No edits without escalation.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or `mini_game_page.dart`. (The orchestrator wires the registry/catalog.)

---

## Why this game exists

It is the **UX-refined alternative** to `osmosis`, built to the teardown brief in
`docs/ux_pass/teardowns/osmosis.md`. It ships **alongside** the original (coexist-then-judge). The
original's failures it fixes: invisible whole-screen slider, two-stage tonicity→volume indirection,
uncapped runaway scoring, and no climax. Do **not** regress those: keep the explicit deck, the
one-value knob = tonicity, the capped multiplier, and the final surge.

---

## Dependency rule (from EXTRACTION_RECIPE.md)

Imports **only** `dart:math`, `package:flutter/material.dart`, `package:flutter/scheduler.dart`,
`../../mini_game.dart`, `../../fx.dart`, and `../../../theme/potatuhs.dart`. No external symbols, no
dependency on any other game. Keep it that way — isolation over DRY.

---

## Scene / exit contract

- `OsmosisV2Game` takes a `MiniGameSession` and is fully host-driven.
- `widget.session.isRunning` gates the simulation. When false the game shows a calm ready state and
  settles the cell to firm turgor; it auto-runs when the host flips `isRunning`.
- One end flourish fires the first frame `session.phase == finished` (STABILIZED / RUPTURED).
- Scores via `widget.session.addScore(n)`; streak high-water via `widget.session.noteStreak(...)`.
- The host owns the 60 s clock, countdown, score HUD, opponents and results. The game renders only
  the play area and never builds a results/restart screen. If it throws, the host error boundary
  catches it — never swallow exceptions.

---

## Performance contract

- **One `Ticker` → one `setState({})` → one `CustomPaint`.** No per-frame setState over a widget
  tree; the build is a single `GestureDetector` wrapping one `CustomPaint`.
- `dt` clamped to `0.05 s` so a stutter can't teleport the sim.
- Painter is a handful of paths/circles + `GameFx.atmosphere` + the solute dots. No raster assets,
  no extra tickers, no nested `CustomPaint`s.

---

## Tunable constants (top-of-file in `osmosis_v2_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kBandMin` / `_kBandMax` | 0.34 / 0.66 | Safe turgor band width. Widen = easier. |
| `_kFlux` | 0.55 | Osmosis strength / immediacy. Lower = laggier (don't reintroduce the old murk). |
| `_kLyseAt` / `_kCrenateAt` | 0.97 / 0.03 | Burst / shrivel thresholds. |
| `_kIsoTol` | 0.14 | Green isotonic zone half-width (also the flux deadband). |
| `_kBasePerSec` | 10.0 | In-band score base rate. |
| `_kMultGain` / `_kMultMax` | 0.45 / 3.0 | Combo growth / cap. Cap keeps standings legible. |
| `_kRecoveryBonus` | 15 | Bounded re-entry bonus. |
| `_kDriftRangeBase` / `_kDriftRangeGain` | 0.40 / 0.70 | Drift push strength early → late. |
| `_kRetargetBase` / `_kRetargetGain` | 2.2 / 1.4 | Seconds between drift re-rolls early → late. |
| `_kSurgeAt` | 10.0 | Seconds-remaining the FINAL SURGE begins. |
| `_kSurgeDriftMul` / `_kSurgeScoreMul` | 1.6 / 2.0 | Surge drift escalation / point multiplier. |

---

## Known TODOs

1. **[LOW] Star thresholds are a first estimate** (`[400, 900, 1500]`, `humanMax 1500`). Re-tune
   from playtests — a clean run parked green most of the round, with the surge ×2, should ~3-star.
2. **[LOW] Drop-and-resume not persisted** — `_volume`/`_knob` reset on mount.
3. **[INFO] `shouldRepaint` returns true** — correct; fresh fields every ticked frame.

---

## Canvas-only rule

All rendering is `CustomPainter` via `GameFx` + raw `Canvas`. **No PNG/JPEG/raster assets.** The
painter draws: tinted solution field + solute dots, the fused safe ring, flux arrows, the
crenating/swelling **potato** cell, the state caption, the explicit BALANCE deck (track + green
zone + big knob), the onboarding ghost hand, the capped multiplier chip, the FINAL SURGE vignette,
event callouts, and `FxBurst`/`FxPop` juice.
