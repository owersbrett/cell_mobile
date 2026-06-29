# AGENT.md — Cell Type v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/cell/cell_type_v2/` — the widget
  (`cell_type_v2_game.dart` → `CellTypeV2Game` / `_CellTypeV2GameState` / `_StagePainter`) and these
  docs (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`, `FxParticle`, `FxBurst`, `FxPop`), `lib/theme/potatuhs.dart`. No edits without escalation.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or `mini_game_page.dart`. (The orchestrator wires the registry/catalog.)

---

## Why this game exists

It is the **UX-refined alternative** to `cell_type`, built to the teardown brief in
`docs/ux_pass/teardowns/cell_type.md`. It ships **alongside** the original (coexist-then-judge). The
original's failures it fixes:

1. **The mandatory 1.9 s fact flare gated every answer** → removed entirely. Tap confirms instantly;
   the next specimen loads the same frame; feedback is non-blocking. Do **not** reintroduce a gate.
2. **Unbounded streak multiplier (runaway leader)** → capped `×3`. Do **not** uncap it.
3. **No second skill axis beyond recall+speed** → the BONUS RING / read-multiplier (calibrated
   confidence: snap the hazy cell vs wait). Keep it visible and keep it the main scoring swing.
4. **First-timers fly blind** → the persistent on-screen LEGEND (decision tree). Keep it.
5. **No climax** → FINAL CELLS surge. Keep it.

The **education is preserved verbatim**: the procedural organelles, the tell-degradation by progress,
and the `_kFacts`. Don't drop the biology to chase feel.

---

## Dependency rule (from EXTRACTION_RECIPE.md)

Imports **only** `dart:math`, `package:flutter/material.dart`, `package:flutter/scheduler.dart`,
`../../mini_game.dart`, `../../fx.dart`, and `../../../theme/potatuhs.dart`. No external symbols, no
dependency on any other game. Keep it that way — isolation over DRY.

---

## Scene / exit contract

- `CellTypeV2Game` takes a `MiniGameSession` and is fully host-driven.
- `widget.session.isRunning` gates the simulation. When false it shows a calm, fully-resolved ready
  specimen; it auto-runs (resets streak + loads a hazy cell) when the host flips `isRunning`.
- One end flourish fires the first frame `session.phase == finished` (TIME! + gold burst).
- Scores via `widget.session.addScore(n)`; streak high-water via `widget.session.noteStreak(...)`.
  It never calls `endEarly`.
- The host owns the 60 s clock, countdown, score HUD, opponents and results. The game renders only
  the play area (and never builds a results/restart screen). If it throws, the host error boundary
  catches it — never swallow exceptions.

---

## Performance contract

- **One `Ticker` → one `CustomPainter` (via a `_Repaint` notifier) → NO per-frame `setState`.** The
  build is a single `GestureDetector` wrapping one `CustomPaint` under a `RepaintBoundary`; the
  painter repaints off the `repaint` pump reading live state. Taps mutate fields; the next ticked
  frame shows them. This is *stricter* than the per-frame-`setState` sibling games.
- `dt` clamped to `0.05 s` so a stutter can't teleport the sim.
- The "out of focus" look is faked with detail-alpha gating + a single small blur disk over the cell
  — **not** a whole-cell blur layer every frame. Don't swap it for a `saveLayer` blur.
- The four choice buttons are **drawn in the painter** and hit-tested by `_choiceRect` in the state
  (same geometry helper) — no widget-tree buttons rebuilding per frame.

---

## Tunable constants (top-of-file)

| Constant | Value | Tune for |
|---|---|---|
| `_kBase` | 60 | Base points per correct read. |
| `_kReadMax` / `_kReadMin` | 1.8 / 1.0 | Read bonus at focus 0 (snap) → focus 1 (crisp). |
| `_kStreakStep` | 3 | Correct-in-a-row per `+1×`. |
| `_kMultMax` | 3 | Streak multiplier CAP. **Keep capped** (anti-runaway). |
| `_kFocusStart` / `_kFocusEnd` | 1.5 / 0.9 | Seconds to fully resolve, early → late round. |
| `_kSurgeAt` | 8.0 | Seconds-remaining the FINAL CELLS climax begins. |
| `_kSurgeFocusMul` | 0.7 | Resolve-faster factor in the surge. |
| `_kSurgeScoreMul` | 2.0 | Surge point multiplier. |

---

## Known TODOs

1. **[LOW] Star thresholds are a first estimate** (`[700, 1400, 2200]`, `humanMax 2200`). Re-tune from
   playtests — a clean run that snaps most reads in the gold band and rides the surge ×2 should
   ~3-star.
2. **[LOW] Drop-and-resume not persisted** — streak/focus reset on mount.
3. **[INFO] `shouldRepaint` returns false** — correct; the painter repaints via the `_Repaint`
   listenable, not via delegate diffing.

---

## Canvas-only rule

All rendering is `CustomPainter` via `GameFx` + raw `Canvas`. **No PNG/JPEG/raster assets.** The
painter draws: `GameFx.atmosphere`, the resolving procedural cell (plant box+chloroplasts, fungal
chitin blob, animal membrane+mitochondria, bacterial capsule+nucleoid), the shrinking BONUS RING +
live read multiplier, the persistent LEGEND, the four canvas choice buttons, the non-blocking toast,
the streak chip, the FINAL CELLS vignette + banner, and `FxBurst`/`FxPop` juice.
