# TODO_strategy.md — Fork Strategy Audit (all 3 maps)

> **Design law under test:** every fork must have a *reason* to go each way, and that
> reason must be readable from the player's current state (diamond count, items held,
> position in the race, awards standing). A fork where one branch is always correct —
> or where neither branch matters — is dead weight.
>
> Sources: `lib/party/maps/game_map.dart` (fork/shop/tile placements),
> `lib/party/party_controller.dart` (walk/shop/ghost mechanics),
> `lib/party/party_models.dart` (prices), `docs/MAPS_SPEC.md`, `docs/ITEMS_SPEC.md`.
>
> **STATUS 2026-07-12 (evening, yumutsu):** the Down the Hole items are BUILT — shop
> 29→24 (cut 14→25 skips the market), THE VAT'S HEAT (rules ≥ 5: deep bands skim
> 1/2/3/4 💎, Void Shield blocks, Shack safe — the checkpoints' reason to exist), and
> the fork chooser now names each branch's trade via `PartyController.previewBranch`
> (PARTY UX LAW). The Shack-parking farm was independently fixed the same day (rules
> ≥ 4 clock-out: the Shack is a checkpoint, not a parking spot). Sections below keep
> the original audit for the reasoning; per-item status is marked inline. Void +
> Aether TODOs remain open.

## The currencies a fork can trade (what exists in code today)

| Lever | Mechanic (verified in code) |
|---|---|
| **Speed to the Shack** | Anchor (order 87) pays +1 potato on arrival ("clocking in") and triggers the global diamond respawn. |
| **Diamonds en route** | Pac-Man economy: you eat 1 diamond on **every space you travel through**, not just landings (`_stepTo`). Longer route = strictly more diamonds. |
| **Shop access** | The market catalog (ITEMS_SPEC.md, 2026-07-12) superseded the old affordability gate: **every pass opens the stall**, broke or rich; perusing is free, buying is diamond-gated. Potato = 20 💎; commons 5–10, rares 12–18, exotics 25–35. |
| **Power-up tiles** | Land on a region's first tile → free themed power-up. |
| **Risk exposure** | Lose tiles (−5 💎), wild cards (big swings), ghosts (up to −6 💎 on their tile, blocked by VOID SHIELD), Peeler/Masher card mischief, map bosses. **All fire on LANDING only** — passing through a lose/wild tile costs nothing. |
| **End-game awards** | Per-map superlatives (+1 potato each): Hole 3, Void 6, Aether 9. `fewestSteps` / `mostItemsUsed` / `mostItemsHeld` exist only on Aether. |

**Key asymmetry that makes the shop-fork thesis work:** the shelf is worthless to a
broke player and load-bearing to a rich one (protection, roll control, game-benders).
So the *long* route past a market is pure upside when you're flush — diamonds eaten +
the buy window — and mostly time-loss when you're broke. The fork logic "poor → cut,
rich → market" is economically sound **if and only if the cut-through actually skips
the shop** — which, as of the 2026-07-12 placement change, it does.

---

## 1. DOWN THE HOLE — audit

Fork inventory (from `buildDownTheHole()`):

- **Cut-throughs (player-choice forks):** `14→25`, `36→47`, `58→69` — skip one spiral band (~10 spots).
- **Bail-up checkpoints (player-choice forks):** `22→11`, `44→33`, `66→55` — retreat one band toward the surface.
- **Shops:** ~~`29`~~ **`24` (moved 2026-07-12)**, `58`, anchor `87` (the Shack). **Wild cards:** `41, 69, 84`. **Boss:** Boiling Vat.

### Fork A — order 14: walk (→15) or cut (→25)

| | Long route (15…25) | Cut (→25) |
|---|---|---|
| Diamonds | ~10 eaten + gain tiles | ~0 |
| Tiles crossed | card @16, power-up @22, lose @19 | none |
| Shop | **passes shop 29 either way** | **also passes shop 29** |
| Position | — | ~10 spots ahead |

**Verdict (pre-change): a real but shallow trade (greed vs. speed). NOT the shop
strat.** The shop at 29 sat *after* the cut-through's exit (25), so market access was
never at stake. **✅ FIXED 2026-07-12: shop moved 29 → 24** — cutting now skips the
market; the long way is the diamond road with the shelf at its end.
- ⚠️ The spec's "cut-throughs drop you on risky spots" is soft in practice: 25 is a
  lose tile, but lose/wild fire **on landing only**. You land on 25 only if your roll
  ends exactly there (you choose the branch mid-walk, then keep stepping).

### Fork B — order 36: walk (→37) or cut (→47)

Same shape as Fork A. Long route crosses card @38, **wild card @41**, power-up @44
(which is also checkpoint fork 44). Cut exits on lose tile 47. Both routes still hit
shop 58. **Verdict: same shallow trade; shop never at stake.**

### Fork C — order 58: walk (→59) or cut (→69)

The fork sits **on the second shop itself** — you decide at the market door, *after*
your buy window fires. Long route: card @60, power-up @66 (+ checkpoint 66), ~10
diamonds. Cut exits onto **wild card 69**, one band from the Floor. **Verdict: the
best-shaped fork on the map today** — "I just shopped; do I grind the Bonds band for
diamonds or sprint for the Shack?" Late-game position (awards race, others' distance
to the Shack) genuinely changes the answer.

### Checkpoints — orders 22 / 44 / 66: continue down or bail up one band

**✅ FIXED 2026-07-12 via option 3a below — THE VAT'S HEAT (rules ≥ 5):** ending a
walk in the four deepest bands skims 1/2/3/4 💎 (Engine/Bonds/Grains/Floor; Shack
safe; Void Shield blocks, consumed). Bailing up now trades tempo for a cooler
commute; checkpoint 66 (Grains, −3/landing) is the sharpest call.

**Verdict (pre-change): DEAD CHOICE. There was no reason to ever bail up.**
- The diamonds behind you are already eaten (they respawn only when someone reaches
  the Shack), so backtracking re-walks a stripped trail.
- The win condition (potatoes) lives at the bottom: Shack +1, shops sell the only
  buyable potatoes, and both shops are at/below you when the choice appears.
- The Boiling Vat "the deeper the hotter" pressure that would justify bailing is
  **flavor only** — no escalating-depth mechanic exists in the controller.
- Sole marginal use: bail @66→55 re-crosses shop 58 for a second buy window.

### Strategy-breaking interaction to verify

**✅ CONFIRMED REAL AND FIXED 2026-07-12 (rules ≥ 4 clock-out, separate session):**
parked farming at the anchor was possible exactly as suspected. Now the walker
returns to square one when the Shack turn is confirmed — the commute loops, and
routing strategy stays live for the whole game.

### Proposed changes (the shop-fork strat, made real)

1. ✅ **Move shop 29 → 24.** The market then sits on the last spot of the long route,
   right before the cut-through's exit (25) merges back in. Fork A becomes the thesis
   fork: **broke → cut ahead and skip the market you couldn't use; rich → take the
   long, diamond-paved road and hit the shelf** (protection items: voidShield 10 💎
   blocks ghosts + lose tiles, strongBond 10 💎 blocks steals/swaps — exactly the
   "protect my diamonds" buy).
2. ✅ **Keep Fork C as-is** (fork ON the shop) — it's a different, also-valid shape:
   shop first, then commit. Two shop-fork grammars on one map is variety, not
   inconsistency. (Alternative if we want both cut-throughs to skip a market: move
   shop 58 → 46 instead; pick one.)
3. ✅ **Give the checkpoints a reason or delete them.** Landed as option a
   (`vatHeatFor` in game_map.dart, applied in `_finishStep`, rules ≥ 5,
   tests in `test/party/vat_heat_test.dart`). Options were, in preference order:
   - **a. Implement the Boiling Vat as real depth pressure** (matches existing lore
     "the deeper you go, the hotter the water"): e.g. below band N the Vat skims
     diamonds per turn, or deep lose tiles hit harder. Bailing up = paying tempo to
     escape the heat with your diamond stack intact → press-your-luck becomes real.
   - b. Bail-up pays a small guaranteed reward (re-arm the band's power-up tile for
     you) so it's a "regroup" play when broke and far from a shop.
   - c. Delete them (fall back to `nexts: [order+1]`) — a dead fork is worse than
     no fork.
4. ✅ **Fork UI must show the trade** (per PARTY UX LAW): `previewBranch` computes
   each branch's live worth (diamonds on the stretch, market, power-up, heat delta,
   risky ground) and `_pathOption` renders it — THE LONG WAY / CUT-THROUGH /
   BAIL UP / PRESS ON each name what they cost and pay.
5. ⬜ Optional sharpener: make cut-through **entry spots landing-guaranteed** (treat the
   branch target as a forced stop) so "riskier" is real, not roll-lottery. Only if we
   want the cuts to bite harder — decide after 1–3.

---

## 2. INTO THE VOID — audit

Fork inventory (from `buildIntoTheVoid()`):

- **Player-choice forks: NONE.** Ladders (`9→28, 21→44, 39→61, 55→78`) and snakes
  (`33→12, 50→27, 67→41, 81→58`) are `jumps` — **automatic on landing** (`_finishStep`),
  not decisions.
- Shops: `30`, `60`. Wild-only card map (8 wild tiles, no Tater cards). Bosses: Vat + Grater.

**Verdict: the map has zero fork strategy today; its strategy is roll-manipulation,
and it's invisible.** The real decisions are (a) shop buy/pass, (b) wild-card decision
cards, and (c) **item-steered landings**: mitochondria (+3 next roll), loadedDice
(roll counts double), accelerator (two dice) let a player aim at ladder heads and
step past snake mouths. That is a genuine skill layer — but the game never shows
distances, so it plays as luck.

**TODOs:**
- [ ] Surface jump geometry at roll time: "ladder in 6 · snake in 3" (or highlight
  reachable heads/mouths on the board) so roll-item play becomes a visible strategy.
- [ ] Consider converting snakes into **pay-to-avoid decisions** ("grab the ledge:
  −5 💎 or slip to lane 2") — turns pure bad luck into a resource decision, on the
  map whose whole identity is risk. Rich players buy their way out; broke players
  ride the snake. Same rich/poor grammar as the Hole's shop forks.
- [ ] Checked for accidental strategy: snake targets (12, 27, 41, 58) don't interact
  with this map's shops (30/60). Nothing hidden there; fine as-is.

---

## 3. THROUGH THE AETHER — audit

Fork inventory (from `buildThroughTheAether()`):

- **Player-choice forks: NONE.** Rainbow slides (`18→30, 40→55, 64→80`) are auto
  jumps on landing, pure upside.
- Shops: `29`, `58`. Wild cards: `32, 54, 76`. Boss: Cheese Grater.
- Awards (9, most of any map) include **fewestSteps, mostItemsUsed, mostItemsHeld**.

**Verdict: no fork strategy, but the award set creates a latent routing tension the
topology doesn't express.** `fewestSteps` (+1 potato) rewards riding slides;
`mostDiamonds` rewards walking the longest trail. Those pull in opposite directions —
that IS a fork, philosophically, but the board never asks the question. Slide 18→30
also silently **skips shop 29** — an accidental market-skip rather than a presented
choice.

**TODOs:**
- [ ] Add 1–2 **player-choice forks** that make the award tension explicit: a "scenic
  loop" branch (longer, diamond-rich, crosses the market → serves mostDiamonds and
  shopping) vs. the direct ribbon (serves fewestSteps). This is the non-market
  strategic fork flavor — the decision is driven by *which award you're racing*,
  not by wallet size.
- [ ] Decide on slide 18→30 skipping shop 29: either embrace it (the slide is the
  "skip the market" express — mirror of the Hole strat, granted by landing skill
  instead of choice) and say so in the slide callout, or re-place the shop so slides
  never mute a buy window. Recommend embrace.
- [ ] Items are this map's award engine (mostItemsUsed/Held): the shop pitch on
  Aether should sell that ("items ARE points here") — one line in the shop sheet.

---

## Cross-map principle (fold into MAPS_SPEC when placements change)

**A fork is only strategic if the two branches price out differently against at least
two of: wallet (diamonds), race position, items held, awards standing.** Placement
rule of thumb going forward: shops live on the *long* branch, immediately before the
merge point; risk tiles live on the *short* branch's landing zone; and the
choose-branch UI always names the trade.
