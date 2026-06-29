# AGENT.md — Portfolio

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/financial/portfolio/portfolio_game.dart` (`PortfolioGame`)
  - Game docs: `lib/games/financial/portfolio/` (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md)
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`,
  `lib/games/mini_game.dart` — read as needed, **no edits**.
- **Do not touch** other games, other scales, the registry/catalog/host, or `mini_game_page.dart`.
  The `MiniGameSpec` for this game (id `portfolio`) is registered by the host owner — propose changes,
  don't make them here.

---

## Scene / exit contract

- `PortfolioGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, countdown, results screen, and exit affordance. The game must **not**
  reimplement or intercept these. It renders ONLY the play area.
- `widget.session.isRunning` gates the sim. `_tick` advances transient FX always (so the ready state
  feels alive) but only advances the market/score when `isRunning` is true. Respect this.
- Report score via `widget.session.addScore(delta)` and streak via `widget.session.noteStreak(n)`.
  Never draw your own clock or score counter — the host shows them.
- If the game throws, the host's error boundary shows an exit fallback. Don't swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/financial/portfolio/portfolio_game.dart` → `PortfolioGame` |
| Canonical spec | `lib/games/financial/portfolio/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/financial/portfolio/EDUCATION.md` |
| POTATUHS lens | `lib/games/financial/portfolio/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.financial` (owned by host) |

---

## Architecture (how it ticks)

- **One `AnimationController`** (`_ctrl`, 1-hour duration, `..forward()`) is both the sim clock
  (`addListener(_tick)`) and the repaint source for all three painters (`super(repaint: s._ctrl)`).
- **No per-frame `setState`.** Painters read mutable state fields directly each frame and repaint off
  the ticker; `shouldRepaint` returns `false`. The widget tree rebuilds ONLY on allocation taps.
  Keep it that way — do not move live values into per-frame `setState`.
- **Continuous rebalancing:** weights are the allocation; `_value *= (1 + Σ wᵢ·rᵢ)` each tick. Weight
  bars are static between taps (clean, no drift bookkeeping).

---

## Tunable constants (current values — all top of file)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kStartValue` | 1000.0 | Opening capital and chart baseline. |
| `_kStockVol` | 0.95 | Per-second stock volatility. Raise for wilder single-stock swings. |
| `_kEtfVol` | 0.30 | Per-second ETF volatility. The smaller vs `_kStockVol`, the clearer the smoothing. |
| `_kDriftMin / _kDriftMax` | −0.014 / 0.024 | Per-second drift band stocks reshuffle within. Negative floor = some stocks bleed (picking wrong loses). |
| `_kReshuffle` | 7.0 | Seconds between drift reshuffles (stops "pick the one winner"). |
| `_kShockFirst` | 6.0 | Delay to the first shock. |
| `_kShockIntEarly / _kShockIntLate` | 7.5 / 3.2 | Shock interval at ramp 0 → 1. |
| `_kShockDur` | 1.4 | Seconds a shock plays out over. |
| `_kCrashMin / _kCrashMax` | 0.50 / 0.82 | Sector crash depth (fraction) early → late. |
| `_kRallyChance` | 0.22 | Chance a shock is a moonshot rally instead of a crash. |
| `_kCorrelateRamp` | 0.55 | Ramp past which crashes can pair two correlated sectors. |
| `_kSurviveDraw` | 0.10 | Drawdown under which a crash counts as "weathered" (streak award). |
| `_kChunk` | 0.12 | Weight shifted by one + / − tap. |

---

## Known TODOs / ideas (in priority order)

1. **[MEDIUM] Star thresholds are first-pass.** `humanMax`/`starThresholds` in the spec are
   reasoned, not playtested. Tune against real runs: confirm a diversified player reliably clears
   1★, a sharp one clears 2★, and 3★ demands well-timed allocation.
2. **[LOW] Correlated-crash readability.** The correlated-crash banner names both tickers, but the
   second crash isn't separately flashed. Consider a distinct visual so players learn the
   "correlation" concept explicitly, not just feel it.
3. **[LOW] No live unrealized split.** The market strip shows per-asset % change; it does not show
   each holding's $ contribution to your book. Could add a thin contribution overlay on the weight bar.
4. **[IDEA] Online/disruption seam.** Like Market Trader, the shock source is factored
   (`_spawnShock` / `_shocks`). A future shared-market mode could let one player's crash hit a rival's
   concentrated book. Keep `_Shock` injectable from an external source.

---

## Canvas-only rule

All rendering is `CustomPainter` (background atmosphere, HUD/chart, FX) plus a small static widget
control panel. **No PNG/JPEG/raster assets.** Chart lines, the diversification gauge, the market strip,
banners, and pops are all drawn procedurally. Keep it that way.
