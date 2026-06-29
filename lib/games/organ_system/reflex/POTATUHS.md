# POTATUHS — Reflex

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Reflex — the organSystem-scale pure-reaction game. Module at
  `lib/games/organ_system/reflex/reflex_game.dart` (`ReflexGame`); a `BioScale.organSystem` title.
- **O — Objectives:** post the highest timed score across ~20 reaction trials in 50 s. Sub-goals:
  string a clean streak of FAST/LIGHTNING reactions (streak bonus); never eat a false start or a
  damage timeout; learn the reflex arc by tracing it every trial.
- **T — Tasks (the play to-do list):** wait through an unpredictable delay · ignore the brain decoy ·
  tap the instant the receptor fires · keep reaction under the shrinking damage window · chain hits
  to grow the ×streak multiplier.
- **A — Automations (firing in the background):** the single-ticker trial machine — randomised
  pre-stimulus delay, decoy scheduler, the damage ring filling against a per-trial limit, the impulse
  auto-travelling receptor → cord → muscle on a hit, and the difficulty ramp that shortens delays /
  damage windows and raises decoy odds as the trial count climbs.
- **T — Testing (experimental / in-flight):** `humanMax`/`starThresholds` are first-pass (retune by
  playtest) · single stimulus site (variety = future) · no audio cue · no in-session restart (host
  owns restart).
- **U — UX:** full-field tap surface · `CustomPainter` arc drawn with `GameFx` orbs/glow-lines ·
  receptor (orange) → spinal cord (lime) → muscle (gold), brain faded + dotted "bypassed" above ·
  big phase callout (WAIT… / REACT! / result) + ms readout + TRIAL/×streak HUD · red flash on false
  start, expanding shock ring on stimulus, muscle contraction on response.
- **H — Heuristics (how you actually win):** react to the *receptor*, never the brain decoy · don't
  pre-fire — a reflex is a response, not a guess · faster always pays (speed curve) so commit the
  instant of the flash · ride a streak once you're warm — the ×bonus compounds.
- **S — Systems (what makes the world feel alive):** the reflex arc itself, animated end-to-end every
  trial · the escalating delay/damage/decoy pressure that turns a calm tap into a nerve test · the
  brand beat — an animal body is a frantic millisecond circuit, while the potato just sits in the
  calm soil (the optional plant contrast in EDUCATION.md).
