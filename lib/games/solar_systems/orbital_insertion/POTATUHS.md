# POTATUHS — Orbital Insertion

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Orbital Insertion — the solar-systems-scale capture game (`OrbitalInsertionGame`
  in `lib/games/solar_systems/orbital_insertion/`). Fling a moon at a planet and drop it into a
  stable orbit; too slow it crashes, too fast it escapes, just right it captures and keeps orbiting.
  Replaces the old "Orbital Mechanic".

- **O — Objectives:** post the highest 60-second score by capturing moons into orbit. Sub-goals:
  land **circular** (low-eccentricity) captures for the big bonus · hug the dashed STABLE-ORBIT ring
  for the stable-ring bonus · chain captures without a crash/escape to build the streak · clear 3
  captures per planet to push into harder, higher-scoring worlds; banked orbiters trickle points
  every lap.

- **T — Tasks (the play to-do list):** read the planet's size and gravity-well rings · drag toward
  where the moon should go and watch the preview's CRASH / ORBIT / ESCAPE label · tune power and
  angle until it reads ORBIT (and ideally circular) · release · watch it swing around and confirm
  the capture · repeat to grow the constellation · on a moving planet, **lead the drift**; on a
  debris world, **thread the hazard**.

- **A — Automations (firing in the background):** the exact two-body classifier (`_classify` —
  energy + angular momentum + eccentricity vector → CRASH/ESCAPE/CAPTURE + full orbital elements) ·
  the drift-free Kepler animator advancing each capture along its true ellipse (`dν/dt = h/r²`) ·
  the numeric integrator flying crash/escape moons so you watch them fall in / fly off · per-lap
  passive scoring · the per-planet difficulty roll (shrink, mu jitter, drift, hazard) · the host's
  clock, 3·2·1, score-HUD, results, and AI opponents.

- **T — Testing (experimental / in-flight):** `humanMax` / `starThresholds` are first-pass and need
  playtest retune once Sessions data exists · capture-confirm gate (`_kConfirmSweep`) may feel slow
  for barely-bound highly-eccentric orbits — alternative "passed periapsis" gate noted in AGENT.md ·
  moving-planet frame slightly shears the painted ellipse at high drift (movement kept gentle).

- **U — UX:** direct-aim drag (drag vector = launch direction, length = power) matched to the
  well-liked Orbit Catch feel · a color-coded live trajectory preview that *names the outcome* before
  release — the whole teaching surface · captured orbits drawn as glowing ellipses (brighter =
  rounder) so eccentricity is visible · capture pips + world counter in the corner · calm orbiting
  demo moon on the ready screen. Canvas-only, no raster assets.

- **H — Heuristics (how you actually win):** aim to the **side** of the planet, not at it — orbits
  want tangential speed · find the band between "too slow → crash" and "too fast → escape"; the
  preview shows exactly where it is · chase **circular** (low e) — it scores far more and hugs the
  ring bonus · don't break the streak with a greedy escape · push into higher worlds for the
  systemIndex bonus once captures come easily · on drifting worlds, fire ahead of the planet.

- **S — Systems (what makes the world feel alive):** the lesson IS the system — an orbit is *falling
  around* a body, and the speed-vs-gravity balance is something you feel in your thumb via the
  preview, not a memorised formula · real Keplerian conics mean every capture is a genuine, stable
  orbit and every crash/escape is physically honest · gravity wells, accretion rings, drifting
  worlds, and threadable debris make each planet a distinct insertion puzzle, nodding to the actual
  job of an orbital-insertion burn at Mars, Jupiter, or Saturn.
