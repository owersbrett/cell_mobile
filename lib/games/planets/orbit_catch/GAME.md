# GAME.md — Orbit Catch

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** planets (`BioScale.planets`)
- **Game id:** planet_catch (registry) · folder `orbit_catch`
- **One-line concept:** A direct-aim gravity launcher — throw a potato through
  deep gravity wells and read the curve that brings it home to Earth.
- **Role:** solo high-score (also party-mode rotation)
- **Variants of it:** `planets/orbit_slingshot` (zoomed-out chain-assist
  variant) reimplements this core; neither imports the other.

---

## Fiction

**We are throwing a potato at Earth.** The launcher (bottom-left) holds a
visibly loaded, gently rocking spud. Every shot is that potato tumbling
end-over-end through a field of alien gravity wells, trailing a warm gold
wake, trying to land on the one blue-green world on the board. Earth is the
only Earth-looking body on screen and carries a converging gold destination
beacon — unmistakably the target at a glance, even at its 13px late-game size.

---

## Rules (canonical)

1. **Direct aim.** Drag anywhere; the drag vector points where the potato
   should go (direction = drag start→finger, speed = drag length through a
   power curve). Release to launch from the fixed launcher (bottom-left,
   ≈ 0.13, 0.84 of the canvas). One potato in flight at a time.

2. **Gravity curves every shot.** Each well pulls with a **softened
   `a = G·mass / r^1.5`** falloff (G = 100000, softening radius 22px). The
   r^1.5 law is deliberate: true 1/r² dies too fast at these pixel scales —
   this keeps close passes slingshot-strong AND reaches across the board, so
   wells dominate aiming and curves are dramatic even on level 1.

3. **Wells are legible.** Body size correlates with mass and each carries a
   GIANT / MID / SMALL label — you read pull at a glance.

4. **The preview never lies.** While aiming, a fading dotted curve runs the
   EXACT flight integrator (same constants, same falloff). Cool→warm color
   along the path encodes direction of travel.

5. **Land on Earth to score.** The potato's circular physics body
   (radius 7px) touching Earth's hit zone is a catch. Touching any well's
   surface destroys the potato (a miss, with an impact burst). Flying more
   than 120px off the field is a miss.

6. **Shots & flow.** **4 shots per level.** A catch advances the ladder.
   Running out of shots rerolls a fresh seeded variation of the SAME level
   (no demotion — the round keeps flowing) and refills shots. Streak =
   consecutive catches, reported to the host via `noteStreak`.

7. **The 10-level ladder.** One 60s round walks 10 data-driven blueprints,
   easiest → hardest; each generates one of ~6+ layout variations per attempt
   (seeded by `(level, attempt, loop)` so preview and live shot always agree):

   | Lv | Name | Puzzle |
   |---|---|---|
   | 1 | First Arc | one forgiving giant, big Earth |
   | 2 | Slingshot | whip around the giant, back to a near target |
   | 3 | Twin Pull | thread between two wells |
   | 4 | Lead the Drift | Earth drifts — lead it |
   | 5 | S-Curve | chain a double bend |
   | 6 | Corridor | two giants form a tight lane |
   | 7 | Pinball | moving Earth behind a heavy giant + deflectors |
   | 8 | Gauntlet | three wells, narrow path, small Earth |
   | 9 | Double Drift | moving Earth + dense heavy field |
   | 10 | Event Horizon | max field, tiny moving Earth — the wall |

8. **Loop escalation.** Clearing all 10 loops back to Lv 1 with **+18% body
   mass per loop** and **Earth shrinking 10% per loop** (difficulty term also
   climbs +0.6/loop), so a perfect run is eventually humanly impossible.

9. **Potato is visual only.** The tumbling PotatoArt spud, its spin, and its
   oblong silhouette NEVER change physics — every collision/catch test stays
   on the circular 7px body. This is a locked law.

---

## Controls

Drag to aim (direction + power), release to throw. While dragging: a gold aim
arrow from the launcher (length ∝ power), a power ring around the hub, and the
live trajectory preview. All rendering is `CustomPainter` — no raster assets.

Visual language:
- **Wells** — shared `PlanetArt` worlds (bands/craters/ice/rings) with pulsing
  influence rings ∝ mass and a size label.
- **Earth (target)** — locally drawn procedural Earth: blue ocean sphere lit
  top-left, fixed green/tan continents (same face every time), southern ice
  cap, drifting cloud wisps, terminator shading, sky-blue atmosphere rim.
  Beacon = a steady gold anchor ring + two gold rings converging inward out of
  phase ("come here"), never a crosshair. Drift arrow when it moves.
- **Launcher** — copper launch rail + ink hub, next potato loaded and rocking
  at the muzzle whenever nothing is in flight.
- **Potato** — canonical `PotatoArt` tuber tumbling at 5.2 rad/s, warm gold
  blurred wake with a pale core (warm = the potato's, cool blue = the wells').

---

## Scoring

| Event | Score |
|---|---|
| Catch (base) | +100 |
| Per spare shot left at the catch | +30 |
| Level bonus | +12 × level index |
| Loop bonus | +60 × loop |
| Miss (hit a well / fly out) | 0; consumes a shot |

Streak multiplier is host-side (`noteStreak`); a 2+ streak also pops an `Nx`
callout at the catch. `humanMax = 2600`; stars at 900 / 1700 / 2600
(registry: 60s, scoreUnit "hits").

---

## Win / end condition

Score attack. The host owns the 60s clock, countdown, score HUD and results.
Highest score when time runs out wins (party mode). No game-over inside the
widget; a miss only costs a shot and the level rerolls, so a fresh attempt
always re-enters cleanly (the GAMES "S").

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Earth radius | 26px (Lv1) → 13px (Lv10); ×0.9 per loop, floor 10px |
| Body mass | Blueprint bases 0.6–4.2, +0.9×difficulty for giants; +18%/loop |
| Field density | 2 bodies (Lv1) → 3 heavy bodies (Lv8–10) |
| Drift | Earth drifts at 58 px/s (±11% of width) on Lv 4, 7, 9, 10 |
| Difficulty term | `level/(count−1) + loop × 0.6` feeds every generator |

---

## Educational blocks engaged

Structural: gravity as a trajectory-bending force (mass and distance set the
pull), reading/predicting curved paths, slingshot flybys, why "aim straight at
it" fails in a gravity field. Full write-up in EDUCATION.md.

## Potato angle

The potato IS the projectile — Hot Potato Games' pass-it-on energy as
planetary mechanics: you don't carry the spud home, you throw it and let
gravity run the relay. The loaded, rocking muzzle potato keeps the fiction on
screen between shots.

## Session / resume

Host-driven session. State to persist for drop-and-resume: `_level`, `_loop`,
`_attempt`, `_shotsLeft`, `_streak`. The in-flight `_projectile`, fx and pops
are ephemeral; the layout regenerates deterministically from
`(_level, _attempt, _loop)`. ATTRACT autopilot (`_autoStep`) sweeps a
deterministic fan of aim angles × power levels through the game's own sim and
fires the closest-approach winner — competent, never perfect.
