# GAME.md — Starch Factory

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** atoms
- **Game id:** starch_factory
- **One-line concept:** A conveyor-belt inside the amyloplast — route coloured
  glucose/carbon molecules to the right lane endpoints before starch reserves run dry.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

Inside the potato's amyloplast (the starch-making organelle), glucose molecules tumble in on a
conveyor. Each glucose is a chain of carbon atoms; routing it to the right chain-building funnel
extends the starch polymer. Route wrong and the chain breaks — starch reserve drops. The conveyor
never stops. Carbon chemistry really does work by sorting and linking; the game makes that
visceral.

> **Edu-tie note:** The sorting mechanic is thematic, not structural. It does not teach atomic
> number, electron shells, or the triple-alpha process. It reinforces Carbon as the backbone of
> starch and introduces the amyloplast as a real organelle. Framed as a *variety* game-2 on the
> Atoms scale — fun and potato-flavoured, not a second lesson in atomic structure.

---

## Rules (canonical)

1. **Three (later up to five) colour-coded molecule types scroll right along parallel conveyor
   lanes.** Each colour represents a glucose/carbon fragment: Amber (G), Cyan (A), Green (B),
   Purple (P), Pink (D).

2. **Each lane has an endpoint (hexagonal funnel) that accepts one specific colour.** When the
   lead molecule reaches the endpoint, it resolves: correct colour scores points and replenishes
   starch; wrong colour loses starch and breaks the chain.

3. **Tap to select a lane; tap a different lane to swap all molecules between the two.** Molecules
   slide smoothly to their new lane; the leader will still reach the endpoint first.

4. **Lane endpoints swap positions on a countdown timer** (starts at 10 s, shrinks toward 4.5 s at
   high score). A warning pulse flashes 1.5 s before the swap. The player must re-route molecules
   mid-flight after each swap.

5. **The starch bar (health) depletes at a steady rate and drops further on each wrong routing.**
   It replenishes slightly on each correct routing. Starch at 0 = game over.

6. **Difficulty ramps with elapsed time:** scroll speed increases, drain rate increases, swap
   cooldown shrinks. At score ≥ 1000 a fourth lane (purple) unlocks; at score ≥ 10000 a fifth
   (pink) unlocks.

7. **Combo multiplier.** Consecutive correct routings build a combo counter (shown from 3×
   onward). Points per correct routing = `10 × (1 + combo × 0.15)`, rounded. Bonus +10 when
   starch is critically low (< 20 %).

---

## Controls

Tap anywhere near a lane to **select** it (border highlights). Tap a different lane to **swap**
all in-flight molecules between the two lanes. Tap the selected lane again to deselect.

All drawn with `CustomPainter` — no raster assets.

Visual language:
- **Molecules** — hexagons in lane colour, letter label (G / A / B / P / D)
- **Endpoints** — larger hexagons; glow + chain of smaller hexagons trailing right
- **Starch bar** — top of screen; green → yellow → red as it depletes
- **Swap countdown** — narrow bar at the top-centre; pulses red in last 25 %
- **Selected lane** — translucent border strip around the lane row

---

## Scoring

| Event | Score |
|---|---|
| Correct routing | +10 (base), multiplied by combo |
| Correct routing while starch < 20 % | +10 bonus on top |
| Wrong routing | 0 pts; starch −7 % |
| Combo of 3+ consecutive correct | points scale: `10 × (1 + n × 0.15)` |

There is no explicit time bonus. Score is a proxy for sustained accuracy under increasing pressure.

---

## Win / end condition

Endless survival. The game ends when starch reaches 0 (`_starch ≤ 0`). Score at that moment is
the final score. Tap to restart immediately (the game owns its own restart — not host-driven).

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Scroll speed | Starts at 0.14 norm/s; grows linearly to 0.14 + 0.18 × (elapsed/90) |
| Drain rate | Starts at 0.018/s; grows to 0.018 + 0.012 × (elapsed/90) |
| Swap cooldown | Starts at 10 s; shrinks to 4.5 s floor at 90 s of play |
| Lane count | 3 → 4 at score 1000 → 5 at score 10000 |

The conveyor speed and swap frequency together form the primary pressure. Late game: five lanes
swapping every 4.5 s with a fast belt is intense. Early game is accessible (3 lanes, slow scroll).

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Carbon | Thematic: molecules are labelled glucose/carbon fragments; the amyloplast is named; the chain-building metaphor echoes polymer assembly | ⚠️ thematic, not structural |
| Hydrogen | Not engaged | ✗ |
| Nitrogen | Not engaged | ✗ |
| Oxygen | Not engaged | ✗ |
| Phosphorus | Not engaged | ✗ |

**Edu verdict:** ⚠️ variety slot. Strong on potato flavour (amyloplast, glucose, starch); weak on
atomic structure. The atomic-structure teaching is owned by `atom_builder`. This game provides
reflexive variety and reinforces the starch-is-carbon-chains idea.

**Upgrade path (optional):** The molecule label system could be extended so each colour is renamed
to `C₆H₁₂O₆` (glucose) with a small C-6 count badge, making the "carbon chains" metaphor more
explicit. Not required for the variety-game slot.

---

## Potato angle

The game lives inside the amyloplast — the organelle that assembles glucose into starch. Starch is
literally the thing that makes a potato a potato. Routing glucose to the right funnel = extending
the starch polymer. The game's health bar is literally called "STARCH." Every correct route grows
the potato; every wrong route degrades it. The potato connection is immediate, visceral, and
accurate — the amyloplast does exactly this in biology.

---

## Session / resume

This game runs its own game-over / restart loop and does not defer to a session host for restart
(unlike `atom_builder`). Key state to persist for drop-and-resume:

- `_elapsed`, `_score`, `_starch`, `_drainRate`, `_scrollSpeed`
- `_laneColors` (current assignment, post-swap)
- `_swapTimer`, `_swapCooldown`
- `_combo`, `_totalRouted`, `_correctRoutes`

The in-flight molecule list (`_mols`) is ephemeral — on resume, repopulate from spawn logic.
