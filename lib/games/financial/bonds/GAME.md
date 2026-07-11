# GAME.md — Bonds

> Canonical spec for the second Financial-scale game. A fixed-income trading desk built around the one
> rule new investors never believe until they feel it: **when interest rates rise, the price of bonds
> you already own falls** — and the longer the bond, the harder it falls.

- **Scale (cell):** financial
- **Game id:** `bonds` (widget `BondsGame` in `lib/games/financial/bonds/bonds_game.dart`)
- **Role:** host-integrated mini-game. Score = cumulative **realized profit**, pushed to the host
  session via `session.addScore` on every sell. The host (`MiniGameHost`) owns the
  clock / countdown / results; this widget renders only the play area and runs the sim while
  `session.isRunning`.
- **Sibling on this scale:** `market_trader` ("Beat the Market") — an equities desk. Bonds is its
  fixed-income counterpart: instead of one ticker, you trade several instruments whose prices are all
  driven, inversely, by a single moving interest rate.

## The lesson the mechanic IS
A central **INTEREST RATE** ticker drifts up and down. Every tradeable bond has a fixed coupon and
maturity set at issue; its market **price** is computed live as the present value of those fixed cash
flows discounted at the current rate. Because a higher discount rate shrinks every future dollar, the
price is a strictly **decreasing** function of the rate. So the chart literally shows the RATE line and
the PRICE line moving in opposite directions, every frame. You win by buying bonds when rates are high
(prices cheap) and selling after rates fall (prices rise) — and by getting out of long bonds before
rates climb.

## Instruments (maturity ladder)
Four bonds, unlocking over the round so the duration lesson lands in order:

| Bond | Coupon | Unlocks | Behaviour |
|---|---|---|---|
| **2Y** | 4.5% | start | Short. Price barely moves when rates swing — low rate risk. |
| **5Y** | 4.5% | start | Medium. Noticeable swings. |
| **10Y** | 4.0% | 18s | Long. Big price moves for the same rate change. |
| **30Y** | 4.0% | 38s | Longest. The most rate-sensitive — biggest profits and biggest losses. |

Each row shows a live **`rate +1% ⇒ −X%`** readout (the price drop for a 1-point rate rise). The number
grows with maturity — that IS duration / interest-rate risk, shown as a number you can watch.

## Controls
- **SIZE** — stepper (−/+), presets `1 / 5`, and `MAX` (most the cash can afford at the live price).
- **Tap a bond row** to select it; the BUY/SELL row acts on the selected bond.
- **BUY n** — buy the lot at the live price (spends cash).
- **SELL n / SELL ALL** — sell the lot / whole position, realizing `(price − avgCost) × qty`.

## Escalation (difficulty ramp)
As the 60s round wears on, rate swings get **larger** (±1.0% → ±3.6% target jumps), **faster** (new
targets every 4.5s → 2.0s), and the rate chases them harder. Longer bonds unlock mid-round, raising the
ceiling on both profit and risk. Late game is a fast, sharp rate environment where a mistimed 30Y is
brutal and a well-timed one pays out big.

## Comprehension layer (teach the ONE action)
Bond finance is unfamiliar to most players, so three always-legible aids make the core loop obvious
without redesigning the mechanic:
- **Objective strip** (under the wallet bar, never leaves): a live one-liner that names the CURRENT best
  move. Flat → `BUY a bond cheap, SELL after rates fall`; holding underwater → `HOLDING — wait for rates
  to FALL, then SELL`; sitting on a gain → `PROFIT READY — SELL to bank +$N`. Colour + icon track the state.
- **How-to coach:** an unmissable, pointer-transparent card over the chart at round start, breathing
  gently. Colour-coded rule: *Rates HIGH ⇒ bonds CHEAP. Tap a bond, BUY — then when rates FALL, SELL for
  profit.* It **fades for good on the player's first buy** (WarioWare-style teach that gets out of the way).
- **Live SELL subtext:** the SELL button reads `bank +$N` / `loss -$N` for the selected position, so the
  score-driver is legible at the exact moment of action (this, plus the floating `+$N` pop on the sell,
  makes "why did my score move" self-evident).

## UI layout (top → bottom)
- **Wallet bar:** CASH · BONDS (mark-to-market value of holdings) · PROFIT (realized P&L).
- **Objective strip:** the always-visible one-line objective (see Comprehension layer).
- **Rate panel:** the live INTEREST RATE with its trend arrow, plus the cause→effect callout
  `RATES ▲ ⇒ PRICES ▼` that flips in real time — the inverse rule, narrated.
- **Chart:** gold RATE line + the selected bond's PRICE line (its colour), visibly inverse. The price
  series is recomputed from the rate series in the painter, so the two lines are always exact opposites.
- **SIZE control.**
- **Bond ladder:** one selectable row per maturity (badge, coupon, live price + delta, `rate +1%`
  sensitivity, your position + unrealized P&L). Locked rows show their unlock time.
- **Trade row pinned at the bottom:** BUY n · SELL n · SELL ALL (selected bond).

## Scoring / win
Score = **cumulative realized profit**, reported via `session.addScore` on every sell. The session
clamps at ≥ 0, so net losses can't drive it negative. Open positions don't count — you must sell to bank
the gain. **`session.noteStreak`** is fed the count of consecutive profitable sells (a clean losing sell
resets it), so the results screen can award a trading streak. Highest realized profit at the buzzer wins.

## Implementation
- Self-contained in `BondsGame` (`bonds/bonds_game.dart`). Constructor is
  `BondsGame({super.key, required MiniGameSession session})`. A single `AnimationController` ticker drives
  the loop; it returns early unless `session.isRunning`, so the host owns timer/countdown/results and the
  board sits calm before the round starts.
- Bond pricing is an iterative present-value loop (no `pow` import). Prices are **derived** from the live
  rate, never stored — including the chart's price line — guaranteeing the inverse relationship is real,
  not decorative.
- All rendering is canvas/procedural (atmosphere background, one chart painter, an FX overlay). No raster
  assets. Performance: one ticker → `CustomPainter` for the chart; per-frame `setState` only mutates
  small scalars/lists, never a large tree.
