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
and MAX (largest lot the available cash can afford at the live **market** price — sized to market so a
market BUY *and* a resting LIMIT order both stay affordable; MAX never leaves a trade button greyed). A
LIMIT slider sets how far below market (0–18%) a buy order rests. BUY/SELL/PLACE buttons all carry the
live lot in their label.

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

## Feature 3 — Market events (the player can move the market — FOR A PRICE)
Buttons the player taps to shove the price. **Every event is a PURCHASE** (Brett, 2026-07-11): tapping
one deducts its price from AVAILABLE cash, and the cost is booked as a **realized expense against P&L**
(exactly like the cancel fee) — the score honestly reflects "spent $60 to make $300 on the pump" versus
a mistimed event that just burned money.

- **Price:** flat `$60` per event (`_kMtEventCost`, ONE tunable const — ~6% of starting capital; a
  well-timed event on a sized position clearly out-earns it, a mistimed one clearly hurts).
- **Affordability gate:** each event button carries its price tag (e.g. `☀️ DROUGHT · $60`) and greys
  out when AVAILABLE cash can't cover it. Cash never goes negative.
- **Cooldown stays** (per-event): money buys the event, time gates the rhythm — wealth cannot
  chain-pump.
- HUSTLE remains the free-cash floor, now doubling as "grinding toward your next event."

> **Shared-market note:** the sim (price path AND events) is per-player local; rooms only sync scores.
> A shared live tape (host-published ticks/events, one market per room, your Drought hits everyone) is
> a designed-but-not-commissioned follow-up.

They inject a strong, sustained price impulse (the existing `_news`/impulse system). Timing them with
your position — and affording them — is the skill.

**Price-UP events (scarcity / supply shock):**
- **Drought** · **Flooding** · **Tornado** · **Earthquake** → spike the price up (buy first, then pump, then sell).

**Price-DOWN events (crash):**
- **Recession** (demand collapse) · **Abundance** (oversupply glut) → crash the price (sell/stay out first, then crash, then buy the dip).

(Directions are a starting call — each is just an impulse sign, trivially flippable. Earthquake could
instead be a pure volatility spike if you prefer chaos over direction.)

Each button shows a **cooldown ring/timer**; strength/duration tuned so a well-timed event meaningfully
swings a trade but doesn't trivialize the game.

## Feature 4 — HUSTLE (the comeback)
A gold **HUSTLE** button pinned in the bottom trade row. **Every tap earns $1 of free cash** —
fires on pointer-DOWN, no cooldown, no throttle: each pound of the thumb pays, that IS the hustle.
It exists so a player who busts (no cash, no shares, no orders) or gets priced out can grind back
into the market instead of dead-ending.

- **Hustled dollars are CASH, not P&L.** They flow into AVAILABLE (spendable on market buys and
  order reserves) and never into realized P&L — **tapping alone can never move the score**. Hustle
  is the floor, not a strategy; a skilled trader out-earns a tap-spammer by an order of magnitude.
- **Bust legibility:** when the player is effectively locked out (free cash below the cheapest
  possible action — 1 share at the deepest limit discount — AND no shares AND no open orders), the
  HUSTLE button gets a gentle gold pulse/glow and the position row shows one line:
  *"Hustle back in — $1 a tap."* No modal, no interruption. Open orders block the bust state —
  reserved cash is still working capital.
- **The lesson:** labor income vs capital gains — hustle gets you a stake; the market is where it
  compounds. Only trades score.

## UI layout (top → bottom)
- **Wallet bar:** AVAILABLE · RESERVED · POSITION (shares) · P&L — always visible.
- **Live price** + delta + average-cost readout.
- **Chart** with the dashed LIMIT line for the resting order.
- **Position summary** (shares @ avg, value, unrealized P&L) or a "set a size, then BUY/LIMIT" hint.
- **SIZE control** (stepper + 1/5/25/MAX + LIMIT slider).
- **Order row** (PLACE LIMIT BUY w/ reserve cost · CANCEL ALL w/ fee) + open-order chips (tap to cancel).
- **Event buttons** (6, with cooldown rings).
- **Trade row pinned at the bottom:** HUSTLE (+$1/tap) · BUY `lot` (market) · SELL `lot` · SELL ALL.

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
P&L at the buzzer wins. **Hustled cash is excluded by construction** — it only ever enters
`_available`, never `_realized`, so the score can only come from trading.

## Implementation
- Self-contained in `FinancialTradingGame` (`market_trader/market_trader.dart`). Constructor is
  `FinancialTradingGame({Key? key, required MiniGameSession session})`. The sim only advances while
  `session.isRunning`; the host owns timer/countdown/results.
- Wallet is `_available` / `_reserved`, position is `_heldShares` + `_avgCost`, score is `_realized`.
  `_placeOrder` reserves cash, `_fillOrders` (checked on every price step) converts reserved cash to
  shares at the limit, `_cancelOrder`/`_cancelAllOrders` refund minus a 1% fee. `_sell` realizes P&L
  and calls `_syncScore`, which pushes the delta to `session.addScore` so the session score tracks the
  running realized total. (Cancel/sell are guarded on `session.isRunning`; reserved cash is clamped at
  ≥ 0 so float drift can't leak a phantom reserve.)
- **Hustle:** `_hustle()` adds `_kMtHustlePerTap` ($1) to `_available` per pointer-down on the HUSTLE
  button (a `Listener`, rapid-fire friendly). Deliberately no per-tap `setState` — the AVAILABLE
  readout refreshes on the 20 Hz render tick, the "+$1" pop lives on the FX canvas (pop count capped
  at `_kMtMaxHustlePops`; earnings never capped), and the press squash runs on its own tiny
  `AnimationController` — so tap-spam can't force full-tree rebuilds past the throttle. Bust
  detection is `_isBusted` (`!_inPosition && _orders.isEmpty && _available < price × (1 −
  _kMtLimitOffsetMax)`). The ATTRACT autopilot hustles a few taps per tick if it ever busts.
- **Registry:** `mini_game_registry.dart` imports this file (`financial/market_trader/market_trader.dart`)
  and builds it via `FinancialTradingGame(session: session)`. This is the shipped Financial-scale game.
- **Render budget:** the sim steps every frame, but the widget tree only rebuilds at `_kMtRenderHz`
  (20 Hz) — or immediately on a discrete event (fill / news / cooldown-ready). The chart, particles and
  atmosphere are drawn by `Listenable`-driven `CustomPainter`s (the chart repaints only when a sample is
  appended or the order set changes), so the big control tree is never rebuilt 60×/sec. This keeps the
  game off the app's render-overload / black-screen path.
