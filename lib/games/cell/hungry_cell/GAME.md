# GAME.md — Hungry Cell

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** cell *(see registry note below)*
- **Game id:** hungry_cell
- **One-line concept:** Steer your cell across a 2400 × 2400 world, eating nutrients and organelle
  pickups to grow, while dodging or devouring predator cells that share your world.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

A single cell drifts in a nutrient-rich environment. To survive — and to win — it must eat
everything smaller than itself, accumulate mass from organelle pickups, and avoid the
predators that will do the same to it if given the chance. This is agar.io logic: size is
power, and the environment only gets more crowded.

---

## Rules (canonical)

1. **The world is 2400 × 2400 px.** The camera follows the player cell, keeping it centered
   on screen. The visible area is a viewport into a much larger space — always be aware of
   what's off-screen.

2. **Drag anywhere to steer.** The cell glides smoothly toward the touch point (agar.io
   glide feel). Releasing the drag decelerates the cell. Larger cells move slightly slower
   (`_kPlayerSizePenalty = 0.28` at max size).

3. **Score = mass.** The session score tracks accumulated mass. Mass is gained by eating;
   mass is lost by being hit. Player cell radius grows with score:
   `radius = baseRadius (26) + (score × 0.22).clamp(0, 40)`.

4. **Food items:**
   - **Green nutrient pellets** (90 scattered across the world): +2 mass on contact.
     Pellets respawn at a new random location after being eaten.
   - **Glowing organelle pickups** (up to 4 simultaneously): +20 mass on contact.
     Three kinds: Mitochondria (orange), Golgi (purple), Ribosome (cyan). Each is procedurally
     drawn. Organelles become scarcer as difficulty rises (count scales from 4 down to ~1 at peak).
     After pickup, a new one respawns after 1.5–4.5 s.

5. **Predator cells** (2 at start, up to 9 at peak):
   - Predators have radii ranging from 16–36 px (player starts at 26 px).
   - **Player eats a predator** if `playerRadius > predator.radius × 1.05` and they touch: +30 mass,
     predator removed and replaced at a safe spawn point.
   - **Predator hits player** if `predator.radius > playerRadius × 0.95` and they touch:
     −25 mass, 1 s invulnerability window, knockback impulse.
   - Predators wander with noisy heading; after 45% of the session, they begin homing toward
     the player at increasing weight (up to 88% homing at session end).

6. **Difficulty ramp** (quadratic, `diff = progress²`):
   - Predator count: 2 → 9 (quadratic over session).
   - Predator speed: ×1 → ×2.6 multiplier over session.
   - Homing begins at 45% elapsed time.
   - Organelle count: 4 → ~1 (fewer pickups as pressure increases).

7. **Invulnerability:** After a hit, the player cell blinks for 1 s and cannot take another
   hit. Knockback applies immediately.

8. **Session length:** 45 s (set by `MiniGameSpec.durationSeconds`). Highest mass score wins.

---

## Controls

Drag (pan) anywhere on screen. No tap required. The cell's target is the touch point converted
from screen-space to world-space. A pulsing ring shows the current target. All rendering is
`CustomPainter`. No raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Eat a green nutrient pellet | +2 |
| Eat a glowing organelle pickup | +20 |
| Eat a smaller predator cell | +30 |
| Get hit by a larger predator | −25 |

Score can go negative (unlikely but possible if hit repeatedly without eating). The session
host prevents scores below 0 if `session.addScore(-25)` is guarded — check the host contract.

---

## Win / end condition

45 s timed score attack. The session host (`MiniGameHost`) owns the timer and results.
`HungryCellGame` fires events via `widget.session.addScore(n)` and reads
`widget.session.isRunning` to gate updates. The game does not implement its own results screen
or restart — these are fully delegated to the host.

---

## Difficulty curve

Three interlocking ramps:

1. **Predator count:** starts at 2 (manageable), reaches 9 at session end (overwhelming if the
   player is not significantly larger by then). Each new predator spawns far from the player.
2. **Predator speed:** base speed multiplied by up to ×2.6. At peak, predators move fast enough
   that the player cannot reliably outrun them — must be outmaneuvered.
3. **Predator homing:** from ~20 s onward, predators begin steering toward the player. At session
   end, 88% of their movement is direct pursuit. Combined with speed ramp, the final 15 s of a
   session is a survival challenge.

The difficulty ramp is deliberately steep (quadratic). A perfect run at max score is not intended
to be achievable — the game is a "how long can you keep the pace" challenge.

---

## Educational blocks engaged

Hungry Cell is on the Cell scale as a **survival / scale-intuition game**, not a structural-biology
game. Its educational association is light:

- **Cell relative size:** the core mechanic (eat smaller, flee larger) gives visceral intuition
  that cells in a real environment compete for resources by relative size.
- **Organelle names:** Mitochondria, Golgi, and Ribosome appear as pickup flavors. Their names
  are shown in popup text on collection. This is cosmetic association, not structural teaching.

For the Cell scale's declared blocks (plant cell types), this game has no association (see
`EDUCATION.md` for the scale-level mismatch discussion).

---

## Potato angle

Light. Cells compete for resources; this is true of any growing tissue including a potato tuber.
Keep the potato angle minimal here — the division games (Mitosis Rush, Meiosis) carry the
primary potato narrative for this scale.

---

## Session / resume

`HungryCellGame` uses `MiniGameSession` and is fully session-host-aware. No internal timer or
results screen. Drop-and-resume: the world state (player position, mass, predator positions)
would need to be persisted. Currently the game reinitializes the world on each mount — resume
would require serializing `_playerPos`, `_playerVel`, `_predators`, `_nutrients`, and `_score`
via the session host's persist mechanism (not yet implemented).
