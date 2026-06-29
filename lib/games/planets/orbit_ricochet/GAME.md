# GAME.md — Ricochet

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** planets
- **Game id:** orbit_ricochet
- **One-line concept:** A bank-shot variant of Orbit Catch — drag toward your target to launch a
  planetlet that BOTH curves through gravity wells AND ricochets off planet surfaces, asteroids,
  and the four arena walls. Reach catchers tucked behind obstacles with deliberate bank shots; the
  more bounces on the catching shot, the bigger the bonus.
- **Role:** solo high-score (also party-mode round)
- **Six-in-one?** no
- **Variant of:** `planets/orbit_catch` (`PlanetCatchGame`). Self-contained — it does NOT import the
  base game; the gravity-aim core is re-implemented here with reflection added.

---

## Lore

Orbit Catch taught you to read a curve. Ricochet adds the second half of every real trajectory
problem: collisions. A shot now carries momentum into walls and bodies and comes back out — angle of
incidence equals angle of reflection — while gravity keeps bending the path between bounces. A skilled
shot is a **bank shot**: aim at a wall or an asteroid so the carom, helped by a gravity assist, drops
the planetlet into a catcher you could never hit on a straight line.

---

## Rules (canonical)

1. **Direct-aim launch.** Drag TOWARD where you want the shot to go — the drag vector IS the launch
   direction; drag length sets power (`240–720 px/s`). Identical control to Orbit Catch.

2. **Gravity bends the path.** Every body pulls (`a = G·mass / r²`, `G = 205000`). Giants pull hard,
   mids less, asteroids almost not at all. Reading the curve before you launch is half the skill.

3. **Everything reflects (the variant).** The planetlet bounces off:
   - **Planet/well surfaces** — restitution `0.90`.
   - **Asteroids** — pure reflectors (negligible gravity), restitution `0.90`.
   - **The four arena walls** — restitution `0.94`.
   Reflection is true mirror reflection about the surface normal (`v' = v − 2(v·n)n`), then energy is
   bled by the restitution factor. This is the other half of the skill: **bank shots**.

4. **Catchers hide behind obstacles.** Targets are placed in corners or behind bodies so the path to
   them is a carom, not a straight curve. Some catchers drift laterally (lead them, then bank).

5. **Banks pay.** A catch scores `100` base. Each bounce on the catching shot adds `+55` (a "1-BANK",
   "2-BANK", "3-BANK"… combo). Spare shots left on the level add `+25` each; level/loop add a small
   step bonus.

6. **Shots fizzle.** A shot dies when it (a) exceeds its flight-time budget, (b) exceeds `16` bounces,
   or (c) settles below `70 px/s` after `1.2 s`. The flight-time budget SHRINKS as difficulty climbs
   (`7.2 s → 3.6 s`): the "faster decay" escalation. A fizzle costs one of your 4 shots on the level.

7. **The level ladder.** One 60s round walks a 10-level, data-driven ladder. Each level procedurally
   generates one of many seeded variations. Difficulty ramps (more obstacles, tighter/moving catchers,
   faster decay). Clearing level 10 loops back with escalated mass (`+16%/loop`) and a shrinking
   catcher (`−10%/loop`) so completion never dead-ends.

---

## Controls

Drag anywhere to aim+launch. Released drag fires one planetlet. You can't aim while a shot is live.

Visual language (all `CustomPainter`, no raster assets):
- **Gravity wells** — shaded orbs with pulsing influence rings (more rings = more mass) and a bright
  reflective rim (signals "bankable surface"). Giants carry a slow accretion ring.
- **Asteroids** — rocky orbs with a hard bright rim + facet ticks; pure reflectors.
- **Arena walls** — a glowing inset frame, so the boundary reads as a bankable surface.
- **Catcher** — gold orb with intake rings + crosshair; a drift arrow if it moves.
- **Aim feedback** — an arrow from the cannon, a power ring, and a faint trajectory preview. The
  preview is BRIGHT up to the first predicted carom and FAINT after it, with a pulsing ring marking
  the predicted first-bounce point.
- **Live shot** — glowing planetlet with a comet trail and a per-bounce halo ring (the bank count
  reads live).

---

## Scoring

| Event | Score |
|---|---|
| Catch (base) | +100 |
| Per bounce on the catching shot (bank bonus) | +55 each |
| Spare shot left when the level clears | +25 each |
| Level step bonus | +12 × level index |
| Loop bonus | +60 × loop |

A clean 3-bank catch with two spare shots on a mid-ladder level: `100 + 3×55 + 2×25 + …` ≈ `315+`.
Banks are the score multiplier — straight catches are fine; bank catches are how you climb.

- **humanMax:** `2900` (a skilled player banks frequently and clears the ladder once or twice).
- **starThresholds:** `[1000, 1900, 2900]`.

---

## Win / end condition

Timed score attack. Duration is host-owned (`session.spec.durationSeconds`, 60s). The atom… the
planetlet keeps going through the whole ladder for the entire session. Highest score when time
expires wins. No restart button inside the session (host owns exit/replay).

---

## Difficulty curve

Three levers in concert:
1. **Ladder ramp** — heavier/more bodies, more asteroids, tighter and moving catchers across Lv 1→10.
2. **Faster decay** — flight-time budget shrinks `7.2 s → 3.6 s` as difficulty rises, so multi-bank
   plans must land sooner.
3. **Loop escalation** — past Lv 10, body mass climbs `+16%/loop` and the catcher shrinks `−10%/loop`.

---

## Educational blocks engaged

See `EDUCATION.md` for the full write-up. Core ideas: **angle of incidence = angle of reflection**
(specular reflection about a surface normal), combined with **gravitational path bending** — i.e. real
bank shots and gravity assists, the same physics that lets spacecraft slingshot off planets.

---

## Potato angle

A potato in soil is a body other potatoes' roots curve around and bounce off. More to the point: the
gravity-assist maneuver that flings a spud-shaped probe across the solar system is exactly the
mechanic here — borrow a planet's motion, leave with more speed in a new direction. Bank shots are
how the Hot Potato gets passed across the system without burning fuel.

---

## Session / resume

Persist: `score`, `elapsed`, `_level`, `_loop`, `_attempt` (variation seed), `_shotsLeft`, `_streak`.
The live projectile and FX are ephemeral — on resume, regenerate the layout from `(_level, _attempt,
_loop)` (deterministic seed) and let the player re-aim. Session re-entry (the S in GAMES): the host
closes the run and starts a fresh one cleanly; this widget holds no global state.

---

## Implementation notes

**File:** `lib/games/planets/orbit_ricochet/orbit_ricochet_game.dart` — class `OrbitRicochetGame`.

**Tunable constants** (all top-of-file):

| Constant | Value | Effect |
|---|---|---|
| `_kGravityConstant` | 205000 | Pull strength; lower = straighter shots |
| `_kBodyRestitution` | 0.90 | Energy kept on a planet/asteroid bounce |
| `_kWallRestitution` | 0.94 | Energy kept on a wall bounce |
| `_kMaxBounces` | 16 | Hard cap; a shot can't pinball forever |
| `_kBaseFlightTime` | 7.2 | Seconds a shot lives at easy difficulty (shrinks with diff) |
| `_kMinFlightSpeed` | 70 | Settle speed below which a shot fizzles |
| `_kBankBonus` | 55 | Bonus points per bounce on the catching shot |
| `_kPointsPerHit` | 100 | Base catch score |
| `_kShotsPerLevel` | 4 | Shots before a level rerolls |
| `_kLoopMassGain` | 0.16 | +mass per completed ladder loop |
| `_kLoopShrink` | 0.10 | Catcher shrink per loop |

**Known bugs / TODOs:**
1. **No restart within session** — host owns replay; intentional.
2. **Preview can diverge from a long live shot** — the preview integrates with its own dt (like the
   base game); after several bounces small numeric drift accumulates. Acceptable: the FIRST bounce
   (the one we render bright + mark) is accurate, which is what the player aims with.
3. **No audio** — all feedback is visual + FX. SFX on bounce/catch is a future polish item.
