# POTATUHS — Ricochet

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Ricochet — the planets-scale bank-shot game; a self-contained variant of Orbit
  Catch. Module at `lib/games/planets/orbit_ricochet/orbit_ricochet_game.dart` (`OrbitRicochetGame`);
  registry game on `BioScale.planets`, id `orbit_ricochet`.
- **O — Objectives:** post the highest timed score by catching planetlets that ricochet into the
  catcher. Sub-goals: stack BANKS (each bounce on the catching shot pays `+55`), clear the 10-level
  ladder for level/loop bonuses, and keep a clear streak for the mastery award.
- **T — Tasks (the play to-do list):** drag TOWARD the target to launch · read the curve from the
  gravity wells · aim at a wall, planet surface, or asteroid so the carom drops into a hidden catcher ·
  lead drifting catchers before you bank · land multi-bank shots before the flight budget decays.
- **A — Automations (firing in the background):** the per-frame sub-stepped physics — inverse-square
  gravity from every body, plus mirror reflection (`v' = v − 2(v·n)n`) off bodies and the four walls,
  each scaled by restitution · the seeded layout generator that rotates variations per attempt · the
  shrinking flight-time budget (faster decay) and loop escalation (heavier bodies, smaller catcher).
- **T — Testing (experimental / in-flight):** preview-vs-live drift on long multi-bank shots (first
  bounce is exact, later bounces are a forecast) · no SFX yet · `humanMax`/`starThresholds` are a
  first-pass calibration (`2900` / `[1000, 1900, 2900]`) pending playtest.
- **U — UX:** a full-field drag surface · `CustomPainter` everything (no raster) · gravity wells with
  mass-scaled rings + a bright reflective rim, asteroids with facet ticks, a glowing reflective wall
  frame · aim arrow + power ring + a trajectory preview that's bright to the first carom and faint
  after, with a ring on the predicted first-bounce point · live shot with a comet trail and a
  per-bounce halo so the bank count reads in real time.
- **H — Heuristics (how you actually win):** banks are the multiplier — straight catches are fine but
  bank catches climb · hit a round body off-center to swing the reflected angle hard · skim near a
  giant for a gravity assist into a new heading · don't dawdle (restitution + the decaying flight
  budget kill slow plans) · aim with the bright preview, treat the faint tail as a hint.
- **S — Systems (what makes the world feel alive):** the two-physics stack — reflection at the instant
  of contact, gravity curving every span between bounces — the same maneuver real probes use to
  slingshot across the solar system, here compressed into a single thumb-flick bank shot.
