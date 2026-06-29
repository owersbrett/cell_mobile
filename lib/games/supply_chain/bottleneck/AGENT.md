# AGENT.md — Bottleneck

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/supply_chain/bottleneck/`
  - Game code: `bottleneck_game.dart` (`BottleneckGame` / `_BottleneckGameState` / `_BottleneckPainter`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`. Read as needed,
  **no edits.**
- **Do NOT touch** other games, other scales, or any shared/registry file:
  `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`. The orchestrator wires those.
- **Do NOT import another game's code.** Self-contained module (EXTRACTION_RECIPE.md dependency rule):
  only `dart:math`, `package:flutter/*`, `../../mini_game.dart`, `../../../theme/potatuhs.dart`.

---

## Scene / exit contract

- `BottleneckGame` takes a `MiniGameSession`; the **host owns** the clock, 3-2-1 countdown, score HUD,
  results and exit. This widget renders **only the play area**.
- The sim loop (`_step`) runs **only when `widget.session.isRunning`**; otherwise `_idleDrift` shows a
  calm, non-scoring preview (auto-starts when `isRunning` flips true).
- Report through `widget.session.addScore(n)` (per shipped potato) and `widget.session.noteStreak(n)`
  (smooth-flow combo). **Never** draw a timer/score/results, and **never** call `endEarly` — there is
  no fail state here.
- One `Ticker`; everything advances off `dt`. `dispose()` kills it. Guards: `mounted` + `isRunning`.

---

## Files

| Role | Path |
|---|---|
| Game widget | `bottleneck_game.dart` → `BottleneckGame` |
| Canonical rules | `GAME.md` (edit first, then code) |
| Education write-up | `EDUCATION.md` |
| POTATUHS lens | `POTATUHS.md` |
| Registry entry | `mini_game_registry.dart` (OUTSIDE scope — flag changes, don't edit) |

---

## Tunable constants (top of `bottleneck_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kStages` | 5 | Number of stations on the line. |
| `_kBaseRate` | `[2.7, 2.2, 1.8, 2.3, 2.0]` | Per-stage base throughput (potatoes/s). Process is the natural slow link. |
| `_kBinCap` | 14 | Buffer size before a bin overflows → waste. |
| `_kInflowStart` / `_kInflowPeak` | 1.4 / 3.3 | Demand ramp into the Farm across the round. Raise peak = harder. |
| `_kBoostDuration` | 1.3 s | How long a boost lasts. |
| `_kBoostMult` | 2.5 | Rate multiplier while boosted. |
| `_kCooldown` | 1.7 s | Lockout after a boost ends. Raise = more triage pressure. |
| `_kBottleneckRatio` | 0.45 | Fill ratio that flags a bin as a bottleneck (drops with progress). |

Drift (where the bottleneck wanders): each `_Stage` carries `driftSpeed` + `driftPhase`; amplitude in
`_rateOf` grows with progress (`0.34 + 0.12 * p`) so late-round chokes are deeper and can double up.

---

## Performance notes (this game's bug-class: black screen / jitter)

- All rendering is in **one `CustomPainter`**; the widget tree is just `GestureDetector > CustomPaint`.
  HUD (throughput meter, labels, tags) is **drawn in-canvas**, not built as widgets — keep it that way
  so per-frame `setState` doesn't rebuild a big tree.
- No raster assets — everything is drawn (potatoes are ovals, station glyphs are `IconData` rendered
  via `TextPainter`).
- If you add particles/popups, cap their count and remove dead ones each tick (see `_popups`).

---

## Known TODOs / ideas (priority order)

1. **[MEDIUM] No audio hooks** — a soft "ship" tick and an overflow "splat" would sharpen feedback.
   Keep it host-compatible; don't add a dependency.
2. **[LOW] Boost is a flat tap** — consider a tiny hold-to-boost or a shared boost meter to add a
   resource-management layer (currently the constraint is only cooldown).
3. **[LOW] Bottleneck flag is fill-based** — it reads the *symptom* (a full bin), not the *cause* (the
   slowest rate). That's intentional (teaches reading the queue), but a "rate too low" subtle hint
   could help first-time players. Don't make it automatic — that removes the skill.
4. **[INFO] `shouldRepaint` returns true** — correct here; repaint is driven by per-frame `setState`,
   same pattern as `arcade/accelerator.dart`.
