# GAME.md — Orbital Insertion

> Canonical spec (the **M** in GAMES) for the Solar-Systems-scale capture game. Replaces the
> "Orbital Mechanic" spiral/sort game. Rules live here — update this first, then the code.

- **Scale (cell):** solarSystems
- **Game id:** `orbital_insertion` (widget `OrbitalInsertionGame` in
  `lib/games/solar_systems/orbital_insertion/orbital_insertion_game.dart`)
- **One-line concept:** Fling a moon at a planet and try to drop it into a **stable orbit** — too
  slow it crashes, too fast it escapes, just right (and tangential) it captures and keeps orbiting.
- **Role:** solo score-attack, 60 s, host-owned clock.

## Why this is great
The single counterintuitive truth of orbital flight — *an orbit is falling around a body, not
hovering* — becomes a tactile balance you feel in your thumb. The live trajectory preview labels
the shot **CRASH / ORBIT / ESCAPE** before you release, so the speed-vs-gravity window is directly
learnable, not memorised. Rounder captures are visibly and numerically better, so you chase the
clean circular orbit.

## Core loop
1. A planet sits in the upper play area with a dashed **STABLE-ORBIT ring** (the circle a perfectly
   circular orbit through the launch point would trace).
2. **Drag from anywhere toward where you want the moon to go** (direct aim — drag vector = launch
   direction, drag length = power). A live preview integrates the real gravity and classifies it.
3. Release to fling:
   - **Too slow / aimed into the planet → CRASH** (periapsis dips below the surface). Lost; streak resets.
   - **Too fast → ESCAPE.** Unbound (hyperbolic) energy — **or any bound orbit whose apoapsis
     would cross the dashed DEEP-SPACE boundary** (the containment rule, below). The moon is
     visibly flung across the boundary and bursts: **"LOST TO DEEP SPACE"**. Lost; streak resets.
   - **Just right → CAPTURE.** The moon swings into a bound ellipse; once it sweeps past ~half an
     orbit the capture **confirms** and scores.
4. A confirmed moon **keeps orbiting forever** and trickles points every completed lap. Captures
   chain into a small constellation that all scores at once.

## Outcome physics (exact two-body Kepler)
Computed analytically from the launch state relative to the planet (mu = G·M):
- specific energy `E = v²/2 − mu/r` → `E ≥ 0` ⇒ **ESCAPE**.
- bound orbit: semi-major `a = −mu/2E`, eccentricity from the eccentricity vector,
  periapsis `a(1−e)`. **Periapsis ≤ planet radius ⇒ CRASH**, else **CAPTURE**.
- A confirmed capture is animated along its true ellipse via `dν/dt = h/r²` — drift-free, so a
  "stable orbit" really is stable.

## Containment + camera (every survivable orbit is always fully visible)
- **Containment rule (hard physics):** playable space is a radial circle around the planet — the
  **deep-space boundary**, drawn as a faint glaucous dashed ring at
  `max apoapsis = 1.4 × the stable-ring radius` (`_kContainFactor`). Any bound orbit whose
  apoapsis exceeds it is judged an **ESCAPE** at launch (and by the live preview — the label
  never lies); the flung moon is culled the moment it crosses the boundary with a burst and the
  **LOST TO DEEP SPACE** banner, exactly once — never invisible-but-alive. Exception: a bound
  overshooting orbit that is *diving inward* hits the surface before deep space, so it stays a
  CRASH. The old rectangular off-screen cull is gone; containment is radial and visible.
- **Camera (view only, physics untouched):** the world renders through a uniform world→screen
  zoom (`canvas` translate/scale), **static per planet**, sized so the containment circle (plus
  the planet's drift amplitude) fits the viewport with ~8% padding. Chosen static (not a chasing
  auto-zoom) so the arena is readable and the camera never moves mid-shot; it only re-fits when
  a new world rolls in. Cosmetic sizes (moons, stroke widths, preview dots, labels) are boosted
  by a clamped `1/zoom` so nothing goes hairline-thin; physical sizes (planet, hazard, ring
  radii) stay true. Bursts/score pops/banner/drag guide draw in screen space. Drag input is a
  pure direction+power vector (no world-point hit-testing), so aiming needs no inverse transform.
- **Consequence for play:** the "too fast" side of the capture band is tighter than the crash
  side (near-escape ellipses are huge), which pushes players toward the round, high-scoring
  orbits — the preview's CRASH / ORBIT / ESCAPE label is the honest guide.

## Scoring (`scoreUnit: "points"`)
- **Capture:** `90` base `+ round((1 − e) × 170)` circularity `+ systemIndex × 16`.
- **Stable-ring bonus:** `+70` if the orbit is near-circular (`e < 0.16`) and its semi-major axis
  hugs the target ring (`|a − ringR| < 16%`).
- **Per lap (each orbiter, while it orbits):** `10 + round((1 − e) × 26)` — circular orbits lap
  faster *and* score more per lap.
- **Streak:** consecutive captures; reported via `session.noteStreak`.

## Progression — each round is a new planet
- `3` captures clears a planet; a new, harder one arrives (constellation graduates with a flourish).
- Ramp: planet **shrinks** (44→24 px) · gravity **mu varies** per planet (capture speed shifts) ·
  from World 4 the planet **drifts** (you must lead it) · from World 6 a **debris hazard** sits on
  the approach path to thread.

## Legibility (the in-game HUD — what the player is told, when)
Comprehension is a first-class rule here; the physics is only fun once the player knows what
they're doing. On-screen, at all times / at the right moment:
- **Always-visible objective** (top bar): *"GOAL · settle the moon into a steady orbit to score."*
  Never disappears — the answer to "what am I doing?" is always on screen.
- **How-to (teaching window, first 2 shots):** bottom banner reads *"DRAG ANYWHERE TO AIM · LET GO
  TO FLING"*; a pulsing ring + up-arrow + **DRAG TO AIM** call-out sits on the launcher until the
  first fling; the gold ring is labelled **AIM FOR THIS RING**. All of it fades after 2 launches so
  the field stays clean once understood. After that the banner becomes the balance reminder
  (*"AIM FOR THE GOLD RING · TOO SLOW CRASHES, TOO FAST FLIES OFF"*).
- **Live aim preview (score-driver):** the trajectory dots + label classify the shot before release
  as **ORBIT! LET GO** (gold, scores), **TOO SLOW · CRASH** (orange), or **TOO FAST · LOST**
  (glaucous). This is the direct action→outcome→reward link.
- **On capture:** `+N` pop, plus a reason pop — **STABLE ORBIT +70** when it hugs the ring, or
  **ROUNDER = MORE** on a wobbly capture — and an **Nx STREAK** pop; banner **CIRCULAR ORBIT!** /
  **CAPTURED!**. Per-lap `+N` pops keep showing the orbit paying out. So the player always sees
  *why* the number moved.

## Educational blocks engaged
solarSystems — **orbital velocity / "falling around"**: the balance of gravity vs tangential speed,
why too slow falls in and too fast flies off, and why a circular orbit is a specific speed. Full
write-up in `EDUCATION.md`.

## Potato angle
Light: the projectile is a "moon" (a little potato-moon); the gag stays out of the way of the
physics. Don't force it.

## Implementation notes
- Self-contained module; framework deps only (`mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`).
- One `Ticker` → `setState` → `CustomPainter`. Captured orbits are analytic (cheap, stable);
  crash/escape moons are numerically integrated so you watch them fall in / fly off.
- Host owns intro / 3·2·1 / score-HUD / timer / results. The game gates on `session.isRunning`
  and renders only the play area (calm orbiting demo moon while not running).
