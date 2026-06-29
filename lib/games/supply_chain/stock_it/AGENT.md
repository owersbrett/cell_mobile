# AGENT.md — Stock It Right

> Context for an AI agent working on THIS game. Read this and GAME.md (and EDUCATION.md for the
> supply-chain theory) first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/supply_chain/stock_it/`
  - `stock_it_game.dart` (`StockItGame` / `_StockItGameState` / `_StockChartPainter` + the value type
    `_DayPoint`)
  - The docs in this folder: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`,
  `lib/games/EXTRACTION_RECIPE.md`. Read as needed; **no edits**.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`, or
  `mini_game_host.dart`. The orchestrator wires those.

---

## Scene / exit contract

- `StockItGame` takes a `MiniGameSession`.
- `widget.session.isRunning` gates the loop — days only advance while playing; the first day auto-starts
  when it flips true. Before play, a calm READY overlay shows (no day advance, no scoring).
- Score reaches the host **only** via `widget.session.addScore(n)` (we mirror running profit each day with
  a signed delta, exactly like `market_trader`'s `_syncScore`); the streak via
  `widget.session.noteStreak(streak)`. The host owns the timer, the 3·2·1 countdown, the results screen
  and the exit. This game has **no** results screen and **never** calls `endEarly`.
- If the game throws, the host's error boundary shows an exit fallback — never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/supply_chain/stock_it/stock_it_game.dart` → `StockItGame` |
| Canonical spec | `GAME.md` (rules live here — edit first, then code) |
| Education | `EDUCATION.md` (inventory / lead time / safety stock / bullwhip) |
| POTATUHS lens | `POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` (out of scope — orchestrator only) |

---

## Tunable constants (top of `stock_it_game.dart`)

| Constant | Value | Tune it for |
|---|---|---|
| `_kDayLenStart` / `_kDayLenEnd` | 1.8 → 1.15 s | Day tempo; how many decisions fit in 60 s (~37 days). |
| `_kStartStock` | 30 | Opening shelf — should sit inside the early healthy band. |
| `_kPrice` | 12.0 | Revenue per potato sold (the score engine). |
| `_kHoldingCost` | 0.6 | Daily cost per potato above the free buffer — the overstock punisher. |
| `_kHoldFree` | 10 | Free-to-hold buffer (no holding fee below it). Raise to forgive small overstock. |
| `_kStockoutPenalty` | 16.0 | Penalty per unmet unit. Keep **above** `_kPrice` so stockouts hurt more than a lost sale. |
| `_kBaseDemand` | 9.0 | Opening demand level. |
| `_kPipelineSlots` | 7 | Pipeline depth — MUST exceed the max lead time (5). |
| `_kWobbleWin` | 10 | Window for the bullwhip amplification meter. |
| lead-time ramp | 3 / 4 / 5 (day < 14 / < 26 / else) | When orders take longer (in `_advanceDay`). |
| demand swing | `2 + 4·(day/34)` | How violent regime shifts get late (in `_advanceDay`). |

`humanMax` and `starThresholds` live in the registry spec, not here — flag changes for the orchestrator.

---

## Design invariants (do not break)

1. **The delay is the game.** An order NEVER fills instantly — it always enters `_pipeline[_leadTime]` and
   shifts forward one slot per day. Do not add an instant-restock button; it deletes the lesson.
2. **Demand has a LEVEL plus noise.** Daily demand = a slowly-drifting `_demandLevel` (regime shifts) plus
   small `±2` noise. The whole point is "read the level, ignore the noise." Keep that separation — don't
   make every day a fresh random draw with no underlying trend.
3. **Two-sided cost.** Stockout penalty AND holding cost must both bite. If you only punish stockouts,
   players hoard and the bullwhip never appears; if you only punish overstock, they starve the shelf.
4. **The bullwhip meter is honest.** It is literally `std(orders)/std(demand)` over the window — never
   fudge it. It's the on-screen proof that overreaction amplifies. Keep it visible.
5. **Score = realized profit, clamped at 0 by the session.** Sync with a signed delta to the running
   `_profit` (don't re-add gross each day).

---

## Performance rule (the "black screen / jitter" bug class)

- Continuous motion (atmosphere, day sweep, the stock/demand chart, FX pops) is **one `CustomPainter`**
  (`_StockChartPainter`) repainted off the single `AnimationController`, inside a `RepaintBoundary`.
- **No per-frame `setState`.** `_onTick` only mutates FX decay + the day clock; it calls `setState` ONLY
  on a day boundary (via `_advanceDay`) and control taps. Keep live HUD numbers as canvas text or
  day-boundary rebuilds — do not lift per-frame values into the widget tree.
- Dispose the controller (already done in `dispose`).
- **Layout coupling:** the painter's chart `top`/`chartH` mirror the `SizedBox` reserved in `build()`. If
  you change the column layout, update both so the chart lands in its reserved gap.

---

## Known TODOs / ideas (not blocking)

1. **[LOW] Forecast hint.** A faint "order ≈ level" ghost on the ORDER button when stock+incoming is below
   target would coach the safety-stock idea without auto-playing.
2. **[LOW] Backlog mode.** Real Beer Game *backorders* unmet demand instead of losing it — a harder
   variant where stockouts must be filled later. Currently lost-sales (simpler).
3. **[LOW] Multi-echelon.** The true bullwhip emerges across a CHAIN (retailer→wholesaler→factory). A
   future version could add an upstream node you also order from. Out of scope for the 60 s solo cut.

---

## Canvas-only rule

All chart/FX rendering is `CustomPainter`. **No PNG/JPEG/raster assets.** The painter draws: the
atmosphere, the chart panel, the shaded healthy band, the stockout (zero) line, the faint demand line, the
glowing stock line (coloured by zone), the tip dot, the BULLWHIP meter box, and the feedback pops/flash.
The only raster-free icons are Material `Icons.*` in the pipeline chips and ready card.
