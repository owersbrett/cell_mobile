# EDUCATION.md — Stock It Right (inventory, lead time & the bullwhip effect)

> What this game teaches: how to **control inventory under delay** — the core problem of every supply
> chain. You hold stock you can't see the future of, you order against a delay you can't shorten, and the
> two costs (running out vs. holding too much) pull in opposite directions. The mechanic IS the lesson:
> every order you place is a bet on demand a few days from now, and the chart shows you — live — when your
> own overreaction turns a small demand ripple into a violent supply wave. That wave is the **bullwhip
> effect**, the most famous result in supply-chain theory.

- **Scale:** `BioScale.supplyChain` — a warehouse is a node in a chain; inventory is the buffer between
  unpredictable demand and delayed supply.
- **Game:** `stock_it` (this game). Sibling to `delivery` (routing) on the same scale; this one is about
  **stock over time**, not distance.
- **Lineage:** a lite, single-node version of the **Beer Distribution Game**, the MIT Sloan classroom
  simulation that made the bullwhip effect famous.

---

## 1. Inventory: the buffer between demand and supply

Customers want potatoes *now*; potatoes take *time* to arrive. **Inventory** — the stock sitting on your
shelf — is the cushion that absorbs that mismatch. With enough stock, a customer who walks in today gets
served from the buffer while your replenishment is still in transit. Inventory is how a supply chain
decouples the *rate* it sells from the *rate* it resupplies.

But inventory is not free, and it is not safe. Hold too little and you **stock out**; hold too much and you
**bleed cash** carrying it. The entire job is finding the level in between — and that job is hard *only*
because of the next idea.

---

## 2. Lead time: orders take time to arrive

When you place a replenishment order, it does not appear on the shelf. It travels through a **lead time** —
the delay between *placing* an order and *receiving* it (in this game, 3–5 days). During the lead time you
are committed: nothing you do changes the stock that's already in transit.

This is what makes inventory a *forecasting* problem instead of a reflex. You cannot order for today's
shelf — today's shelf is already set by orders you placed days ago. **You must order for the demand you
expect when the order finally lands.** The pipeline display in the game ("20 · in 3d") is exactly this:
goods you've committed to that haven't arrived yet. Good players read the pipeline as part of their
stock — what you'll have, not just what you have.

The key quantity is **demand during lead time**: roughly `expected daily demand × lead time`. That is how
much stock you'll consume before a fresh order can possibly help you. Your on-hand plus in-transit stock
needs to cover it.

---

## 3. Safety stock: a buffer against the unknown

Demand is not constant — it wobbles, and occasionally jumps to a new level (a "regime shift" in the game).
If you carry *exactly* the expected lead-time demand, then any day demand runs a little hot, you stock out.
So you carry a little extra — **safety stock** — to absorb the variability.

```
order-up-to level  ≈  (expected demand × lead time)  +  safety stock
```

More demand variability, or a longer lead time, means you need **more** safety stock to hit the same
service level (the same chance of *not* stocking out). The game's **healthy band** (the shaded green zone)
is exactly this order-up-to range: its centre is lead-time demand plus a safety day, and it widens as the
demand level grows. Keep the stock line in the band and you're carrying the right buffer — covered against
normal wobble, without drowning in excess.

---

## 4. The two costs that pull against each other

Every inventory decision trades off two opposing costs:

| | What goes wrong | What it costs (in game) |
|---|---|---|
| **Stockout** (too little) | Demand you can't fill | Lost sale **+** $16/unit penalty — angry stores, lost revenue, lost goodwill |
| **Holding** (too much) | Stock sitting idle | $0.6/potato/day above the free buffer — tied-up cash, spoilage, warehouse space |

In the real world, stockouts cost lost margin, expediting fees, and customer trust; holding costs cover
capital, storage, insurance, obsolescence, and (for potatoes!) spoilage. The optimum is **not** "never
stock out" and **not** "never hold extra" — it's the level where the marginal cost of one more unit of
buffer equals the marginal cost of the stockouts it prevents. That balance point is what the healthy band
visualizes, and why both red (empty) and deep-gold (bloated) are bad on the chart.

---

## 5. The bullwhip effect — the heart of the game

Here is the deep idea, and the reason this game exists. Watch the two lines on the chart: **demand** (the
faint gold line) wobbles only a little. But your **stock** (the bright line) can swing wildly — up, then
crashing down, then up again. Why does a small wobble in demand produce a big swing in your inventory and
orders?

Because of the **delay**. Suppose demand spikes for a day. You panic and place a big order. But it won't
arrive for 3 days — so meanwhile you keep feeling short and order *more*. Then all those orders land at
once: now you're massively overstocked, bleeding holding cost, so you slam your orders to **zero**. With
nothing in the pipeline, a few days later the shelf runs dry and you stock out — so you panic-order again.
The cycle repeats. A one-day demand bump has become a self-sustaining oscillation in your stock.

This amplification — **small variation in demand → large variation in orders** — is the **bullwhip
effect** (named because a flick of the wrist sends a big wave down a whip). Its causes, all present here:

- **Order delay / lead time** — you can't see the result of an order before reacting again, so you
  over-correct.
- **Overreaction to noise** — treating a random one-day blip as a real trend.
- **Forecast chasing** — re-forecasting off the latest data point instead of the underlying level.

The game's **BULLWHIP meter** measures it directly: it's `std(your orders) ÷ std(demand)` over the last
several days. At ×1 your ordering is as smooth as demand. Above ×2 it flashes `BULLWHIP!` — your orders are
twice as jumpy as the demand they're chasing. *You* are now the source of the chaos.

### Why it matters far upstream

In a real multi-stage chain (store → distributor → factory → raw supplier), each stage reacts to the
*orders* of the stage below it, not to true end-customer demand. So the bullwhip **amplifies at every
step**: a 10% wobble at the shelf can become a 40% swing at the distributor and a wild boom-bust at the
factory. This is why factories see feast-or-famine production while actual consumer demand barely moved —
and it's a major driver of real-world waste, with documented cases (Procter & Gamble's diapers, HP's
printers) launching the whole field of study.

---

## 6. How to play it right (the strategy that IS the lesson)

1. **Order to the demand LEVEL, not the noise.** Use the `=level` preset as your anchor. A single hot day
   is probably noise; don't chase it.
2. **Order ahead of the lead time.** Replenish steadily so goods are always arriving — the pipeline should
   never be empty for long.
3. **Hold a safety buffer.** Stay in the healthy band: covered against a bad day, not so deep that holding
   cost piles up.
4. **Don't overreact.** When you see a spike, resist the urge to slam a huge order — that's exactly the
   reflex that whips. Adjust gently; let the steady flow do the work.
5. **Smooth orders beat clever orders.** The most profitable players keep the bullwhip meter near ×1 and
   the stock line flat inside the band — boring on purpose.

---

## Association verdict

**Strong tie to the supply-chain scale.** A supply chain is, at bottom, the problem of matching uncertain
demand to delayed supply, buffered by inventory — and the bullwhip effect is the signature failure mode of
that problem, the thing the whole discipline organizes itself around. This game strips the chain to one
node so the dynamics are legible, then makes the abstraction physical: you feel the lead-time delay in your
hands, you watch the two costs fight, and you watch your own panic amplify a ripple into a wave on a live
chart. There is no cleaner embodiment of "inventory under delay" on this scale.
