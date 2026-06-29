# GAME.md — Stock It Right (inventory · lead time · bullwhip)

> Canonical spec for the supply-chain-scale inventory game — the "Beer Game", lite. Rules live here:
> edit this first, then the code. A sibling to `delivery` (routing) on the same scale, teaching a
> DIFFERENT concept — not routing, but **inventory control under delay**.

- **Scale (cell):** `BioScale.supplyChain`
- **Game id:** `stock_it`  ·  widget `StockItGame` in `stock_it_game.dart`
- **One-line concept:** Run one potato WAREHOUSE that ships spuds to stores. Keep stock in the healthy
  band by ordering **ahead of the lead time** — and watch your own panic create the bullwhip.
- **Role:** solo high-score (also drops into party rotation).
- **Duration:** 60 s (host-owned clock).

## The loop (one DAY at a time)
Time advances in DAYS (~1.8 s/day at the start, speeding up to ~1.15 s/day). Each day, in order:

1. **Arrivals** — any order that has finished its lead time lands on the shelf (`_pipeline[0]`), and the
   incoming pipeline shifts one slot closer.
2. **Demand & sales** — customers want `demand` potatoes. You sell `min(stock, demand)`; unmet demand is
   a **STOCKOUT** (lost sales + penalty).
3. **Costs** — `revenue = sales × $12`; `holding = (stock above the free buffer of 10) × $0.6/day`;
   `penalty = missed × $16`. Day profit = revenue − holding − penalty.
4. **Record** — stock + demand pushed to the chart; per-day demand & order series feed the bullwhip meter.

You may **place an order at any time**. It does NOT arrive now — it enters the pipeline at the lead-time
slot and shows up that many days later. This delay is the whole game.

## The two failure modes (the tension)
- **STOCKOUT** (demand > stock) — you lose the sale AND eat a $16/unit penalty. Order too little / too
  late and the shelf goes empty.
- **OVERSTOCK** — every potato held above the free buffer bleeds $0.6/day. Panic-order after a spike and
  you drown in holding cost a few days later.

The sweet spot is the **healthy band** (shaded green on the chart): enough to cover demand across the
lead time plus a safety day, never so much that holding cost piles up.

## The teaching twist — the BULLWHIP EFFECT
Because orders are delayed, reacting to every demand wobble makes your stock **oscillate**: you panic-buy
after a spike, it over-arrives, you slam orders to zero, you stock out, you panic-buy again. The chart
shows your stock line (big swing) against the demand line (small wobble), and a live **BULLWHIP meter**
= `std(your orders) / std(demand)`. Above ×2 it flashes `BULLWHIP!` — your ordering is amplifying a small
demand ripple into a big supply wave. Order to the demand LEVEL, not to today's noise, and the meter
stays near ×1.

## Scoring / win
- **Score = running PROFIT** (revenue − holding − stockout penalty), pushed via `session.addScore` (the
  session clamps cumulative at ≥ 0). Most profit at the buzzer wins.
- **Streak** = consecutive "smooth supply" days (no stockout AND not heavily overstocked), via
  `session.noteStreak` — surfaced as a mastery award on the host results screen.

## Escalation
- **Lead time** stretches: 3 days (early) → 4 (mid, ~day 14) → 5 (late, ~day 26). Longer delay = you must
  forecast further ahead.
- **Demand swings** grow: regime shifts in the underlying demand level get bigger as the game runs.
- **Days speed up** toward the end.

## Controls
- **Order size** stepper (−/+) with presets: `=level` (match current demand level), `+5`, `0`.
- **ORDER** button — drops the current size into the pipeline at the lead-time slot.
- Incoming pipeline chips show each batch and how many days until it arrives.

## Potato angle
Native — it's a potato warehouse shipping spuds to stores; orders are truckloads in transit.

## Implementation notes
- Self-contained module under `lib/games/supply_chain/stock_it/`. Imports only `mini_game.dart`,
  `fx.dart`, `theme/potatuhs.dart`, Flutter, `dart:math`. Imports no other game.
- One `AnimationController` (Ticker) drives the day clock and the single `CustomPainter` chart. Stats and
  controls rebuild only on day boundaries / taps — never per frame (the black-screen perf rule).
- Registry wiring (`MiniGameSpec`, `CatalogGame`) is the orchestrator's job, NOT this folder's.
