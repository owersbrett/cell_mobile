# ITEMS_SPEC — The Market Catalog

> LOCKED spec (Brett, 2026-07-12, yumutsu). The rules are the asset; this file
> outranks the implementation. 22 items, 3 rarity tiers, one law: **passing a
> market ALWAYS opens the stall.** SSOT in code: `lib/party/party_models.dart`
> (`kItemCatalog`, `kCatalogPrices`) + `lib/party/party_controller.dart`
> (shelf, effects). Tests: `test/party/items_catalog_test.dart`.

## The market law

- **Every pass opens the shop.** Walking onto (or through) a `shop` space
  pauses the walk in `shopOffer` for *every* player, broke or rich. Perusing
  is free; buying is gated by diamonds. (The old affordability gate survives
  only for pre-catalog saves — `bazaar: false`.)
- **The shelf is drawn fresh per visit** off the random tape (host-authoritative
  online): **2 distinct commons + 1 rare**, and roughly **1 visit in 4** an
  **exotic** joins the shelf.
- **Buying keeps the stall open.** Bought items leave the shelf; the potato is
  always for sale; **LEAVE MARKET** is the only exit. The pack caps at 3 items
  (`kMaxItems`).
- A **potato costs 20 💎** (`kPotatoPrice`). Every exotic costs MORE than a
  potato — game-benders are priced against the win condition.

## The catalog — 22 items

### Common (10) — everyday shelf stock, 5–10 💎

| Item | 💎 | Effect |
|---|---|---|
| Coupon | 5 | Your next market purchase is half price (round up), then it's spent |
| Tailwind | 6 | +2 on your next roll |
| Spark | 8 | +4 diamonds, immediately |
| Sabotage | 8 | Every rival's next roll is HALVED (round up), once each |
| Pickpocket | 8 | Steal 3 diamonds from the leading rival (Strong Bond blocks) |
| Diamond Magnet | 8 | Path diamonds count DOUBLE for your next walk |
| Second Wind | 9 | +1 on your rolls for your next 3 turns |
| Mitochondria | 9 | +3 on your next roll |
| Void Shield | 10 | Blocks your next diamonds loss (spaces, ghosts, events) |
| Catalyst | 10 | Your next mini-game diamonds award is doubled |

### Rare (5) — four roll-improvers + the potato lock, 12–18 💎

| Item | 💎 | Effect |
|---|---|---|
| Booster | 12 | +5 on your next roll |
| Loaded Dice | 14 | Your next roll counts DOUBLE (2×) |
| Accelerator | 14 | Your next roll uses TWO dice |
| Strong Bond | 14 | Blocks the next swap/steal against you — including the Masher's potato grab |
| Mega Booster | 18 | +10 on your next roll |

### Exotic (7) — expensive, don't always show, 25–35 💎

| Item | 💎 | Effect |
|---|---|---|
| Swapper | 25 | TARGETED: swap board positions with a chosen player |
| Freeze Ray | 26 | TARGETED: a chosen player skips their next turn |
| Triple Dice | 26 | Your next roll uses THREE dice added together |
| Warp Potato | 30 | TARGETED: teleport to any warp node (every market + gateway/power-up space, path order, max 16) |
| Toll Contract | 30 | An op charges rivals 5 💎 at EVERY fork, through the END of next round, paid to you |
| Game Rigger | 32 | YOU pick the next mini-game (from a tape-drawn hand of 4) |
| Golden Stakes | 35 | Declared before the game: the next mini-game's winner takes ×3 diamonds AND a potato |

## Effect rulings

- **Roll math order:** dice sum → +bonuses (mitochondria, tailwind, boosters,
  second wind, ATP) → Loaded Dice ×2 → **Sabotage ÷2 (round up), last**.
- **Triple Dice trumps Accelerator**; an armed Accelerator is NOT consumed
  under it (it waits for a later roll).
- **Sabotage** is unblockable (it is neither a swap nor a steal) and never
  hits its user.
- **Pickpocket** targets the leading rival (potatoes, then diamonds); Strong
  Bond blocks it and is consumed, like every steal.
- **Toll Contract:** active from use through the end of the NEXT round; the
  holder rides toll-free; a broke rival pays what they have. Tolls transfer,
  never burn.
- **Game Rigger** fires when the round's mini-game would be drawn: play holds
  in the `gamePick` phase until the holder picks (a real logged input — the
  player drives). Never re-offers the game just played.
- **Golden Stakes** arms until the next SCORED mini-game (a vote-skipped round
  keeps it armed). Winner's award is tripled before Catalyst doubling; ties at
  rank 0 all collect.
- **Targeted items** (Swapper, Freeze Ray, Warp Potato) encode their target in
  4 bits (`useItemOn`, value = `item.index * 16 + target`) — warp destinations
  are therefore capped at 16 nodes.

## Wire/save compatibility (load-bearing)

- `PowerUp` is serialized **by index** — the 13 catalog values are APPENDED;
  never reorder.
- Saves carry `bazaar: true`. Absent key ⇒ pre-catalog save: replay keeps the
  affordability-gated, single-purchase market and the fixed 9-item
  `kItemShop` / `kItemPrices` so old input logs stay aligned.
- Shelf draws, exotic appearances, and the rigger's hand all come off the
  RandomTape — host-recorded, client-replayed, lockstep-safe.
