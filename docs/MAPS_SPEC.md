# Board Maps — Design Spec

Three boards for the main game (the Mario-Party layer). Each is one leg of the
avatar-in-the-void journey — **Down the Hole**, **Into the Void**, **Through the
Aether** — and each has **exactly 88 landing spots**.

All three reuse the existing engine (`party_models.dart`): `BoardSpace` with
`SpaceType { gain, lose, powerUp, event, shop }`, `nexts` for forks/jumps, and
`BoardSection` for themed regions. What differs per map is the **topology** (the
shape of the path) and the **theme** (which scales/lore each region maps to).
Landing on a spot in a scale-region triggers that scale's mini-game chooser.

## Economy, rounds & end-game (all maps)

**Two currencies.**
- **Potatoes** — the win metric. **Most potatoes at game end wins.** A player's
  total = potatoes bought in-game **+** potatoes won from end-game awards.
- **Diamonds** — Pac-Man-style collectibles strewn on the path. You **eat the
  diamond on every space you travel through** on your roll (the whole move, not
  just the landing space), so taking your own/longer route is how you grab more.
  Diamonds **respawn once a player completes a full traversal** of the board.
  Diamonds convert to a potato only via the end-game "Most Diamonds" award.
- **Paydirt / ATP** (current engine) stay as in-round spending — roll boosts and
  the potato purchase below.

**Buying potatoes in-game.** Reaching a map's **destination anchor** (the final
spot, `order 87`) lets you **buy a potato with paydirt** — one climactic buy
point per map:
- Down the Hole → the **spiral center**.
- Into the Void → the **exit**.
- Through the Aether → the **end**.

The anchor is both the race target and the potato shop; diamonds respawn when a
player reaches it (completes the traversal).

**Rounds.** Players take board turns; **after every full turn-cycle (all players
have moved), a mini-game round fires**, drawn from the map's 8 scales. Round
finishes feed the "Most Round Wins" / "Most L's" tallies.

**End-game potato awards.** At game end, superlative potatoes are handed out —
**3 on Down the Hole, 6 on Into the Void, 9 on Through the Aether** (the journey
escalates). Each award = +1 potato to its leader. These stack on the potatoes
collected during play, so the finish is a big swing.

| Award | Hole (3) | Void (6) | Aether (9) |
|---|:--:|:--:|:--:|
| Most Round Wins | ✓ | ✓ | ✓ |
| Most Diamonds | ✓ | ✓ | ✓ |
| Most Stolen-From* | ✓ | ✓ | ✓ |
| Most Taps |  | ✓ | ✓ |
| Most Swipes |  | ✓ | ✓ |
| Most L's (round losses) |  | ✓ | ✓ |
| Most Items Used |  |  | ✓ |
| Most Items Held (final) |  |  | ✓ |
| Fewest Steps |  |  | ✓ |

*Most Stolen-From: rewards the player disrupted/robbed most. **If no one stole
all game, everyone gets this potato** (consolation).

**Per-player stats the engine must track:** roundWins, roundLosses (L's),
diamonds, stolenFromCount, taps, swipes, itemsUsed, itemsHeldFinal, stepsTaken.

## Shared spot model

Every spot carries, in addition to the engine fields:
- `order` — 0…87, its position along the path.
- `x, y` — normalized coordinates [0..1] for rendering the board shape.
- `nexts` — usually `[order+1]`; multiple at forks; a jump target for
  ladders/snakes/slides.

## Shared space rhythm (per ~11-spot region)

- **spot 0 of a region** → `powerUp` (that region's themed power).
- **1 spot** → `event`.
- **2–3 spots** → `lose`.
- **remainder** → `gain` (gain-biased, like the current board).
- **2 `shop` spots per map** at fixed points (≈⅓ and ⅔ along the path).
- Forks/jumps are the map's signature mechanic (spiral cut-throughs, ladders &
  snakes, rainbow slides).

Sums to 88 per map. Regions = 8 per map (≈11 spots each) unless the topology
dictates otherwise (Into the Void uses 10 lanes; see below).

---

## 1. Down the Hole — uzumaki spiral (zoom IN)

**Shape.** An Archimedean (uzumaki) spiral of 88 spots winding **inward**:
`order 0` sits on the outer rim, `order 87` at the dead center — the bottom of
the hole. ~3.5 turns. Render: `angle = order * k`, `radius` shrinks linearly
from 1.0 → 0.0; `x = 0.5 + radius*cos(angle)*0.5`, `y = 0.5 + radius*sin(angle)*0.5`.

**Theme — the descent into the infinitesimal.** As you spiral down, scales
shrink. 8 bands, outer→center (~11 spots each):

| Band (outer→center) | Scale | Power-up theme |
|---|---|---|
| Surface | organism | harvest charm |
| Flesh | organ | growth |
| Weave | tissue | layer-lock |
| Chamber | cell | mitosis |
| Engine room | organelle | mitochondria |
| Bonds | molecular | catalyst |
| Grains | atoms | strong bond |
| The floor | particles | accelerator |

**Signature mechanic — spiral cut-throughs.** A few spots fork "across" the
spiral to an inner arm (skip a turn) — fast descent, riskier (lose-heavy) spots.

---

## 2. Into the Void — snakes & ladders (the dream realm)

**Shape.** `4 + (10 lanes × 8) + 4 = 88`.
- **Entry (4 spots)** — stepping off the edge into the dream (`order 0–3`).
- **Body (80 spots)** — a 10-lane × 8-row grid traversed **boustrophedon**:
  lane 0 bottom→top (up 8), step right one lane, lane 1 top→bottom (down 8),
  right one, lane 2 up 8… `order 4–83`.
- **Exit (4 spots)** — the return / reset threshold (`order 84–87`).

Render on an 8-tall grid; entry/exit as short stubs off the left/right edges.

**Theme — the Void cosmogony.** The 10 lanes are 10 dream-stations:

| Lane | Station | Maps to scale |
|---|---|---|
| 1 | The Void | nothings |
| 2 | Something | somethings |
| 3 | The Rainbow | somethings |
| 4 | The Aether | particles |
| 5 | Yoomi | multiverseAll |
| 6 | Oomi | multiverseAll |
| 7 | Soomi | universeAll |
| 8 | Bobo, the Watcher | cosmicStructures |
| 9 | Jellyfish Drift | infinities |
| 10 | The Reset | infinities |

**Signature mechanic — ladders & snakes** (the forks/jumps):
- **Ladders** (≈4): jump forward/up to a later lane — a lucky lift through the
  dream. Land on a few designated spots to climb.
- **Snakes** (≈4): slip back/down to an earlier lane — the void pulls you under.
- Implemented as `nexts` jump targets to non-adjacent `order`s.

---

## 3. Through the Aether — Candyland (zoom OUT)

**Shape.** A long meandering **S-curve** of 88 spots — gentle left-right
switchbacks descending the screen (the Candyland ribbon), not a tight grid.
Render: a smoothed polyline of 88 points sweeping across and down.

**Theme — the ascent into everything.** 8 colored regions (~11 spots each),
world → cosmos:

| Region | Scale | Power-up theme |
|---|---|---|
| Meadow | ecosystem | balance |
| Farmland | farmSystem | rotation |
| Worlds | planets | gravity |
| Suns | solarSystems | orbit |
| Galaxies | galactic | starlight |
| The Web | cosmicStructures | link |
| Manyfold | multiverseAll | merge |
| All | universeAll | everything |

**Signature mechanic — rainbow slides.** A few spots are slide-heads that
launch you forward across a region boundary (Candyland's shortcuts) — pure
upside, but rare and fixed, so routing around them is a skill.

---

## Cards — two decks (all maps)

Some tiles are **card tiles**: land on one and you draw a card — sometimes an
instant effect, sometimes a **decision** (choose between options). Two decks,
two tile types:

- **`cardCommon` — Tater Cards.** Frequent, low-variance, mostly upside with the
  odd small cost. These replace the old `event` spots (so they're common).
- **`cardWild` — Void Cards.** High-variance big swings that **can be an
  objectively bad draw**, and the deck that hands out **items**. On Down the Hole
  and Through the Aether they're **rare** (~2–3, on risky/deep spots). On **Into
  the Void the deck is wild-only** — every card tile draws a Void Card and there
  are **no Tater (common) cards at all**, fitting the dangerous dream realm.

### Card data shape
```
Card {
  id, deck (common|wild), title, text,
  isDecision (bool),
  effects: [ Effect ]            // applied when drawn / when no decision
  options: [ { label, effects } ] // present only when isDecision
}
Effect kinds: gainPaydirt(n) · losePaydirt(n) · tithe(pct)        // rivals pay you %
            · gainDiamonds(n) · loseDiamonds(n) · allLoseDiamonds(frac)
            · gainItem(item) · loseItem(random) · stealItem(target)
            · gainAtp(n) · move(n) · teleport(start|anchor)
            · swapPaydirt(randomRival) · coinFlip(win:[..], lose:[..])
            · gainPotato · losePotato                              // wild only, rare
```

### Common deck — Tater Cards (≈10)
| Title | Effect |
|---|---|
| Tithe | Each rival gives you 10% of their paydirt |
| Windfall | +15 paydirt |
| Diamond Vein | Eat 6 diamonds now |
| Second Wind | +2 ATP |
| Hop To It | Move forward 3 |
| Toll Booth | −8 paydirt |
| Generous Spud *(decision)* | **A:** +10 paydirt · **B:** give 5 to each rival, gain a power-up |
| Back Alley *(decision)* | **A:** move back 2, +12 paydirt · **B:** stay put |
| Pocket Find | +8 paydirt and +3 diamonds |
| Even Split *(decision)* | **A:** swap paydirt with the player behind you · **B:** decline |

### Wild deck — Void Cards (≈10)
| Title | Effect |
|---|---|
| Void Swap | Swap your **entire** paydirt with a random rival (can hurt) |
| The Watcher's Gift | Coin-flip: **win** a rare item · **lose** skip your next round |
| Black Hole | Everyone (you too) loses **half** their diamonds |
| Diamond Heist | Steal 10 diamonds from the current leader |
| Reset | Coin-flip: **win** teleport to the anchor · **lose** teleport to start |
| Potato Gamble | Coin-flip: **win** a potato · **lose** −30 paydirt |
| Inventory Raid | Take a random item from a rival (if you have none, they take from you) |
| Mirror | Set your paydirt equal to the leader's (great behind, bad ahead) |
| Gnome Bargain *(decision)* | **A:** −1 potato now, +60 paydirt · **B:** nothing |
| Aether Tax | All players −15 paydirt; you −0 |

*Items granted by cards plug into the existing power-up/item system
(`kMaxItems = 3`). Decks are shared across maps for now; per-map flavor skins are
a later option.*

## Placements (proposed — redline freely)

Exact `order` indices (0–87). Power-ups open each region; one **Tater (common)
card** mid-region (the `event@` column below); 2–3 loses; rest gain; 2 shops/map;
a few **Void (wild) cards** on the riskiest spots; anchor at 87. (The `event@`
spots are now `cardCommon` tiles.)

### Down the Hole — 8 bands × 11, spiral inward
| Band | Orders | Scale | powerUp@ | event@ | lose@ |
|---|---|---|--:|--:|--:|
| Surface | 0–10 | organism | 0 | 5 | 3, 8 |
| Flesh | 11–21 | organ | 11 | 16 | 14, 19 |
| Weave | 22–32 | tissue | 22 | 27 | 25, 30 |
| Chamber | 33–43 | cell | 33 | 38 | 36, 41 |
| Engine | 44–54 | organelle | 44 | 49 | 47, 52 |
| Bonds | 55–65 | molecular | 55 | 60 | 57, 63 |
| Grains | 66–76 | atoms | 66 | 71 | 68, 74 |
| Floor | 77–87 | particles | 77 | 82 | 79, 84 |

- **Shops:** 29, 58. **Anchor (buy potato):** 87 (center).
- **Void (wild) cards:** 41, 69, 84 (deeper = riskier).
- **Spiral cut-throughs (forks, inner-arm skips, lose-heavy):** 14→25, 36→47, 58→69.

### Into the Void — 4 entry + (10 lanes × 8) + 4 exit
Lanes are 8 spots; orders run boustrophedon from 4.
| Lane | Orders | Station | Scale |
|---|---|---|---|
| 1 | 4–11 | The Void | nothings |
| 2 | 12–19 | Something | somethings |
| 3 | 20–27 | The Rainbow | somethings |
| 4 | 28–35 | The Aether | particles |
| 5 | 36–43 | Yoomi | multiverseAll |
| 6 | 44–51 | Oomi | multiverseAll |
| 7 | 52–59 | Soomi | universeAll |
| 8 | 60–67 | Bobo, the Watcher | cosmicStructures |
| 9 | 68–75 | Jellyfish Drift | infinities |
| 10 | 76–83 | The Reset | infinities |

- **Entry:** 0–3. **Exit / anchor:** 84–87 (buy potato at 87).
- **Ladders (jump forward):** 9→28, 21→44, 39→61, 55→78.
- **Snakes (slip back):** 33→12, 50→27, 67→41, 81→58.
- **Void (wild) cards — wild-only map, NO Tater cards:** 7, 17, 25, 35, 43, 59, 71, 79
  (≈one per lane; every card tile here is chaos).
- **Shops:** 30, 60. **Power-ups:** lane starts (4, 12, 20, 28, 36, 44, 52, 60, 68, 76).

### Through the Aether — 8 regions × 11, Candyland S-curve
| Region | Orders | Scale |
|---|---|---|
| Meadow | 0–10 | ecosystem |
| Farmland | 11–21 | farmSystem |
| Worlds | 22–32 | planets |
| Suns | 33–43 | solarSystems |
| Galaxies | 44–54 | galactic |
| The Web | 55–65 | cosmicStructures |
| Manyfold | 66–76 | multiverseAll |
| All | 77–87 | universeAll |

- **Shops:** 29, 58. **Anchor:** 87 (end).
- **Void (wild) cards:** 32, 54, 76.
- **Rainbow slides (forward shortcuts):** 18→30, 40→55, 64→80.
- Power-ups at region starts (0, 11, 22, 33, 44, 55, 66, 77); event mid-region.

## Build order

1. This spec (done) → confirm themes/lore.
2. A `GameMap` data layer: `{ id, name, sections, spaces[88], jumps }` for the
   three maps, generated from the topologies above (spiral / grid / S-curve give
   the `x,y`; rhythm gives the `SpaceType`; forks give ladders/snakes/slides).
3. A **map picker** in the party setup flow.
4. A board renderer that draws each topology (spiral, grid, ribbon).

**Status: LOCKED** — topologies, themes, economy, the Into-the-Void lane lore,
and all placements (shops, anchors, ladders/snakes/slides, spiral cut-throughs)
are confirmed. Ready to build.
