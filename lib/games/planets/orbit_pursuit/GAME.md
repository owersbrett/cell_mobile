# GAME.md — Pursuit

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (planets):** planets
- **Game id:** orbit_pursuit
- **One-line concept:** A moving-target variant of Orbit Catch — drag to launch a planetlet that
  curves through gravity wells, but the catcher is a MOON or COMET on the move, so you must aim
  where it will be, not where it is.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

Orbit Catch taught you to read gravity: drag toward a target and the planetlet bends through deep
wells onto a parked catcher. **Pursuit** removes the "parked." Every catcher now ORBITS a body or
rides an eccentric COMET arc. Your shot still takes real time to travel and still bends on the way —
so by the time it arrives, the target has moved. You have to LEAD: aim at the spot the target will
occupy when the planetlet gets there. The orbit path and a row of "future ghost" markers make the
lead visible and learnable. This is the same problem a real spacecraft solves to rendezvous: you do
not burn toward where the station is, you burn toward where it will be.

---

## Rules (canonical)

1. **Drag TOWARD where you want the shot to go.** Direct aim: the drag vector (start → finger) is the
   launch direction; drag length sets power (`_kMinLaunchSpeed`..`_kMaxLaunchSpeed`). A live
   trajectory preview shows the real curved path through the wells.

2. **Gravity bends every shot.** Wells pull with `a = G·mass / r²` (strong — `_kGravityConstant =
   240000`). Bigger/heavier bodies are drawn bigger so you can *read* pull from size. Crashing the
   planetlet into a well is a miss.

3. **The target moves.** Each catcher traces a closed elliptical orbit: circular (a moon) or
   eccentric (a comet arc), pro- or retrograde. Catch it by intercepting it mid-flight — the
   intercept test runs against the target's LIVE position, so the lead is entirely on you.

4. **Lead with the ghosts.** Each target shows: the full orbit path (faint), a fading trail behind
   it, a direction arrow, and **future ghost dots** at fixed time steps ahead (`_kGhostStep` apart).
   Aim your shot's end point at a ghost, not the target. Higher levels show fewer ghosts.

5. **Catch all targets to clear the level.** Single-moon levels clear on one catch; multi-moon levels
   need every moon. Clearing advances up the 10-level ladder.

6. **Shots.** You get `_kShotsBase (4)` shots per level, `+2` per extra moon. A miss (crash or
   off-screen) costs one shot and breaks your streak. Run out → the SAME level rerolls a fresh
   variation with shots refilled (no demotion; the round keeps flowing).

7. **Scoring.** Each intercept: `100` base `+ leadBonus` (up to `60`, scaled by how fast the target
   was sweeping — a fast lead is worth more) `+ levelBonus` (`level×12 + loop×60`). Clearing a level
   with shots to spare banks `+30` per spare shot. Consecutive intercepts build a streak (reported to
   the host as the streak award).

8. **It escalates.** Across the ladder: targets speed up, orbits get more eccentric, retrograde and
   multi-moon levels appear, the catcher shrinks, and the ghost-dot count drops. Clearing all 10
   loops back with heavier wells and a smaller catcher so completion never dead-ends.

---

## Controls

Drag anywhere to aim+power; release to launch. One planetlet in flight at a time; you cannot start a
new drag until the current shot resolves. All drawn with `CustomPainter` — no raster assets.

Visual language:
- **Cannon** — bottom-left orb with a barrel that points along the launch/shot direction.
- **Gravity wells** — shaded orbs with pulsing influence rings + `GIANT/MID/SMALL` labels; giants
  carry a slow tilted ring.
- **Moving target** — gold orb with intake rings + crosshair; gold orbit path; gold ghost dots
  ahead; gold direction arrow.
- **Planetlet** — glaucous orb with a white-cored trail.
- **Preview** — cool→warm dots along the predicted curved path (cool at the cannon, warm at the end).

---

## Scoring

| Event | Score |
|---|---|
| Intercept a target | +100 base |
| Lead bonus (per intercept) | up to +60, scaled by target tangential speed |
| Level step bonus | +`level×12 + loop×60` per intercept |
| Spare-shot bonus (on level clear) | +30 × shots left |
| Miss (crash / off-screen) | 0 (breaks streak, costs a shot) |

---

## Win / end condition

Timed score attack — duration is the host's `session.spec.durationSeconds` (60s). No built-in cap;
the ladder loops with escalating difficulty for the whole session. Highest score when time expires
wins. The host owns the timer, results, and exit.

---

## Difficulty curve

`difficulty = level/9 + loop·0.6`. Levers, all flowing from the level index + loop:

1. **Target speed** — `angSpeed = (baseSpeed + diff·0.16)·jitter`; later blueprints raise `baseSpeed`
   (0.5 → 1.1 rad/s) and add retrograde motion.
2. **Eccentricity** — early orbits are near-circular; comet levels squash the minor axis (`ecc` down
   to ~0.42), so the target races at the turns.
3. **Target count** — 1 moon early; 2–3 moons on `Two Moons`, `Eccentric Pair`, `Triple Drift`,
   `Event Orbit`.
4. **Catcher radius** — `lerp(24 → 12)` across the ladder, then `×0.9` per loop.
5. **Ghost dots** — `(5 − level·0.45 − loop)` clamped to `[1,5]`: generous early, near-blind late.
6. **Well mass** — `+18%` body mass and `−10%` catcher per completed loop.

---

## The ladder (10 blueprints)

1. **First Orbit** — one slow wide moon, a small well to nudge the arc.
2. **Wide Drift** — a flattened comet-ish arc past one mid well.
3. **Moon of the Giant** — the moon circles the very well you must dodge.
4. **Comet** — fast eccentric arc; a giant bends the approach.
5. **Twin Wells** — a moon orbits the gap between a giant and a mid.
6. **Two Moons** — twin catchers, same orbit, opposite phase.
7. **Eccentric Pair** — two comets on different arcs + a deflector.
8. **Retrograde Run** — one fast backward moon, dense heavy field.
9. **Triple Drift** — three catchers across a crowded field.
10. **Event Orbit** — two fast eccentric moons, max field, tiny catcher.

---

## Session / resume

Persist: `score`, `elapsed`, `_level`, `_loop`, `_attempt`, `_shotsLeft`, `_streak`. The live
projectile and per-target `caught` flags are ephemeral — on resume, regenerate the layout from
`(_level, _attempt, _loop)` (deterministic seed) and refill shots. The orbit positions are pure
functions of the clock, so nothing else needs storing.

---

## Implementation notes

**File:** `lib/games/planets/orbit_pursuit/orbit_pursuit_game.dart` — class `OrbitPursuitGame`.
Self-contained module (framework deps only: `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`).
Single `AnimationController` ticker → `setState` over a `CustomPaint`; all motion/FX in one
`_PursuitPainter`. Ticker disposed in `dispose()`.

**Tunable constants** (top of file): launch (`_kMaxLaunchSpeed`, `_kMinLaunchSpeed`,
`_kDragToSpeedScale`, `_kMaxDragPx`), gravity (`_kGravityConstant`, `_kMinGravDist`), preview
(`_kPreviewSteps`, `_kPreviewDt`), target (`_kTargetBaseRadius`, `_kTargetMinRadius`, `_kGhostStep`),
scoring (`_kPointsPerHit`, `_kBonusPerExtraShot`, `_kLevelStepBonus`, `_kLeadBonusMax`, `_kShotsBase`),
loop escalation (`_kLoopMassGain`, `_kLoopShrink`).
