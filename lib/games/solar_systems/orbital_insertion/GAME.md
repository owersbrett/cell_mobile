# GAME.md — Orbital Insertion

> Canonical spec (the **M** in GAMES) for the Solar-Systems-scale capture game. Rules live
> here — update this first, then the code.
>
> **v2 — CONSTELLATION rules (2026-07-12).** The v1 one-shot-at-a-time loop (launch → watch →
> wait → launch) is replaced by **continuous multi-moon orbiting**: launch freely, back-to-back,
> and crowd the sky with simultaneously orbiting moons. The v1 per-world progression (3 captures
> → new planet) is gone; one persistent world escalates over the 60 s clock instead.

- **Scale (cell):** solarSystems
- **Game id:** `orbital_insertion` (widget `OrbitalInsertionGame` in
  `lib/games/solar_systems/orbital_insertion/orbital_insertion_game.dart`)
- **One-line concept:** Fling moons at a planet, back-to-back, and build the biggest
  **simultaneous constellation** of stable orbits you can — every completed lap pays, and moons
  that meet destroy each other.
- **Role:** solo score-attack, 60 s, host-owned clock.

## Why this is great
The single counterintuitive truth of orbital flight — *an orbit is falling around a body, not
hovering* — becomes a tactile balance you feel in your thumb. And the v2 loop adds the second
great truth: **every orbit you launch from the same pad passes back through the pad's radius**,
so a crowded sky isn't safe just because each orbit is individually stable — moons on crossing
paths WILL eventually meet unless you *phase* them (time your launches so they never occupy the
shared crossing at the same moment). Greed vs. phasing is the whole score tension.

## Core loop (v2)
1. One planet holds the upper play area for the whole run, with a dashed **STABLE-ORBIT ring**
   (the circle a perfectly circular orbit through the launch point would trace).
2. **Drag from anywhere toward where you want the moon to go** (direct aim — drag vector = launch
   direction, drag length = power). A live preview integrates the real gravity and classifies the
   shot **CRASH / ORBIT / ESCAPE** before release.
3. Release to fling — and **keep flinging. There is no pause.** Earlier moons keep orbiting while
   you launch the next one. Pacing is only the natural drag gesture plus a tiny
   `0.25 s` debounce cooldown (`_kLaunchCooldown` — gesture-glitch guard, not a mechanic).
   - **Too slow / aimed into the planet → CRASH** (periapsis dips below the surface). Streak resets.
   - **Too fast → ESCAPE.** Unbound energy, or any bound orbit whose apoapsis would cross the
     dashed **DEEP-SPACE boundary** (containment rule, below). **"LOST TO DEEP SPACE."** Streak resets.
   - **Just right → CAPTURE.** The moon swings into a bound ellipse; after sweeping ~half an orbit
     (`_kConfirmSweep = 3.7 rad`) the capture **confirms**, scores, and joins the constellation.
4. **Every full revolution a confirmed moon completes earns points** — announced with a score pop
   and a ring-pulse flash on the moon, the visible heartbeat of a stable orbit.
5. **Moon-vs-moon collisions deduct points and destroy both moons involved.**
   *(Open spec question, resolved by orchestrator interpretation 2026-07-12: Brett specified
   collisions "deduct points"; destruction of both moons is the adopted reading — nothing in the
   existing exact-Kepler physics suggests bounce/merge, and destruction is what makes the
   crowding gamble real. Revisit here first if Brett rules otherwise.)*
6. **Goal:** maximize how many moons orbit **simultaneously** — more moons = more laps ticking =
   more points, but every extra moon raises the odds two orbits meet.

## Outcome physics (exact two-body Kepler — unchanged from v1)
Computed analytically from the launch state relative to the planet (mu = G·M):
- specific energy `E = v²/2 − mu/r` → `E ≥ 0` ⇒ **ESCAPE**.
- bound orbit: semi-major `a = −mu/2E`, eccentricity from the eccentricity vector,
  periapsis `a(1−e)`. **Periapsis ≤ planet radius ⇒ CRASH**, else **CAPTURE**.
- A confirmed capture is animated along its true ellipse via `dν/dt = h/r²` — drift-free, so a
  "stable orbit" really is stable. **Captured conics are frozen at capture time**: the late-round
  mass swell (below) changes the field for NEW launches only; existing orbits keep their locked
  ellipse (a deliberate game abstraction, noted in EDUCATION.md).

## Collision rules (new in v2)
- **Who collides:** every live moon — confirmed orbiters, still-confirming captures, and
  crash/escape fliers — against every other live moon. Uniform rule; no exceptions.
- **Hit test:** centre distance < `2 × moon radius` (the *drawn* radius, i.e. `_kMoonRadius ×`
  the clamped `1/zoom` cosmetic boost — the collision matches what the player sees).
- **Spawn grace:** a moon younger than `0.45 s` (`_kSpawnGrace`) cannot collide — both members
  of a pair must be past grace. Prevents a fresh launch from being deleted under the player's
  finger; the pad-crossing risk still applies the moment grace ends.
- **On collision:** `−60` points (`_kCollisionPenalty`, once per colliding pair), **both moons
  destroyed** with a burst at the meeting point, a `−60 COLLISION` pop, a **COLLISION!** banner,
  and the streak resets. Session score is floored at 0 by the host contract.
- **Fleet cap:** at most `12` live moons (`_kMaxMoons`, orbiters + fliers — perf bound). At the
  cap the launcher refuses and the hint banner reads **SKY FULL**; collisions and crashes free
  slots naturally.

## Scoring (`scoreUnit: "points"`)
Laps are the engine now; the capture payout is the down-payment.
- **Capture (on confirm):** `40` base `+ round((1 − e) × 60)` circularity.
- **Stable-ring bonus:** `+30` if near-circular (`e < 0.16`) and semi-major axis hugs the target
  ring (`|a − ringR| < 16%`).
- **Per completed lap (each confirmed orbiter, every full 2π):**
  `25 + round((1 − e) × 25) + 5 × (other confirmed moons aloft, bonus capped at +30)`.
  Circular orbits lap faster *and* pay more; a crowded sky multiplies the lap income — that's the
  bait that makes you launch one moon too many.
- **Collision:** `−60`, both moons destroyed (see above).
- **Crash / escape:** no point deduction (the moon simply never earned), streak resets.
- **Streak:** consecutive captures with no loss (crash, escape, or collision all reset);
  reported via `session.noteStreak`.

## Containment + camera (every survivable orbit is always fully visible — unchanged mechanics)
- **Containment rule (hard physics):** playable space is a radial circle around the planet — the
  **deep-space boundary**, a faint glaucous dashed ring at `max apoapsis = 1.4 × the stable-ring
  radius` (`_kContainFactor`). Any bound orbit whose apoapsis exceeds it is judged an **ESCAPE**
  at launch (and by the live preview — the label never lies); a flung moon is culled the moment
  it crosses the boundary with a burst and the **LOST TO DEEP SPACE** banner. Exception: a bound
  overshooting orbit that is *diving inward* hits the surface first — stays a CRASH.
- **Camera (view only):** one uniform world→screen zoom, **static for the whole run** (v2 has one
  planet per run; the fit budget always includes the maximum late-round drift amplitude so the
  camera never re-fits mid-run). Cosmetic sizes (moons, strokes, preview dots, labels) are
  boosted by a clamped `1/zoom`; physical sizes stay true. Bursts/pops/banner/drag guide draw in
  screen space. Drag input is a pure direction+power vector — no inverse transform needed.

## Escalation — one world, time-phased over the 60 s clock (replaces v1 world progression)
- **0–18 s · calm:** static planet, base gravity. Learn the band, seed the constellation.
- **≥ 18 s · mass swell:** the planet accretes — `mu` ramps linearly to `+40%` by 60 s
  (`_kSwellStart` / `_kSwellMax`). New insertions need noticeably different speeds; the live
  preview always uses the live `mu`, so it stays the honest guide. Captured orbits stay frozen.
- **≥ 28 s · drift:** the planet starts swaying horizontally (`_kDriftStart`), amplitude easing
  in from zero (no snap) up to `0.09 × width` at `0.8 rad/s`. You must lead a moving target while
  your constellation rides along.
- **≥ 40 s · debris:** a copper debris hazard fades in on the approach lane (`_kHazardStart`).
  It kills **incoming fliers** that clip it (crash); confirmed orbiters ignore it (two-body
  purity — it sits off typical orbit radii).
- Net effect per GAME_DESIGN.md: a perfect final stretch — big constellation, swollen gravity,
  drifting planet, debris on the lane — is humanly impossible to keep clean.

## Legibility (the in-game HUD — what the player is told, when)
- **Always-visible objective** (top bar): *"GOAL · crowd the sky with orbiting moons — laps pay,
  collisions cost."* Plus a live **`N ALOFT · BEST M`** constellation counter.
- **How-to (teaching window, first 2 shots):** bottom banner *"DRAG ANYWHERE TO AIM · LET GO TO
  FLING · KEEP LAUNCHING"*; pulsing ring + up-arrow + **DRAG TO AIM** call-out on the launcher;
  the gold ring labelled **AIM FOR THIS RING**. Fades after 2 launches. After that the banner
  becomes the phasing reminder (*"STACK MOONS · PHASE YOUR LAUNCHES SO ORBITS NEVER MEET"*), or
  **SKY FULL · WAIT FOR A GAP** at the fleet cap.
- **Live aim preview:** trajectory dots + label classify the shot before release as
  **ORBIT! LET GO** (gold), **TOO SLOW · CRASH** (orange), or **TOO FAST · LOST** (glaucous).
- **On capture:** `+N` pop, reason pop (**STABLE ORBIT +30** / **ROUNDER = MORE**), **Nx STREAK**
  pop, banner **CIRCULAR ORBIT!** / **CAPTURED!**.
- **Every completed lap:** `+N` pop at the moon **plus a ring-pulse flash on the moon itself** —
  the lap payout IS the visible proof the orbit is stable.
- **On collision:** burst at the meeting point, `−60 COLLISION` pop, **COLLISION!** banner.

## Educational blocks engaged
solarSystems — **orbital velocity / "falling around"** plus, new in v2, **orbital phasing &
why crowded orbits collide**: all insertions from one pad share a common crossing region, so
period differences decide whether moons meet — the real logic behind rendezvous, constellation
design, and collision avoidance (Kessler). Full write-up in `EDUCATION.md`.

## Potato angle
Light: the projectiles are "moons" (little potato-moons); the gag stays out of the way of the
physics. Don't force it.

## Implementation notes
- Self-contained module; framework deps only (`mini_game.dart`, `fx.dart`, `planet_art.dart`,
  `theme/potatuhs.dart`). The planet renders via the shared **`PlanetArt`** procedural renderer
  (same worlds as Orbit Catch); gravity-well glow + pull rings stay game-side.
- One `Ticker` → real elapsed-dt → `setState` → one `CustomPainter`. Captured orbits analytic
  (cheap, stable); crash/escape moons numerically integrated. Trails hard-capped
  (orbiters 30 pts, fliers 48); collision test is O(n²) over ≤ 12 moons.
- Host owns intro / 3·2·1 / score-HUD / timer / results. The game gates on `session.isRunning`
  and renders only the play area. `autoPilot` launches near-circular insertions on a ~1.3 s
  interval (same handedness, speed-jittered 0.94–1.06 × v_circ, fleet-capped) so ATTRACT mode
  builds a live constellation. No internal game-over.
