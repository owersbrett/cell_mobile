# POTATUHS — Bonds

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Bonds — the financial-scale fixed-income desk that teaches the price/yield inverse.
  Self-contained module (`lib/games/financial/bonds/bonds_game.dart`, `BondsGame`); on
  `BioScale.financial`. The structural sibling of Market Trader (equities → free-floating price; Bonds →
  price *derived* from a moving interest rate).
- **O — Objectives:** post the highest **cumulative realized profit** at the 60s buzzer (reported via
  `session.addScore`). Sub-goals: read the rate trend, match maturity to conviction (long bonds when sure,
  short bonds when not), and close positions before the buzzer — open holdings don't score.
- **T — Tasks (the play to-do list):** watch the **INTEREST RATE** ticker · set your **SIZE**
  (stepper / 1·5 / MAX) · **tap a bond** on the maturity ladder to select it · **BUY** when rates are high
  (prices cheap) · hold as rates fall and prices rise · **SELL / SELL ALL** to bank the gain · rotate into
  short bonds before a rate spike · chase the late-game **30Y** for the biggest (riskiest) swings.
- **A — Automations (firing in the background):** the host-owned 60s clock (sim gates on
  `session.isRunning`) · a per-frame **rate engine** that drifts toward random targets, escalating in size
  and speed as the round wears on · **live present-value pricing** of every bond from that rate
  (`_price`) so prices move inversely with no extra wiring · timed **maturity unlocks** (10Y at 18s, 30Y
  at 38s) · the per-bond `rate +1% ⇒ −X%` duration gauge (`_sensitivity`).
- **T — Testing (experimental / in-flight):** the rate engine is isolated in `_tick` so its source can
  later come from a server — built toward the planned **online shared-rate market** (Firebase) where every
  player trades the same rate environment. Solo today; this is the game's disruption seam. Open idea: a
  yield-curve inset to make the duration ladder even more legible.
- **U — UX:** wallet bar (CASH · BONDS value · PROFIT) up top, a **rate panel** whose
  `RATES ▲ ⇒ PRICES ▼` callout flips live to name the inverse rule, a two-line **chart** (gold RATE vs the
  selected bond's PRICE, visibly mirrored), a SIZE control, a selectable **bond ladder** (badge, coupon,
  live price + delta, sensitivity gauge, your position + unrealized P&L), and the BUY / SELL / SELL-ALL
  row pinned at the bottom · every button carries its exact cash effect · profit pops + colour flashes on
  each realized trade.
- **H — Heuristics (how you actually win):** rates high ⇒ prices cheap ⇒ **buy** · rates about to rise ⇒
  **sell long bonds** or hide in short ones · longer maturity = bigger swing = bigger profit *and* bigger
  loss — only go long-duration when you're confident · size up on conviction, retreat to the 2Y when
  unsure · close before the buzzer — unrealized gains don't score · profitable sells build a streak
  (`noteStreak`), a clean loss resets it.
- **S — Systems (what makes the world feel alive):** a single interest rate that never stops breathing —
  escalating, reversing, dragging four bond prices the opposite way in lockstep — so the whole board moves
  as one coupled system you fight and time · the price line *is* arithmetic on the rate line, so the
  inverse relationship isn't decoration, it's the physics of the world · the late-unlocking 30Y is the
  living tension at the heart of the game: the most profit and the most pain, both at once.
