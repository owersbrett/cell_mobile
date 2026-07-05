# GAME.md — Ricochet

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** planets
- **Game id:** orbit_ricochet
- **One-line concept:** Cosmic billiards — drag toward your target to launch a planetlet that flies
  DEAD STRAIGHT and ricochets off planet surfaces, asteroids, and the four arena walls. Bodies PAY
  (+30 per carom, and each body carom banks +55 more at the catch); walls COST (−15 per carom).
  Reach catchers tucked behind obstacles with deliberate body-bank shots.
- **Role:** solo high-score (also party-mode round)
- **Six-in-one?** no
- **Variant of:** `planets/orbit_catch` (`PlanetCatchGame`). Self-contained — it does NOT import the
  base game. **Deliberate differentiation:** Orbit Catch is the GRAVITY game (curved flight);
  Ricochet is the REFLECTION game (pure billiards, straight flight). The gravity-well ring visuals
  remain here as ambient dressing only — they never pull the shot.

---

## Lore

Orbit Catch taught you to read a curve. Ricochet strips gravity out and hands you the other half of
every trajectory problem: collisions. A shot carries momentum into a surface and comes back out —
angle of incidence equals angle of reflection — in a dead-straight line. A skilled shot is a **body
bank**: clip the edge of a planet or asteroid so the carom drops the planetlet into a catcher you
could never hit on a direct line. The walls will bounce you too, but the house charges for it.

---

## Rules (canonical)

1. **Direct-aim launch.** Drag TOWARD where you want the shot to go — the drag vector IS the launch
   direction; drag length sets power (`240–720 px/s`). Identical control to Orbit Catch.

2. **Pure billiards flight (the physics contract).** The planetlet travels in a STRAIGHT LINE
   between bounces. There is NO mid-flight gravity — the wells' influence rings are visual dressing.
   This guarantee is load-bearing: it is what makes the cue-style aim preview exactly truthful.

3. **Everything reflects.** The planetlet bounces off:
   - **Planet/well surfaces** — restitution `0.90`.
   - **Asteroids** — small pure reflectors, restitution `0.90`.
   - **The four arena walls** — restitution `0.94`.
   Reflection is true mirror reflection about the surface normal (`v' = v − 2(v·n)n`), then energy is
   bled by the restitution factor.

4. **Bodies pay, walls cost (the scoring contract).**
   - Each carom off a **planet or asteroid** scores **+30 live** (a "+30" pop at the contact point)
     and counts toward the bank bonus.
   - Each carom off a **wall** deducts **−15 live** (a "−15" pop in the warning tone). Walls remain
     fully reflective — a wall route always physically works; it just bleeds points.
   - A corner hit (both wall axes in one contact) registers as ONE wall carom, one deduction.
   - **The score never goes below 0** — deductions are clamped against the session's current score.

5. **Catchers hide behind obstacles.** Targets are placed so the intended path is a **body bank**:
   a blocker body sits on (or near) the straight cannon→catcher line, and clipping its edge is the
   natural, paying solve. Some catchers drift laterally (lead them, then bank).

6. **Banks pay at the catch.** A catch scores `100` base. Each **body** carom on the catching shot
   adds `+55` (a "1-BANK", "2-BANK", "3-BANK"… combo). **Wall caroms never credit a bank.** Spare
   shots left on the level add `+25` each; level/loop add a small step bonus.

7. **Shots fizzle.** A shot dies when it (a) exceeds its flight-time budget, (b) exceeds `16`
   bounces, or (c) settles below `70 px/s` after `1.2 s`. The flight-time budget SHRINKS as
   difficulty climbs (`7.2 s → 3.6 s`). A fizzle costs one of your 4 shots on the level.

8. **The level ladder.** One 60s round walks a 10-level, data-driven ladder. Each level procedurally
   generates one of many seeded variations. Difficulty ramps (more obstacles, tighter/moving
   catchers, faster decay). Clearing level 10 loops back with bigger/denser bodies (`+16%/loop`
   heft) and a shrinking catcher (`−10%/loop`) so completion never dead-ends.

---

## Controls

Drag anywhere to aim+launch. Released drag fires one planetlet. You can't aim while a shot is live.

Visual language (all `CustomPainter`, no raster assets):
- **Gravity wells** — shaded orbs with pulsing influence rings and a bright reflective rim. The
  rings are AMBIENT DRESSING (planetary gravitas); only the solid surface matters to the shot.
- **Asteroids** — rocky orbs with a hard bright rim + facet ticks; small precision reflectors.
- **Arena walls** — a glowing inset frame; bankable but costly.
- **Catcher** — gold orb with intake rings + crosshair; a drift arrow if it moves.
- **Cue-style aim preview** — while aiming: a STRAIGHT line from the cannon to the first surface
  the aim ray hits, a pulsing ring at the impact point, and a SHORT STUB showing the reflected
  (next-ricochet) direction with a small arrowhead. Color tells the score story: **gold** when the
  ray pots the catcher clean or lands on a paying body, **warning orange** when it lands on a wall.
  Because flight is straight, the preview is EXACT up to that first contact — it never lies.
- **Live shot** — glowing planetlet with a comet trail and a per-BODY-bank halo ring (wall caroms
  don't earn a ring, since they don't credit a bank).

---

## Scoring

| Event | Score |
|---|---|
| Carom off a planet/asteroid (live) | +30 each |
| Carom off a wall (live) | −15 each (clamped — total never drops below 0) |
| Catch (base) | +100 |
| Per BODY carom on the catching shot (bank bonus) | +55 each |
| Spare shot left when the level clears | +25 each |
| Level step bonus | +12 × level index |
| Loop bonus | +60 × loop |

A clean 1-body-bank catch with two spare shots on a mid-ladder level:
`30 (live) + 100 + 55 + 2×25 + …` ≈ `250+`. Body banks are the multiplier — a straight pot is fine;
body-bank catches are how you climb; wall routes are the lazy tax.

- **humanMax:** `2900` (a skilled player body-banks frequently and clears the ladder once or twice).
- **starThresholds:** `[1000, 1900, 2900]`.

---

## Win / end condition

Timed score attack. Duration is host-owned (`session.spec.durationSeconds`, 60s). The planetlet
keeps going through the whole ladder for the entire session. Highest score when time expires wins.
No restart button inside the session (host owns exit/replay).

---

## Difficulty curve

Three levers in concert:
1. **Ladder ramp** — bigger/more bodies, more asteroids, tighter and moving catchers across Lv 1→10.
2. **Faster decay** — flight-time budget shrinks `7.2 s → 3.6 s` as difficulty rises, so multi-bank
   plans must land sooner.
3. **Loop escalation** — past Lv 10, body heft climbs `+16%/loop` (bigger surfaces, less open space)
   and the catcher shrinks `−10%/loop`.

### The ladder (intended solutions route off BODIES)

| Lv | Name | Intent |
|---|---|---|
| 1 | First Contact | A roomy giant squats on the direct line; clip its edge (+30) into the corner pocket. |
| 2 | Off the Giant | A mid blocks the left lane; carom off the central giant's flank to the top-left pocket. |
| 3 | Asteroid Carom | Kiss a small rock to swing the angle — the precision body bank. |
| 4 | Moving Pocket | Lead a drifting catcher off the mid parked in its lane. |
| 5 | Double Kiss | Chain two body caroms in one shot down into the bottom-right pocket. |
| 6 | Corridor | Two giants form a lane; graze a flank to thread the carom out the top. |
| 7 | Pinball | Rock bumpers + a big giant; multi-body caroms stack +30s into a moving pocket. |
| 8 | Gauntlet | Dense field, narrow body banks, small catcher — walls tempt and bleed everywhere. |
| 9 | Double Drift | Moving catcher + heavy field of paying banks. |
| 10 | Event Horizon | Max field, tiny moving catcher. The wall. |

Walls remain fully reflective on every level — the wall route is always physically available, just
costed.

---

## Educational blocks engaged

See `EDUCATION.md` for the full write-up. Core idea: **angle of incidence = angle of reflection**
(specular reflection about a surface normal) on flat vs convex surfaces — real cue-sports bank-shot
geometry, plus restitution as an energy budget. (Gravitational path bending is deliberately NOT this
game's lesson — that's Orbit Catch.)

---

## Potato angle

Racking up spuds on a billiards table: the Hot Potato gets passed around the system off every
surface in the room. A potato is never handed over in a straight line politely — it's banked off the
nearest planet, and the house always takes its cut when you play the rails.

---

## Session / resume

Persist: `score`, `elapsed`, `_level`, `_loop`, `_attempt` (variation seed), `_shotsLeft`, `_streak`.
The live projectile and FX are ephemeral — on resume, regenerate the layout from `(_level, _attempt,
_loop)` (deterministic seed) and let the player re-aim. Session re-entry (the S in GAMES): the host
closes the run and starts a fresh one cleanly; this widget holds no global state.

---

## Implementation notes

**File:** `lib/games/planets/orbit_ricochet/orbit_ricochet_game.dart` — class `OrbitRicochetGame`.

**Tunable constants** (all top-of-file, first-pass values):

| Constant | Value | Effect |
|---|---|---|
| `_kBodyRestitution` | 0.90 | Energy kept on a planet/asteroid bounce |
| `_kWallRestitution` | 0.94 | Energy kept on a wall bounce |
| `_kMaxBounces` | 16 | Hard cap; a shot can't pinball forever |
| `_kBaseFlightTime` | 7.2 | Seconds a shot lives at easy difficulty (shrinks with diff) |
| `_kMinFlightSpeed` | 70 | Settle speed below which a shot fizzles |
| `_kBodyBounceScore` | 30 | Live points per body carom |
| `_kWallPenalty` | 15 | Live deduction per wall carom (floors at 0) |
| `_kBankBonus` | 55 | Bank bonus per BODY carom on the catching shot |
| `_kPointsPerHit` | 100 | Base catch score |
| `_kShotsPerLevel` | 4 | Shots before a level rerolls |
| `_kCueStubLen` | 64 | px length of the reflected-direction preview stub |
| `_kLoopMassGain` | 0.16 | +body heft (size/clutter) per completed ladder loop |
| `_kLoopShrink` | 0.10 | Catcher shrink per loop |

**ATTRACT autopilot:** because flight is straight, the bot plans exactly — direct pot if the line is
clear, else a swept search for a one-carom BODY-bank route (same ray-cast as the aim preview), else
fire at the blocker (which at least pays +30).

**Known bugs / TODOs:**
1. **No restart within session** — host owns replay; intentional.
2. **A shot that misses everything bleeds** — it caroms walls until its flight time expires,
   −15 per wall. Intentional risk (walls cost), but the per-shot worst case is worth a playtest;
   tune `_kWallPenalty` / `_kBaseFlightTime` if misses feel too punishing.
3. **No audio** — all feedback is visual + FX. SFX on bounce/catch is a future polish item.
