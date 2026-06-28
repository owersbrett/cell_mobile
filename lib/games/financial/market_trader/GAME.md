# GAME.md — Market Trader / "Beat the Market" (trading-desk redesign)

> Canonical spec for the Financial-scale game. A coherent **trading desk**: the player has direct,
> obvious control over HOW MUCH each action moves (batch sizing), and can stage LIMIT BUY orders that
> reserve cash and fill against the moving market — or cancel them for a small fee.

- **Scale (cell):** financial
- **Game id:** market_trader (widget `FinancialTradingGame` in
  `lib/games/financial/market_trader/market_trader.dart`)
- **Role:** host-integrated mini-game. Score = cumulative **realized P&L**, pushed to the host session
  via `session.addScore` on every sell. The host (`MiniGameHost`) owns the clock/countdown/results.

## Problem this fixes
Play-test: "I have no agency over how much I buy/sell — it feels broken, and the actions are unclear."
The redesign gives the player a **batch-size knob** (stepper + 1/5/25/MAX presets), explicit
**AVAILABLE vs RESERVED** cash, and a real **order book**: place LIMIT BUYs that tie up cash until they
fill, cancel them (small fee) to free that cash and re-plan around market conditions. Every action is
labelled with its exact cash/share effect.

## Feature 0 — Batch sizing (the core fix)
A SIZE control sets the share count for every action. Stepper (−/+), one-tap lot presets (1 / 5 / 25),
and MAX (largest lot the available cash can afford at the current limit). A LIMIT slider sets how far
below market (0–18%) a buy order rests. BUY/SELL/PLACE buttons all carry the live lot in their label.

## Feature 1 — Orders & reserves
- **PLACE LIMIT BUY** — reserves `lot × limit` cash (moves AVAILABLE → RESERVED) and rests an order.
  It **fills** when the market trades at/under the limit; reserved cash converts to shares at the limit
  price (weighted into the average cost basis). A dashed sienna LIMIT line on the chart shows where it
  rests.
- **MARKET BUY** (the green BUY button) — instant fill of the lot at the live price.
- **CANCEL** — tap any open-order chip (or CANCEL ALL) to refund the reserved cash **minus a 1% fee**.
  The fee is a realized cost against P&L. No order can be placed without the cash to back it; cash never
  goes negative.

## Feature 2 — Selling / realizing
- **SELL `lot`** market-sells the lot from held shares; **SELL ALL** dumps the whole position.
- Realized P&L `(price − avgCost) × qty` accumulates and is reported to the session each sell.

## Feature 3 — Market events (the player can move the market)
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

## UI layout (top → bottom)
- **Wallet bar:** AVAILABLE · RESERVED · POSITION (shares) · P&L — always visible.
- **Live price** + delta + average-cost readout.
- **Chart** with the dashed LIMIT line for the resting order.
- **Position summary** (shares @ avg, value, unrealized P&L) or a "set a size, then BUY/LIMIT" hint.
- **SIZE control** (stepper + 1/5/25/MAX + LIMIT slider).
- **Order row** (PLACE LIMIT BUY w/ reserve cost · CANCEL ALL w/ fee) + open-order chips (tap to cancel).
- **Event buttons** (6, with cooldown rings).
- **Trade row pinned at the bottom:** BUY `lot` (market) · SELL `lot` · SELL ALL.

> Note: the old Credit/Debt mechanic is **removed**. Reserves-via-limit-orders is the new agency/capital
> mechanic and reads far more clearly than a debt meter.

## Multiplayer (future, not now)
Single-player today (events move your own market). This design is built for the planned **online mode**
(web-hosted / mobile-joined over Firebase): a **shared live market** where your Drought spikes everyone's
price and your Recession craters a rival right after they buy. Keep the event system factored so the
impulse source can later come from any player. (See online-play roadmap.)

## Scoring / win
Score = **cumulative realized P&L**, reported to the host session via `session.addScore` on every sell
(and reduced by cancel fees). The session clamps the score at ≥ 0, so net losses/fees can't drive it
negative. Open (unrealized) positions don't count — you must close to bank the gain. Highest realized
P&L at the buzzer wins.

## Implementation
- Self-contained in `FinancialTradingGame` (`market_trader/market_trader.dart`). Constructor is
  `FinancialTradingGame({Key? key, required MiniGameSession session})`. The sim only advances while
  `session.isRunning`; the host owns timer/countdown/results.
- Wallet is `_available` / `_reserved`, position is `_heldShares` + `_avgCost`, score is `_realized`.
  `_placeOrder` reserves cash, `_fillOrders` (checked on every price step) converts reserved cash to
  shares at the limit, `_cancelOrder`/`_cancelAllOrders` refund minus a 1% fee. `_sell` realizes P&L
  and calls `_syncScore`, which pushes the delta to `session.addScore` so the session score tracks the
  running realized total.
- **Registry note:** the `market_trader` spec in `mini_game_registry.dart` currently imports
  `financial/financial_trading/financial_trading_game.dart`. To ship THIS file, switch that import to
  `financial/market_trader/market_trader.dart` (both declare `FinancialTradingGame`, so only the import
  line changes — the builder call is unchanged).
