# POTATUHS — Reflex Gate (reflex_v2)

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Reflex Gate — the refined organSystem-scale go/no-go reaction game. Module at
  `lib/games/organ_system/reflex_v2/reflex_v2_game.dart` (`ReflexV2Game`); a `BioScale.organSystem`
  title. The UX-refinement sibling of `reflex` (v1): same legibility, new judgement ceiling.
- **O — Objectives:** post the highest timed score across ~25 trials in 50 s. Sub-goals: discriminate
  ORANGE (react) from TEAL (inhibit) under speed pressure; never misfire on a NO-GO; ride the CHARGE
  multiplier to ×3.5 without dropping it; learn the reflex arc — and that the reflex is *graded* — by
  playing it.
- **T — Tasks (the play to-do list):** wait through an unpredictable delay · ignore the brain decoy ·
  on ORANGE tap the instant it fires · on TEAL do nothing and let the inhibit ring drain · chain clean
  decisions to grow ×charge · beat your own BEST ⚡ reaction time.
- **A — Automations (firing in the background):** the single-ticker trial machine — randomised
  pre-stimulus delay, go/no-go cue selection, decoy scheduler, the GO damage arc filling vs the NO-GO
  inhibit ring draining, the impulse auto-travelling receptor → cord → muscle on a hit, the charge
  multiplier compounding/collapsing, and the difficulty ramp + final-12 s climax that shorten delays,
  raise NO-GO odds, and ramp screen-shake/glow.
- **T — Testing (experimental / in-flight):** `humanMax`/`starThresholds` first-pass (charge makes
  totals sensitive — retune by playtest) · cue-similarity hard mode is an idea, not built · no audio
  cue · no in-session restart (host owns restart).
- **U — UX:** full-field tap surface · `CustomPainter` arc drawn with `GameFx` orbs/glow-lines ·
  receptor flashes ORANGE (REACT) or TEAL (HOLD) → spinal cord (lime) → muscle (gold), brain faded +
  dotted "bypassed" above · big phase callout (WAIT… / REACT! / HOLD! / result ×charge) + ms readout ·
  always-on CHARGE meter + BEST ⚡ ghost · red flash + screen-shake on a misfire, shock ring on a cue.
- **H — Heuristics (how you actually win):** read the colour *before* you move — ORANGE only · holding
  a TEAL is a win, not a waste · the charge multiplier means one greedy misread costs more than a slow
  reaction ever does · don't pre-fire — a reflex is a response, not a guess · once warm, protect the
  charge above chasing raw speed.
- **S — Systems (what makes the world feel alive):** the reflex arc animated end-to-end on every GO ·
  the muscle staying calm on a correct HOLD (inhibition made visible) · the escalating
  delay/NO-GO/decoy pressure plus the climax that turns a calm tap into a nerve test · the brand beat —
  an animal body is a frantic, *discriminating* millisecond circuit, while the potato just sits in the
  calm soil (the optional plant contrast in EDUCATION.md).
