# AGENT.md — Bonds

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/financial/bonds/`
  - Game code: `bonds_game.dart` (`BondsGame` / `_BondsGameState` + its private painters)
  - Docs: `GAME.md`, `EDUCATION.md`, `AGENT.md`, `POTATUHS.md`
- **Read-only (do NOT modify without explicit escalation):**
  - `lib/games/mini_game.dart` (`MiniGameSession` contract)
  - `lib/games/fx.dart` (`GameFx`, `FxParticle`, `FxBurst`, `FxPop`)
  - `lib/theme/potatuhs.dart` (fonts, palette)
- **Do NOT touch** `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`, the sibling
  `financial/market_trader/`, or any other game. Registry/catalog wiring is the orchestrator's job.

---

## Session / host contract (the S in GAMES)

- The **host owns the clock, countdown, score display, and results screen.** This widget renders ONLY the
  play area.
- The sim loop (`_tick`) **returns early unless `widget.session.isRunning`**, so before the round it sits
  in a calm ready state and auto-starts the instant the host flips to playing. Do not add an internal
  timer, game-over screen, or restart button — that would break session re-entry.
- Score is reported with `session.addScore(delta)` via `_syncScore()` (pushes the realized-P&L delta).
  `session` clamps at ≥ 0 and is monotonic.
- `session.noteStreak(_streak)` is called on each profitable sell; a losing sell resets `_streak`.
- Duration is **60s** — keep `_kGameSeconds` in sync with the spec's `durationSeconds`.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/financial/bonds/bonds_game.dart` → `BondsGame` |
| Canonical spec | `lib/games/financial/bonds/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/financial/bonds/EDUCATION.md` |
| POTATUHS lens | `lib/games/financial/bonds/POTATUHS.md` |

---

## How the core works (don't break the inverse)

- A bond's price is **derived**, never stored: `_price(bondDef, ratePct)` is an iterative present-value
  loop (coupons + face discounted at the live rate). The chart painter recomputes the price line from the
  rate history with the same formula. **This is what guarantees price moves inversely to rate.** Do not
  cache prices or feed the price line from a separate random walk — that would sever the lesson.
- The `rate +1% ⇒ −X%` row gauge is `_sensitivity` — keep it; it's the visible duration teach.

---

## Tunable constants (current values — in `bonds_game.dart`)

| Constant / field | Value | Tune for |
|---|---|---|
| `_kStartCash` | `2000.0` | Starting capital; raise to allow bigger positions. |
| `_kRateStart / _kRateMin / _kRateMax` | `5.0 / 1.5 / 12.0` | Rate band (%). Wider band = bigger price swings. |
| `_kBonds` | 2Y/5Y/10Y/30Y, coupons + `unlockAt` | The maturity ladder. Add/retune carefully — longer = more sensitive. |
| Escalation (in `_tick`) | `interval 4.5→2.0s`, `swing ±1.0→3.6%`, `approach 0.5→1.3` | Difficulty ramp over the 60s. |
| `_kLotPresets` | `[1, 5]` | One-tap size buttons. |
| `_kChartMax` | `110` | Rate-history samples (chart length / memory). |

---

## Tuning levers for `humanMax` / `starThresholds`

Score is realized profit in whole dollars on $2000 starting cash. The realistic skilled-human ceiling in
60s (calibrated to `market_trader`'s family) is ~**600**. Registry ships `humanMax: 600`,
`starThresholds: [180, 380, 600]`. Re-tune by playtest if the rate volatility or starting cash changes.

---

## Known TODOs / ideas (not bugs)

1. **[IDEA] Shared online rate.** Like `market_trader`'s event seam, the rate engine could later be driven
   by a server so all players trade the *same* rate environment (Firebase online mode). Keep the rate
   engine isolated in `_tick` so the source can be swapped.
2. **[IDEA] Yield-curve view.** A small inset plotting price-vs-maturity at the current rate would make the
   duration ladder even more legible. Optional polish, not required.
3. **[INFO] Long-only by design.** No shorting; you profit by buying low / selling high like the sibling.
   Adding shorts would teach more but complicates the UI — escalate before attempting.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG/JPEG/raster. Rendering uses `GameFx.atmosphere` (background),
gradient/`Path` line strokes (chart), and `FxBurst` / `FxPop` (juice). Brand fonts/colours come from
`Potatuhs`.
