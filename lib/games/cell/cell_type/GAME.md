# GAME.md — Cell Type

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** cell — `BioScale.cell`
- **Game id:** cell_type
- **One-line concept:** A cell is drawn live from its structural tells; classify it as
  **PLANT / ANIMAL / BACTERIAL / FUNGAL** before the next one loads. Fast, streak-multiplied,
  with a fact card after every answer.
- **Role:** solo / party score attack
- **Six-in-one?** no

---

## Lore

You're at the microscope. Each specimen is a single cell, rendered from its real structures —
a rigid wall, green chloroplasts, a giant central vacuole, a nucleus (or none at all), a swimming
flagellum, relative size. Name the kingdom. The clearer the slide, the easier the call; as the
round runs, the tells thin out and the specimens come faster.

---

## Rules (canonical)

1. **One cell on the stage at a time.** It is procedurally drawn (all `CustomPainter`, no raster
   assets) from a feature set that uniquely implies its type.
2. **Tap one of four classifications:** PLANT, ANIMAL, BACTERIAL, FUNGAL.
3. **Scoring is speed-based.** An instant correct answer is worth `_kMaxPoints` (110); the value
   decays linearly to `_kFloorPoints` (15) over the current decay window. Wrong answers score 0
   (no penalty — keep it fast and fun).
4. **Streak multiplier.** Every `_kStreakStep` (3) consecutive correct answers adds +1x. The
   multiplier scales the speed bonus. A wrong answer resets the streak to x1. The session keeps
   the high-water streak via `noteStreak`.
5. **Fact card after every answer.** Shows the true type + a structural fact for `_kFlareDuration`
   (1.9 s), then the next cell loads. Tap the card to skip ahead.
6. **Difficulty ramps with elapsed time** (`_progress`, derived from `session.remaining`):
   - **Subtler tells:** plant cells shed chloroplasts; bacteria shift from rods to cocci; fungal
     and plant cells blur (both walled).
   - **Faster scoring window:** the decay window shrinks from `_kDecayFast` (3.4 s) to
     `_kDecaySlow` (1.7 s), so the speed bonus drops off quicker late in the round.
7. **Session length: 60 s** (`MiniGameSpec.durationSeconds`). The host owns the clock, countdown,
   score readout and results. The game never calls `endEarly`.

---

## The tells (what the player learns to read)

| Type | Wall | Chloroplasts | Big central vacuole | Nucleus | Size | Extra |
|---|---|---|---|---|---|---|
| **PLANT** | yes (rigid box) | yes (green grana) | yes | yes (pushed to edge) | large | boxy outline |
| **ANIMAL** | no (thin membrane) | no | no | yes (central) | large | mitochondria, round blob |
| **BACTERIAL** | yes (+capsule) | no | no | **no** (nucleoid) | **tiny** | ribosome dots, flagellum |
| **FUNGAL** | yes (round, chitin) | no | no | yes | medium | granules, plant look-alike minus chloroplasts |

Reading order that resolves any cell: **nucleus present? → wall present? → chloroplasts present?**
- No nucleus + tiny → BACTERIAL.
- Nucleus + no wall → ANIMAL.
- Nucleus + wall + chloroplasts + big vacuole → PLANT.
- Nucleus + wall + no chloroplasts → FUNGAL.

---

## Scoring

| Event | Score |
|---|---|
| Correct (instant) | up to 110 x streak multiplier |
| Correct (slow, end of decay window) | 15 x streak multiplier |
| Wrong | 0 (streak resets) |

`humanMax` 2000 · `starThresholds` [600, 1300, 2000].

---

## Win / end condition

60 s timed score attack. Highest score when time runs out wins. Fully host-driven results.

---

## Session / resume

`CellTypeGame` uses `MiniGameSession`. It auto-starts on `session.isRunning` (a calm,
breathing cell shows in the ready state, input gated off). When the host ends the run, the
final score stands; a fresh session re-generates from cell #1. No internal timer or results
screen — the S in GAMES is satisfied by the host's close/re-enter cycle.
