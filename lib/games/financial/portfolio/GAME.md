# GAME.md — Portfolio ("Don't Put All Your Eggs in One Basket")

> Canonical spec for the second Financial-scale game. The player runs a live $1,000 portfolio,
> splitting it across four volatile sector **stocks** and one steady **index ETF**, and learns —
> by feeling it — that **diversification lowers risk**.

- **Scale (cell):** financial
- **Game id:** `portfolio` (widget `PortfolioGame` in
  `lib/games/financial/portfolio/portfolio_game.dart`)
- **Role:** host-integrated mini-game. Score = **portfolio value** (dollars → points), synced to the
  host session via `session.addScore` on every change. The host (`MiniGameHost`) owns the
  clock/countdown/results; this widget renders only the play area and runs the sim while
  `session.isRunning`.

## The lesson this teaches
One stock can double — or get cut in half by a single bad day. A basket of many can't double as fast,
but it can't be wiped either. **Spreading a fixed budget across uncorrelated holdings lowers the
swing without giving up the climb.** The game makes that trade-off tactile: you watch your line ride
between a wild single-stock line and a smooth basket line, and you choose where on that spectrum to sit
as the shocks get bigger.

## The market (what's moving)
Five tradeable positions:
- **FRYZ** (Fast Food), **CHIPZ** (Snacks), **SPUD** (Farming), **MASH** (Industrial) — four volatile
  sector stocks. High volatility, drifts that **reshuffle every ~7s** so no single stock is permanently
  "the winner" (you can't just pick one and coast).
- **TUBR** (Index ETF) — the diversified basket. Gentle drift, **~1/3 the volatility** of a single
  stock, and it absorbs only ~1/4 of any single sector's crash. One-tap diversification.

The portfolio is **continuously rebalanced** to the weights you set, so the weights you choose ARE your
allocation — no drift-away bookkeeping. Portfolio return each tick = Σ(weightᵢ × returnᵢ); value
compounds it.

## Allocation (the agency)
- Every asset row has a **weight bar**, a live **%**, and **− / +** buttons. **+** shifts 12% of the
  book into that asset (pulled proportionally from the rest); **−** pulls 12% out (spread to the rest).
- **SPREAD EVENLY** — instantly diversify to equal weights across all five.
- **ALL-IN ETF** — dump everything into the basket (the safe play).
- You can set your book during the calm ready state before the round starts, then adjust live.

## Shocks (the escalation)
A **shock** fires on a timer that accelerates as the clock runs down (~7.5s apart early → ~3.2s late):
- **Sector crash** (most shocks): one stock drops 50–82% over ~1.4s. Concentrated in it → you crater.
  Diversified → a glancing blow. The ETF only dips ~1/4 as much.
- **Rally** (~22%): one stock moonshots +40–85% — concentration's tempting upside, so greed has a voice.
- **Correlated crash** (late, ramp > 0.55): two sectors crash **together** — naive spreading across
  correlated stocks helps less, nudging you toward the steadier ETF.

## Comprehension layer (what makes the point unmissable)
Portfolio is about **allocation**, not single-asset timing (that's Market Trader). Four cues make the
difference legible in the first three seconds:
- **Always-visible objective line** under the value: *"SPREAD RISK — SET THE MIX ACROSS 5 HOLDINGS."*
- **Allocation DONUT** in the header — a live pie of the five weights (the ETF slice carries a bright
  inner rim / shield). This is the signature visual: a *mix of holdings*, which a single-price trading
  desk cannot show. Its hole reads the RISK SPREAD word (CONCENTR. → BALANCED → SPREAD, red→green,
  Herfindahl-based).
- **Coach hint** — a bright, centered *"Tap − + to set each weight · SPREAD EVENLY to diversify"* strip
  that **pulses until the player's first allocation move**, then fades over ~0.9s (auto-dismisses after
  ~7s if the player never touches a control, so it never covers the chart).
- **Score-driver +N pops** — the portfolio's net rise is banked and a green **+N** floats every ~0.5s of
  gain; weathering a sector crash with < 10% drawdown fires a **DIVERSIFIED! ×N** pop + burst, so the
  winning behaviour (a spread book shrugging off a crash) is *rewarded on screen*, not just in the score.

## Make the smoothing visible
The chart draws **three lines** against the $1,000 baseline:
- **YOU** — your live portfolio (bright teal / red when underwater).
- **1 STOCK** — what all-in on a single stock (FRYZ) would have done (thin red, wild).
- **BASKET** — what holding only the ETF would have done (thin teal, smooth).
A live market strip shows each ticker's % change since open.

## Scoring / win
Score = **current portfolio value** in points, synced every tick (`session.addScore(target − current)`;
the session clamps ≥ 0). It **can fall** — a blow-up is punished, steady growth is rewarded. Final value
at the buzzer is the score. **Streak award:** each sector crash *weathered* with < 10% drawdown bumps a
survival streak (reported via `session.noteStreak`) — the results screen reads it as diversification
mastery.

- `durationSeconds`: 60
- `scoreUnit`: "value"
- Tuning: a steady diversified book typically lands ~1,300–2,200; a perfectly-timed diversified run
  pushes ~3,000+; a concentrated gamble can spike higher or get wiped near zero.

## Implementation
Self-contained in `PortfolioGame` (`portfolio/portfolio_game.dart`). Constructor:
`PortfolioGame({super.key, required MiniGameSession session})`. One `AnimationController` ticker drives
`_tick` (sim, gated on `session.isRunning`) and three `CustomPainter`s (background, HUD/chart, FX) that
repaint off the ticker — the widget tree only rebuilds on allocation taps (no per-frame `setState`).
State: `_assets` (weights/prices), `_value`, `_shocks`, `_hist` (3-line chart samples). `_syncScore`
pushes the value delta to the session each tick. Comprehension state: `_acted`/`_hintAlpha` (coach hint),
`_gainAccum`/`_gainClock`/`_lastValue` (+N pop banking). The allocation donut is drawn in `_HudPainter.
_paintAllocationDonut`; static labels (objective line, coach hint) are cached `TextPainter`s laid out once
(no per-frame `GameFx.text` for static text).

**ATTRACT autopilot** demonstrates the lesson by cycling the game's own controls (deterministic 3-stage
loop): SPREAD EVENLY (calm diversified book) → ALL-IN on one stock (a concentrated book takes a crash on
the chin) → SPREAD EVENLY to recover. It calls the same methods the player's buttons do — no synthetic
taps, no flailing.
