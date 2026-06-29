# GAME.md — Build the Chain

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale:** supplyChain (`BioScale.supplyChain`)
- **Game id:** build_chain
- **One-line concept:** Drag shuffled supply-chain STAGE tiles (Farm → Wash/Sort →
  Process → … → Store) into a row of ordered slots, upstream → downstream. Get the
  order right and goods FLOW; get it wrong and the chain visibly BREAKS.
- **Role:** solo high-score (also drops into party rotation)
- **Type:** primer — teaches the STRUCTURE & VOCABULARY of a supply chain.

---

## What it teaches (the E lives in the mechanic)

A supply chain is a **named, ordered sequence of stages** that carries a product from
raw material to customer. The whole game is: name the stages and put them in order.
You cannot warehouse before you process; you cannot sell before you stock. **Order is
the lesson**, and the broken arrow is the feedback. Full write-up in `EDUCATION.md`.

---

## The potato supply chain (the stages taught)

Each tile carries a one-line ROLE that pops on tap or placement:

| Stage | Role (the vocabulary) |
|---|---|
| 🌱 Farm | Grow and harvest the raw potatoes. |
| 🚿 Wash & Sort | Clean off the dirt and grade spuds by size and quality. |
| 🔍 Quality Check | Inspect the batch and reject bruised or green potatoes. |
| 🏭 Process | Cut and cook the potatoes into fries and chips. |
| 📦 Packaging | Seal the product into bags and boxes. |
| ❄️ Cold Storage | Keep the product frozen and fresh until it ships. |
| 🏬 Warehouse | Hold finished stock until stores place an order. |
| 🚚 Distribute | Load the trucks and haul product out to stores. |
| 🏪 Store | Stock the shelves and sell to the customer. |
| 🚢 Export Port | Ship product overseas to reach distant markets (branch ending). |

Canonical order = the `rank` field (0…9). The correct chain for any round is its
chosen subset of stages sorted by rank.

---

## Rules (canonical)

1. **Two phases per round: ASSEMBLE, then FLOW.**
2. **Assemble.** A row of empty numbered slots sits up top; a tray of shuffled stage
   tiles sits below. **Drag** a tile into a slot. Slot *i* expects the *i*-th stage of
   the correct (rank-sorted) order.
3. **Per-placement feedback.** Drop a tile in its correct slot → it locks with a teal
   border, scores, and the role card shows. Wrong slot → amber border, streak resets.
4. **The arrow shows the break.** Between two filled slots the connecting arrow is
   **teal** when both are correctly ordered (goods flow), **red** when both are filled
   but out of order (the chain snaps here), and faint when not yet linked. This is how
   "order matters" is taught visually.
5. **Rearrange freely.** Tap a placed tile to pull it back to the tray; drag tiles
   between slots. Tapping any tray tile shows its role (free vocabulary).
6. **Lock-in.** When every slot is filled **and** every slot is correct, the chain
   locks: completion bonus + a spark burst, then FLOW begins.
7. **Flow.** Potatoes run the line left → right. A stage occasionally **STALLS** (turns
   red, flashes "TAP!") and halts the potato. **Tap the stalled stage** to clear it
   (+points) and keep goods moving. Ignore it and after a short window the goods back
   up (no points, the run is no longer "clean"). Deliver the goal count of potatoes to
   finish the phase.
8. **Escalation.** Each completed round increments the level: chains get longer (4 → 7
   stages), mix in the advanced stages (Quality Check, Packaging, Cold Storage), throw
   the occasional **export branch** (ends at the port, not the store), and stalls get
   more frequent with a tighter tap window.

---

## Controls

- **Drag** a tile → drop it into a slot (or back to the tray).
- **Tap** a placed tile to remove it; **tap** any tile to read its role.
- **Tap** a stalled stage during flow to clear it.

All rendering is a single Ticker-driven `CustomPainter`. No raster assets — stage icons
are emoji drawn via `TextPainter`; everything else is canvas primitives + `fx.dart`.

---

## Scoring

| Event | Score |
|---|---|
| Correct placement | +15 + (streak × 2) |
| Chain locked (all in order) | +50 + level×12 + speed bonus (≤60) |
| Clean flow (no missed stalls) | +25 |
| Stall cleared during flow | +12 |
| Potato delivered (flow upkeep) | +5 each |

`session.noteStreak` is fed by consecutive correct placements and clean chains.

---

## Win / end condition

Timed score attack — the host owns the 60-second clock, countdown, score HUD and
results. The game just keeps producing chains; the more chains you assemble cleanly and
the faster you order them, the higher the score when time expires.

---

## Difficulty curve

`level = chains completed`. Drives: chain length `(4 + level).clamp(4,7)`, inclusion of
advanced stages and export branches (`level ≥ 3`), stall chance `(0.16 + level×0.05)`
capped at 0.5, and stall tap window `(2.2 − level×0.12)` floored at 1.1 s. Level 0 is a
fixed gentle primer: Farm → Wash → Process → Store.

---

## Session / resume

The host owns session lifecycle (close + re-enter = the S in GAMES). The game holds no
cross-session persistence; each mount reseeds from `microsecondsSinceEpoch`, so every
run draws a fresh chain order. To resume mid-run you would persist: `score` (host),
`_level`, the current `_correct` order, and which slots are filled. Field potatoes are
ephemeral — restart the flow from the saved chain.

---

## Implementation notes

**File:** `lib/games/supply_chain/build_chain/build_chain_game.dart` — class
`BuildChainGame`. Self-contained: imports only `../../fx.dart`, `../../mini_game.dart`,
and Flutter. Single `AnimationController` ticker; `_ChainPainter` repaints off it and
reads the live state. Drag mutates tile `x/y` directly (no per-frame `setState`).

**Tunable constants (inline):** placement points `15 + streak×2`; completion `50 +
level×12`; clean bonus `25`; stall clear `12`; delivery `5`; belt speed `3.0` stops/s;
`_deliverGoal = 3`; stall chance/window as above.
