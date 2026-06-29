# AGENT.md — Nutrient Cycle v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/ecosystem/nutrient_cycle_v2/` — the widget
  (`nutrient_cycle_v2_game.dart` → `NutrientCycleV2Game` / `_NutrientCycleV2GameState` /
  `_NutrientCycleV2Painter`) and these docs (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`, `FxParticle`, `FxBurst`), `lib/theme/potatuhs.dart`. No edits without escalation.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or `mini_game_page.dart`. (The orchestrator wires the registry/catalog.)

---

## Why this game exists

It is the **UX-refined alternative** to `nutrient_cycle`, built to the teardown brief in
`docs/ux_pass/teardowns/nutrient_cycle.md`. It ships **alongside** the original (coexist-then-judge).
The original's failures it fixes:

1. **Low skill ceiling on three fixed maps** → the ring is re-laid-out each cycle (random rotation +
   random start), and the real game is now **energy routing + demand delivery + combo management**,
   not recall of `_kCarbon/_kWater/_kNitrogen` spatial layouts.
2. **Low-stakes core action** (`+1` per tap) → each transfer scores `×combo` (`1→5`), a dead-end or
   stall **wipes** the combo, deliveries pay `6×combo`, loops `4×combo`. Every tap carries weight.
3. **Concept needed reading** → energy now **visibly leaks** as heat motes every step (one way) and
   re-enters **only** at the gold ☀ sun-driven process — the matter-vs-energy asymmetry is *seen*,
   not read off a label.

Plus a real **climax** (FINAL BLOOM, last 12 s: ×2 points, faster leak, single-loop cycle flips).

Do **not** regress these. Preserve: the three real cycles with verbatim process names, the
conserved-atom-on-a-closed-loop LOOP bonus, and the energy meter as a felt threat.

---

## Dependency rule (from EXTRACTION_RECIPE.md)

Imports **only** `dart:math`, `package:flutter/material.dart`, `package:flutter/scheduler.dart`,
`../../mini_game.dart`, `../../fx.dart`, and `../../../theme/potatuhs.dart`. No external symbols, no
dependency on any other game. Keep it that way — isolation over DRY.

---

## Scene / exit contract

- `NutrientCycleV2Game` takes a `MiniGameSession` and is fully host-driven.
- `widget.session.isRunning` gates the simulation. When false the game shows a calm ready state and
  auto-routes the atom as a living preview; it starts the run when the host flips `isRunning`.
- One end flourish fires the first frame `session.phase == finished` (CYCLE SUSTAINED / COLLAPSED).
- Scores via `widget.session.addScore(n)`; combo high-water via `widget.session.noteStreak(...)`.
- Climax reads the host's `session.remaining` clock (≤ 12 s). The game renders only the play area and
  never builds a results/restart screen. If it throws, the host error boundary catches it — never
  swallow exceptions.

---

## Performance contract

- **One `Ticker` → one `setState({})` → one `CustomPaint`.** The build is a single `GestureDetector`
  wrapping one `CustomPaint`.
- `dt` clamped to `0.05 s` so a stutter can't teleport the sim.
- Painter is a handful of lines/circles/paths + `GameFx.atmosphere` + the node orbs + heat motes. No
  raster assets, no extra tickers, no nested `CustomPaint`s.

---

## Tunable constants (top-of-file in `nutrient_cycle_v2_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kComboMax` | 5 | Combo ceiling. Cap keeps party standings legible (no runaway). |
| `_kLoopBonus` / `_kDemandBonus` | 4 / 6 | Loop / delivery payout (× combo). |
| `_kLeakBase` / `_kLeakRamp` | 0.085 / 0.060 | Energy lost per transfer, early → late. Higher = tenser. |
| `_kPassiveLeak` | 0.018 | Ambient energy drain/sec (discourages camping). |
| `_kSolarGain` | 0.55 | Energy regained on the ☀ process. Sustains ~6 steps. |
| `_kDeadEndLeak` | 0.13 | Energy cost of a dead-end tap. |
| `_kStallFloor` | 0.34 | Energy after a full stall. |
| `_kLoopsPerCycle` | 2 | Loops before the element switches (forced to 1 in climax). |
| `_kClimaxAt` | 12.0 | Seconds-remaining the FINAL BLOOM begins. |
| `_kClimaxLeakMul` / `_kClimaxScoreMul` | 1.5 / 2 | Bloom leak escalation / point multiplier. |
| `_kDemandEvery` | 4.5 | Seconds a demand stays before re-rolling. |

---

## Known TODOs

1. **[LOW] Star thresholds are a first estimate** (`[35, 70, 110]`, `humanMax 120`). Re-tune from
   playtests — a clean run that keeps energy topped, banks ×5 and rides the bloom ×2 should ~3-star.
2. **[LOW] Drop-and-resume not persisted** — atom/energy/combo reset on a fresh run.
3. **[INFO] `shouldRepaint` returns true** — correct; fresh fields every ticked frame.

---

## Canvas-only rule

All rendering is `CustomPainter` via `GameFx` + raw `Canvas`. **No PNG/JPEG/raster assets.** The
painter draws: the atmosphere field, the energy meter, the header, the process edges (current options
named; the ☀ sun edge gold), the reservoir orbs (current / reachable / gold DEMAND ring), the
travelling atom with its energy aura, the heat motes, event callouts, the FINAL BLOOM vignette, and
the combo/loops footer.
