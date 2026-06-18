# GAME.md — Scale the System (reworked from "Orbital Mechanic" spiral game)

> Canonical spec for the Solar-Systems-scale game. Replaces the freehand-spiral game with a
> relative-size drawing challenge; the spiral mechanic returns as the finale.

- **Scale (cell):** solarSystems
- **Game id:** scale_the_system (widget `SolarSortGame` in `mini_games_batch3.dart`)
- **One-line concept:** Draw two circles at the right **relative size** to compare neighbors —
  Sun vs Mercury, Mercury vs Venus, Venus vs Earth, Earth vs Mars … the closer to true scale, the
  more points. Finish with a spiral-spam finale.
- **Role:** solo high-score

## Why this is great
The relative sizes of the solar system are deeply counterintuitive — the Sun dwarfs everything, Venus
≈ Earth, Mars is half of Earth, Jupiter is gigantic. Making the player *draw* the ratio (and seeing how
wrong their intuition is) is the lesson.

## Rounds — relative-size pairs (in order)
Each round names **two bodies**; the player **draws two circles** (freehand circle gesture → fit a
radius to each path). Score by how close the **drawn radius ratio** matches the **true ratio**. After
each, reveal the real ratio + a fact (our fact-flare).

Sequence (adjacent neighbors): **Sun→Mercury, Mercury→Venus, Venus→Earth, Earth→Mars, Mars→Jupiter,
Jupiter→Saturn, Saturn→Uranus, Uranus→Neptune.**

True mean radii (km) to bake in:
Sun 696,340 · Mercury 2,440 · Venus 6,052 · Earth 6,371 · Mars 3,390 · Jupiter 69,911 ·
Saturn 58,232 · Uranus 25,362 · Neptune 24,622.

Notable ratios / facts to surface on reveal:
- **Sun : Mercury ≈ 285 : 1** — "~285 Mercurys would span the Sun." (You literally can't draw Mercury
  to scale next to the Sun — that's the point.)
- **Venus : Earth ≈ 1 : 1.05** — "Venus is Earth's near-twin in size."
- **Earth : Mars ≈ 1 : 0.53** — "Mars is about half Earth's width."
- **Mars : Jupiter ≈ 1 : 20.6** — "Jupiter is over 11 Earths wide."
- (Generate the rest from the radii.)

## Scoring
- Per round: points scale with **ratio accuracy** — `score = base × accuracy`, where accuracy falls off
  as the drawn ratio diverges from the true ratio (log-scale tolerance, since ratios span huge ranges).
  A near-perfect ratio = full points + a "PERFECT SCALE" flourish.
- Reveal the true ratio after each attempt (educational beat + the fact).

## Drawing mechanic
- Player draws a roughly circular gesture; fit a circle (centroid + mean radius) to the path. Two draws
  per round (body A, then body B). Forgiving — it's the *ratio* that's scored, not circle perfection.
- Clear prompt of which body to draw now; show the first circle while drawing the second so the player
  can judge relative size.

## Finale — spiral spam (keep the old mechanic)
After the size rounds, a **bonus finale**: spam spirals as fast as you can (the original spiral-drawing
mechanic) — framed as the spinning protoplanetary disk / galaxy. Pure points dump, satisfying ending.

## Educational blocks engaged
solarSystems blocks (Our Sun, Planetary Formation, Habitable Zones, System Architecture) — the size
comparisons + reveals teach real scale; the spiral finale nods to disk formation. Much stronger tie than
the old pure-spiral game (which taught nothing).

## Potato angle
Light — optional gag: a "potato to Sun" bonus reveal at the very end (how absurdly tiny). Don't force it.

## Implementation
- Rework `SolarSortGame` in `mini_games_batch3.dart` (edit ONLY that class — megafile). Keep it
  self-contained (internal timer/results/restart, like now). Reuse the existing spiral-draw code for the
  finale. Bake in the radii + facts. Canvas-only.
