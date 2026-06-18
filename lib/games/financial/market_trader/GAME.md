# GAME.md — Market Trader / "Beat the Market" (enhanced)

> Canonical spec for the Financial-scale game enhancements. Core buy-low/sell-high loop is fun; this
> adds player-controlled market events, a debt/credit mechanic, and fixes the "sold early → locked out"
> dead end.

- **Scale (cell):** financial
- **Game id:** market_trader (widget `FinancialTradingGame` in `mini_games_batch3.dart`)
- **Role:** solo high-score (designed to extend to shared online market — see Multiplayer)

## Problem this fixes
Play-test: "I sold too early and was effectively locked out" — once you're in cash and the price runs
away, there's no way back in. The new mechanics give the player **agency over the market** (crash it to
re-enter cheap) and **credit** (borrow to get back in), so you're never dead in the water.

## Feature 1 — Market events (the player can move the market)
Buttons the player taps to shove the price, each on its own **cooldown** (no spamming). They inject a
strong, sustained price impulse (extend the existing `_news`/impulse system). Timing them with your
position is the skill.

**Price-UP events (scarcity / supply shock):**
- **Drought** · **Flooding** · **Tornado** · **Earthquake** → spike the price up (buy first, then pump, then sell).

**Price-DOWN events (crash):**
- **Recession** (demand collapse) · **Abundance** (oversupply glut) → crash the price (sell/stay out first, then crash, then buy the dip).

(Directions are a starting call — each is just an impulse sign, trivially flippable. Earthquake could
instead be a pure volatility spike if you prefer chaos over direction.)

Each button shows a **cooldown ring/timer**; strength/duration tuned so a well-timed event meaningfully
swings a trade but doesn't trivialize the game.

## Feature 2 — Credit / Debt
- **Take Credit** — borrow cash (adds to wallet + to a **debt** balance). Buying power on demand —
  including a way back in after selling early.
- Debt **accrues interest that chips away at your realized funds** over time (a visible debt meter
  draining you) — the warning that you're leveraged.
- **Pay Debt** (clear in full) and **Minimum Payment** (chip it down) buttons.
- Risk/reward: leverage up for bigger swings, but the interest bleeds your score if you sit in debt.

## UI placement (per request)
A new control cluster in the **bottom-middle**, **between the BUY/SELL row and the position-status row**
("No open position — tap BUY to enter"):
- Row of 6 event buttons (compact, with cooldown indicators).
- Credit/debt controls (Take Credit · Pay/Min Payment) + a debt readout.
Keep the chart up top and the BUY/SELL row at the very bottom.

## Multiplayer (future, not now)
Single-player today (events move your own market). This design is built for the planned **online mode**
(web-hosted / mobile-joined over Firebase): a **shared live market** where your Drought spikes everyone's
price and your Recession craters a rival right after they buy. Keep the event system factored so the
impulse source can later come from any player. (See online-play roadmap.)

## Scoring / win
Highest **net worth minus outstanding debt** at the buzzer (debt must count against you, or credit is free
money). Leaderboard stays.

## Implementation
- Edit ONLY `FinancialTradingGame` in `mini_games_batch3.dart`. Reuse the `_news`/impulse + `_price`
  engine; add player events as impulse sources with cooldowns, and a `_debt` balance with interest +
  pay buttons. Fix the existing P&L-pop hardcoded `Offset(160,260)` while in there.
