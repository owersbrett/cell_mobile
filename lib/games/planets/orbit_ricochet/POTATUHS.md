# POTATUHS — Ricochet

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Ricochet — the planets-scale bank-shot game; a self-contained variant of Orbit
  Catch. Module at `lib/games/planets/orbit_ricochet/orbit_ricochet_game.dart` (`OrbitRicochetGame`);
  registry game on `BioScale.planets`, id `orbit_ricochet`.
- **O — Objectives:** post the highest timed score by potting planetlets into the catcher off BODY
  banks. Sub-goals: stack body caroms (`+30` live each, `+55` more per carom at the catch), avoid
  the wall tax (`−15` per wall carom), clear the 10-level ladder for level/loop bonuses, and keep a
  clear streak for the mastery award.
- **T — Tasks (the play to-do list):** drag TOWARD the target to launch · read the cue preview
  (straight line → impact ring → reflected stub) · clip the edge of a planet or asteroid so the
  paying carom drops into a hidden catcher · lead drifting catchers before you bank · land
  multi-bank shots before the flight budget decays.
- **A — Automations (firing in the background):** the per-frame sub-stepped pure-billiards physics —
  straight-line flight plus mirror reflection (`v' = v − 2(v·n)n`) off bodies and the four walls,
  each scaled by restitution · per-surface scoring (bodies pay, walls cost, floor at 0) · the seeded
  layout generator that rotates variations per attempt · the shrinking flight-time budget (faster
  decay) and loop escalation (bigger bodies, smaller catcher).
- **T — Testing (experimental / in-flight):** the wall-bleed worst case on a full-miss shot (−15 per
  carom until the budget dies) pending playtest · no SFX yet · `humanMax`/`starThresholds` are a
  first-pass calibration (`2900` / `[1000, 1900, 2900]`) pending playtest.
- **U — UX:** a full-field drag surface · `CustomPainter` everything (no raster) · well rings as
  ambient dressing + a bright reflective rim, asteroids with facet ticks, a glowing reflective wall
  frame · aim arrow + power ring + a cue-style preview that is EXACT to the first contact (gold =
  pot/paying body, warning orange = costing wall) · live shot with a comet trail and a per-BODY-bank
  halo so the paying bank count reads in real time · "+30"/"−15" pops right at the contact points.
- **H — Heuristics (how you actually win):** body banks are the multiplier — straight pots are fine
  but body-bank catches climb · hit a round body off-center to swing the reflected angle hard · the
  wall route always works but always costs — take it only when the body line isn't there · don't
  dawdle (restitution + the decaying flight budget kill slow plans) · trust the cue line completely;
  hold the bounces after the first in your head.
- **S — Systems (what makes the world feel alive):** cosmic billiards — specular reflection at the
  instant of contact and dead-straight flight between, priced by surface: the geometry-hard convex
  bodies pay you, the forgiving flat rails charge you, compressed into a single thumb-flick bank shot.
