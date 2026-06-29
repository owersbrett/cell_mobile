# GAME.md — Companion Planting

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** farmSystem
- **Game id:** companion_planting
- **One-line concept:** Place crop tiles on a garden grid so orthogonal NEIGHBORS
  help, not hurt — Three Sisters thrive, fennel poisons the bed.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

A garden plot is a tiny ecosystem. Some plants are allies: beans pull nitrogen from
the air and feed their corn neighbours; corn gives beans a pole and shades squash;
marigolds and basil drive pests away from tomatoes. Others are saboteurs: fennel
leaks growth-inhibiting chemicals into the soil and stunts almost everything near it;
onions choke the nitrogen-fixing bacteria on bean roots; potatoes and tomatoes are
both nightshades and pass blight and beetles between them.

You're handed crop tiles and an empty bed. Where you put each one is the whole game —
the same six tiles can make a flourishing plot or a wilting one. This is real
companion planting compressed into a placement puzzle.

---

## Rules (canonical)

1. **A plot is a grid of soil cells.** It starts at 3×3 and grows as you harvest
   more plots (up to 5×5).

2. **A hand of up to 5 crop tiles waits in the tray.** Drag a tile onto any empty
   cell to plant it. The tray refills until the whole plot is full.

3. **Only orthogonal neighbours (up/down/left/right) interact.** On each placement,
   every already-planted neighbour is scored:
   - **Friend** (e.g. corn+beans, marigold+tomato, carrot+onion): **+12** each, and
     a green **"+helps"** cue flashes.
   - **Foe** (e.g. fennel+anything, onion+beans, potato+tomato): a red **"−hurts"**
     cue flashes; it breaks your combo and risks a wilt in the growth phase.
   - **Neutral:** no effect.

4. **Combo.** A "clean" placement (≥1 friend, 0 foes) extends the combo and adds a
   `combo × 4` bonus. Any foe-adjacent placement resets the combo to 0.

5. **Growth phase.** When the plot fills, every plant's net neighbour balance
   (friends − foes) is tallied. Net-positive plants **thrive** (+8 × net, green glow
   + grow); net-negative plants **wilt** (shrink + brown). A plot with **zero** foe
   adjacencies anywhere is a **FLAWLESS PLOT**: +25 + level×10, and extends the
   flawless streak (`session.noteStreak`).

6. **Accelerate.** Each harvested plot raises the level: bigger plots and a wider
   crop palette with subtler relationships. Early plots use only friendly/neutral
   crops (pure positive feedback); foes (tomato/corn, potato, onion, then fennel)
   are introduced as the climb continues.

---

## Controls

Drag a tile from the tray to an empty cell. While dragging, the target cell tints
**green** (the move makes net friends), **red** (net foes), or white (neutral), and a
preview reads off the relationship before you commit. Release to plant; release off
the grid to snap the tile home.

All drawn with `CustomPainter` on one `Ticker` — no raster assets.

Visual language:
- **Plants** — shaded orbs in crop colour with a 2-letter badge (Co/Be/Sq/To…).
- **Relationship links** — a green or red beam flashes between newly-adjacent plants.
- **Soil cells** — rounded dark beds; occupied beds darken.
- **Growth** — thriving plants swell and glow green; wilting plants shrink and brown.

---

## Scoring

| Event | Score |
|---|---|
| Friendly neighbour on placement | +12 each |
| Clean placement combo (n ≥ 2) | +n × 4 |
| Plant thrives in growth (net > 0) | +8 × net |
| Flawless plot (no foe adjacency) | +25 + level × 10 |
| Foe neighbour | 0 pts; breaks combo; risks a wilt |

Score is a proxy for spatial planning skill: reading the hand and arranging it so
allies touch and antagonists never do.

---

## Win / end condition

Score attack. The HOST owns the 60-second clock, the 3·2·1 countdown, the live score
HUD and the results screen. This widget renders only the play area and gates all
progress on `session.isRunning`. Highest score when the clock runs out wins.

---

## Difficulty curve

| Level (= plots harvested) | Plot | Palette added |
|---|---|---|
| 0 | 3×3 | corn, beans, squash, marigold (all friend/neutral) |
| 1 | 4×3 | + tomato, basil |
| 2 | 4×4 | + potato, onion (first foes appear) |
| 3 | 4×4 | + fennel (the saboteur) |
| 4 | 5×4 | + carrot, cabbage |
| 5+ | 5×5 | + lettuce |

The ramp comes from two knobs at once: a larger bed (more adjacencies to manage) and
a denser web of relationships (more ways to help and to hurt).

---

## Educational blocks engaged

See `EDUCATION.md` for the full write-up. In brief, the game teaches the four real
mechanisms of companion planting — **nitrogen fixing** (beans→corn/cabbage), **pest
repulsion** (marigold/basil→tomato), **structural support / shade** (Three Sisters),
and **competition / allelopathy** (fennel, nightshade clustering, allium×legume).
Every placement is a labelled "+helps/−hurts" micro-lesson.

---

## Potato angle

Potato is a first-class crop tile with its real companion profile: it **likes** beans
(beans deter the Colorado potato beetle), corn and cabbage and marigold, and it
**hates** tomato (shared nightshade blight) and squash (both heavy feeders). Planting
a healthy potato bed in-game mirrors how you'd actually lay out a potato patch.

---

## Session / resume

The host drives the run lifecycle. Key state to persist for drop-and-resume:

- `_plotsCompleted`, `_level`, `_combo`, `_flawlessStreak`
- `_cols`, `_rows`, `_grid` (placed crops), `_palette`
- `_hand` (current tray tiles), `_phase`, `_growthAge`

Transient (`_links`, `_pops`, `_fx`, drag state) is ephemeral and rebuilds on resume.
