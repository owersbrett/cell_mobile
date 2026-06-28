# POTATUHS — Market Trader

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Market Trader ("Beat the Market") — the financial-scale buy-low/sell-high trader.
  Self-contained module (`lib/games/financial/market_trader/market_trader.dart`,
  `FinancialTradingGame`); on `BioScale.financial`.
- **O — Objectives:** post the highest **cumulative realized P&L** at the 60s buzzer (reported via
  `session.addScore`). Sub-goals: size your trades deliberately, stage limit orders to enter on dips,
  use events to manufacture your entry/exit, and close before the buzzer — open positions don't score.
- **T — Tasks (the play to-do list):** set your **SIZE** (stepper / 1·5·25 / MAX) · BUY at market or
  **PLACE LIMIT BUY** to reserve cash and enter on a dip · CANCEL orders (1% fee) to re-plan · SELL the
  lot or SELL ALL to realize · fire **market events** to shove the price (Drought · Flooding · Tornado ·
  Quake pump it up; Recession · Abundance crash it) · time events to your position.
- **A — Automations (firing in the background):** the host-owned 60s clock (sim gates on
  `session.isRunning`) + per-frame price engine (`_price`, ticking `_kMtBaseTickHz`→`_kMtMaxTickHz`) ·
  escalating volatility (`_kMtBaseVolatility`→`_kMtMaxVolatility`) and random `_news` impulses ·
  per-step limit-order fills (`_fillOrders`) · per-event cooldown timers (`_eventCooldowns`,
  `_kMtEventCooldown`).
- **T — Testing (experimental / in-flight):** the event system is factored so the impulse source can
  later come from *any* player — built for the planned **online shared live market** (web-hosted /
  mobile-joined over Firebase) where your Drought spikes everyone and your Recession craters a rival right
  after they buy. Solo today; this is the game's disruption seam.
- **U — UX:** wallet bar (AVAILABLE · RESERVED · POSITION · P&L) up top, chart with a dashed limit line,
  a SIZE control (stepper + 1/5/25/MAX + limit slider), an order row (PLACE LIMIT / CANCEL ALL) with
  tap-to-cancel order chips, 6 event buttons each with a cooldown ring, and the BUY/SELL/SELL-ALL row
  pinned at the bottom · every button carries its exact cash/share effect · P&L pops on each realized
  trade.
- **H — Heuristics (how you actually win):** size up when you're confident · rest LIMIT BUYs below market
  to catch dips for free, cancel them (small fee) when the read changes · buy first, *then* fire an UP
  event, then sell into the spike · sit out, *then* crash it, then buy the dip · close before the buzzer —
  unrealized gains don't score · respect cooldowns; one shove at a time.
- **S — Systems (what makes the world feel alive):** a market that never stops moving — escalating
  volatility, random news shocks, and player-driven weather/economy events make the price feel like a
  living thing you fight and steer · resting limit orders that fill on the swing make the order book feel
  alive — the living tension at the heart of the game.
