# GAME.md — Delivery / Supply Chain (refined)

> Canonical spec for the reworked Supply-Chain-scale game. The current build (farm → processor →
> distributor → market) is close but has **no tension** — you can hoard with no downside. This adds
> an antagonist (spoilage + market events), a 7-node chain, yield investment, and active market-opening.

- **Scale (cell):** supplyChain
- **Game id:** delivery (current widget `SupplyChainGame` in `mini_games_batch2.dart`)
- **One-line concept:** Build a potato empire — grow, process, and **keep product MOVING before it
  rots** — investing in farms and opening new markets, timing your sells to a volatile market.
- **Role:** solo high-score

## The core tension (the missing piece): PERISHABILITY
Potatoes rot. Raw and processed goods carry a **spoilage clock** and **storage is limited**. You can't
hoard — overflow or rot is lost product. **This is the antagonist that compels a sell.** On top of
that, periodic **market events** create timing pressure (sell now or miss it).

## 7 node types (place / upgrade on the board)
1. **Farm** — produces raw potatoes over time. **Invest in sod/seed or add farmers** to raise yield (#).
2. **Silo (Storage)** — buffers product, but everything inside is on a **spoilage clock**; limited
   capacity → overflow forces you to move it. The pressure valve.
3. **Wash & Sort** — preps raw potatoes (slows spoilage; gate to processing).
4. **Processor** — fries/chips (adds value).
5. **Premium Processor** — specialty goods (gourmet, vodka) for the top markets.
6. **Distributor** — speeds throughput / reaches farther markets.
7. **Cold Chain Transport** — slows spoilage and **unlocks Export.**

## Invest in farmers / sod (yield) — request #3
Spend cash to **upgrade a Farm** (sod/seed → higher output) or **add new Farms** (more farmers = more
yield). Yield growth is the engine; but more yield = more product to move before it spoils (feeds the
tension).

## Open new markets — request #4
Markets are **opened by investment**, not passive unlock: pay to **open** Local (start) → Supermarket →
Restaurant → Export. Each open market is an ongoing revenue channel; higher tiers need the right nodes
feeding them (Export needs Cold Chain). Markets **saturate** — flood one and its price dips, so spread
your sells.

## The antagonist — what compels a sell (request #2)
- **Spoilage + storage cap** (continuous): keep product flowing or lose it.
- **Market events** (periodic, telegraphed):
  - **Blight Scare** — prices about to crash; **sell now.**
  - **Demand Boom** — one market spikes; **dump into it now** for bonus.
  - **Price Crash** — a market tanks for a while; avoid it / pivot.
- Optional **rival "Spud Baron"** who periodically undercuts a market's price — a visible competitor.

## Loop
Build the chain → invest in farms/sod for yield → open markets → keep product moving before it spoils
→ time your sells to market events → most cash when the clock runs out.

## Scoring / win
Highest total cash at the buzzer. No fail state, but spoilage/overflow bleeds potential profit.

## Duration (tune)
More strategic than the arcade games — suggest **~45 s** (enough to build + react to a couple of
events) rather than 30 s. Confirm on build.

## Educational angle
Real supply-chain concepts: perishability & cold chain, value-add processing, market saturation,
yield investment, demand timing. The blocks (Harvest, Storage, Processing, Distribution, Retail) all
become mechanics.

## Potato angle
Native — it's a potato empire; processing = fries/chips/vodka, the cold chain, the markets.

## Implementation
- Reworks `SupplyChainGame` in `mini_games_batch2.dart` (edit ONLY that class). Keep the node-placement
  + auto-link + traveling-token rendering that already works; ADD spoilage clocks, the 7 node types,
  farm yield upgrades, market-opening, and market events. Fix the existing FxPop/FxBurst placeholder
  positions (they stack in a corner) while in there.
