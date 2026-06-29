# POTATUHS — Stock It Right

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Stock It Right ("Beat the Bullwhip") — the supply-chain-scale **inventory** game, a
  lite single-node Beer Game. Self-contained module
  (`lib/games/supply_chain/stock_it/stock_it_game.dart`, `StockItGame`); on `BioScale.supplyChain`.
  Sibling to `delivery` (routing) on the same scale — this one is stock-over-time, not distance.
- **O — Objectives:** post the highest **running PROFIT** at the 60 s buzzer (`session.addScore`, clamped
  at 0). Profit = revenue from potatoes sold − holding cost on excess stock − stockout penalty. Sub-goal:
  the longest **smooth-supply streak** (`session.noteStreak`) — consecutive days with no stockout and no
  heavy overstock.
- **T — Tasks (the play to-do list):** read the demand LEVEL off the chart · set an **ORDER** size
  (stepper / `=level` / `+5` / `0`) · place orders **ahead of the lead time** so the pipeline keeps
  feeding · hold a safety buffer that keeps the stock line inside the healthy band · resist the urge to
  panic-buy a spike · keep the bullwhip meter near ×1.
- **A — Automations (firing in the background):** the host-owned 60 s clock (sim gates on
  `session.isRunning`) + a single-Ticker **day clock** (~1.8 → 1.15 s/day) · per-day `_advanceDay`
  pipeline shift / demand draw / sales / cost accounting · a drifting `_demandLevel` with regime-shift
  jumps + daily noise · the live **bullwhip meter** = `std(orders)/std(demand)` over a rolling window ·
  the escalating lead time (3→4→5) and growing demand swings.
- **T — Testing (experimental / in-flight):** today it's a **single-node, lost-sales** cut. The designed
  but-not-yet-built directions: a **backlog** variant (unmet demand must be filled later, true Beer-Game
  rules) and a **multi-echelon** chain (retailer→wholesaler→factory) where the bullwhip amplifies stage by
  stage — the real, dramatic version of the effect. Both flagged in AGENT.md as out-of-scope-for-now.
- **U — UX:** a stat bar (STOCK · DEMAND · INCOMING · PROFIT) up top with stock coloured by zone · a
  CustomPainter chart showing the shaded healthy band, the stockout floor, the faint demand line and the
  bright glowing stock line (the bullwhip made visible) · a BULLWHIP amplification readout · incoming
  pipeline chips ("20 · in 3d") that make lead time tangible · a SIZE stepper + ORDER button at the
  bottom · a calm READY card before play. Canvas-drawn; no raster assets.
- **H — Heuristics (how you actually win):** order to the **level, not the noise** · keep goods always in
  transit (never an empty pipeline) · carry enough to cover lead-time demand + a safety day, no more ·
  **don't overreact** — gentle adjustments beat panic orders · boring is optimal: a flat stock line in the
  band with the bullwhip meter at ×1 is the highest-profit play.
- **S — Systems (what makes the world feel alive):** a demand level that quietly drifts and occasionally
  lurches, so the future is never quite known · a delay you cannot shorten, turning every order into a
  forecast · two costs (stockout vs. holding) pulling against each other so there's always a right answer
  to find · and the bullwhip itself — a feedback loop where your own reactions, fed through the delay,
  become the thing you're fighting. The chart is the soul of the game: you literally watch a small demand
  ripple become a big supply wave, in your own hand.
