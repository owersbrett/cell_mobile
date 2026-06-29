# AGENT.md — Nutrient Cycle

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/ecosystem/nutrient_cycle/`
  - Game code: `nutrient_cycle_game.dart` (`NutrientCycleGame` / `_NutrientCycleGameState` /
    `_NutrientCyclePainter`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`, `lib/games/mini_game.dart`.
  Read as needed, **no edits.**
- **Do NOT touch** other games, other scales, or any shared/registry file:
  `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`. The orchestrator wires those.
- **Do NOT import another game's code.** Self-contained module (EXTRACTION_RECIPE.md dependency rule):
  only `dart:math`, `package:flutter/*`, `../../fx.dart`, `../../mini_game.dart`,
  `../../../theme/potatuhs.dart`.

---

## Scene / exit contract

- `NutrientCycleGame` takes a `MiniGameSession`; the **host owns** the clock, 3-2-1 countdown, score
  HUD, results and exit. This widget renders **only the play area**.
- The scoring logic runs **only when `widget.session.isRunning`**; otherwise the atom auto-routes a calm,
  non-scoring preview of the loop (`_autoStep`). A false→true `isRunning` transition calls `_startRun()`
  (auto-start, no button).
- Report through `widget.session.addScore(1)` per valid transfer (+`_kLoopBonus` per closed loop) and
  `widget.session.noteStreak(n)`. **Never** draw a timer/score/results, and **never** call `endEarly` —
  there is no fail state here.
- One `Ticker`; everything advances off `dt`. `dispose()` kills it. Guards: `mounted` + `isRunning`.

---

## Files

| Role | Path |
|---|---|
| Game widget | `nutrient_cycle_game.dart` → `NutrientCycleGame` |
| Canonical rules | `GAME.md` (edit first, then code) |
| Education write-up | `EDUCATION.md` |
| POTATUHS lens | `POTATUHS.md` |
| Registry entry | `mini_game_registry.dart` (OUTSIDE scope — flag changes, don't edit) |

---

## Data model

- A `_Cycle` = element + symbol + color + `List<_Reservoir>` (ring nodes) + `List<_Edge>` (directed
  valid transfers, each named by its `process`). Three consts: `_kCarbon`, `_kWater`, `_kNitrogen`,
  collected in `_kCycles`.
- To add/edit a cycle: append reservoirs + edges; the ring layout (`_recomputeLayout`) adapts to any
  node count automatically. Keep each cycle a genuine closed loop (every node has a path back to start)
  or loop-completion can't fire.

## Tunable constants (top of `nutrient_cycle_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kTransferRun` | 0.20 s | Atom slide time during play. |
| `_kTransferIdle` | 0.75 s | Slower slide for the calm preview. |
| `_kIdlePause` | 0.35 s | Pause between preview auto-steps. |
| `_kLoopBonus` | 5 | Score for closing a full loop. |
| `_kFlowGain` | 0.42 | Flow restored per valid transfer. |
| `_kFlowDecayBase` / `_kFlowDecayRamp` | 0.075 / 0.20 | Flow lost/sec (base + ramps to end). Raise = harder. |
| `_kStallPenalty` | 0.20 | Flow lost on a dead-end tap. |
| `_kLoopsPerCycle` | 2 | Loops before the element switches. |

---

## Performance notes (this game's bug-class: black screen / jitter)

- All rendering is in **one `CustomPainter`**; the widget tree is just `GestureDetector > CustomPaint`.
  HUD (flow meter, labels, loop counter) is **drawn in-canvas**, not built as widgets — keep it that way
  so per-frame `setState` doesn't rebuild a big tree.
- No raster assets — reservoirs are `GameFx.orb`, glyphs are `IconData` via `TextPainter`, edges are
  lines + a small arrow path.
- Particles (`_fx`) and pops (`_pops`) are capped by their short lifetimes and removed each tick. Bursts
  are small (≤14). Don't add unbounded spawners.
- `GameFx.atmosphere` runs with `motes: 24` (down from default 36) to stay cheap on web.

---

## Known TODOs / ideas (priority order)

1. **[MEDIUM] Pre-game cycle pick** — the brief says the player "picks" carbon/nitrogen/water. Currently
   the round opens on carbon and *rotates* through all three as it accelerates. A ready-state element
   chooser is possible but must not fight the host's auto-start/countdown — keep it optional.
2. **[MEDIUM] Mixed cycles** — late-round could splice reservoirs from two elements into one ring for a
   harder "which process is this?" read. Today it switches whole elements; mixing is unbuilt.
3. **[LOW] No audio hooks** — a soft "transfer" tick and a richer "loop closed" chime would sharpen
   feedback. Keep it host-compatible; don't add a dependency.
4. **[LOW] Reachable-hint pulse** — newcomers can follow the pulse without reading the process labels.
   Intentional (keeps flow moving), but a difficulty toggle could hide it for mastery play.
5. **[INFO] `shouldRepaint` returns true** — correct here; repaint is driven by per-frame `setState`,
   same pattern as `supply_chain/bottleneck`.
