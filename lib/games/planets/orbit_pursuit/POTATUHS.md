# POTATUHS — Pursuit

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Pursuit — the planets-scale moving-target variant of Orbit Catch. Self-contained
  module at `lib/games/planets/orbit_pursuit/orbit_pursuit_game.dart` (`OrbitPursuitGame`); a
  registry game on `BioScale.planets`.
- **O — Objectives:** post the highest timed score by intercepting moving catchers — moons on orbits
  and comets on eccentric arcs — as you climb a 10-level ladder that loops with escalating
  difficulty. Sub-goals: chain consecutive intercepts into a streak; clear levels with shots to spare;
  catch fast/leading targets for the lead bonus.
- **T — Tasks (the play to-do list):** drag toward where the shot should go · read the trajectory
  preview (the curve) · read the orbit path + ghost dots (the lead) · line the shot's end onto a
  future ghost, not the live target · dodge the well between you and the catcher · catch every moon to
  clear the level.
- **A — Automations (firing in the background):** the per-frame gravity sim that bends the planetlet
  (`a = G·mass/r²`, 10 sub-steps) · targets whose positions are pure functions of the clock (closed
  ellipses, pro/retrograde) · the live intercept test against each target's current position · the
  seeded layout generator rotating ~many variations per blueprint · the loop escalator (heavier wells,
  smaller catcher, fewer ghost dots).
- **T — Testing (experimental / in-flight):** lead-bonus calibration (`/140` divisor vs.
  `_kLeadBonusMax`) · ghost-dot density vs. fairness at high loops · multi-moon shot economy on
  `Triple Drift` · eccentric-comet readability on tall/narrow web viewports.
- **U — UX:** a full-canvas drag surface · `CustomPainter` everything (no rasters) · gold catcher with
  intake rings + crosshair + orbit path + future ghosts + direction arrow · cool→warm preview dots ·
  glaucous planetlet with a white-cored trail · in-play HUD of shot pips + level label + a
  WarioWare-style hint banner. Host owns countdown / score / timer / results / exit.
- **H — Heuristics (how you actually win):** aim where it WILL be — chase the ghosts, not the orb ·
  the faster the moon, the bigger the lead · lead in the direction of travel (watch the arrow) · a
  faster shot needs a smaller lead · keep the streak alive; a clean intercept compounds.
- **S — Systems (what makes the world feel alive):** the same strong, legible gravity as Orbit Catch
  so the curve feel transfers · orbits and comets that never stop sweeping · the lead-prediction loop
  that is, literally, how spacecraft rendezvous · a data-driven ladder that loops forever so a 60s
  session never dead-ends.
