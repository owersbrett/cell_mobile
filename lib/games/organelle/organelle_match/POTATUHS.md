# POTATUHS — Organelle Match

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives,
> Tasks, Automations, Testing, UX, Heuristics, and Systems. One profile per game.

- **P — Project:** Organelle Match — the organelle-scale function/clue match quiz. Module at
  `lib/games/organelle/organelle_match/organelle_match_game.dart` (`OrganelleMatchGame`);
  registry game on `BioScale.organelle`.
- **O — Objectives:** post the highest timed score by matching each clue to the organelle
  that does it. Sub-goals: build a long correct streak to climb the multiplier; answer fast
  enough to bank near-max speed bonuses; survive the late-round confusable distractors.
- **T — Tasks (the play to-do list):** read the clue ("...captures sunlight to make sugar")
  · tap the right organelle from four · go fast while the speed window is wide · keep the
  streak alive across the subtler late-round options · glance the fact card, then push on.
- **A — Automations (firing in the background):** the difficulty ramp
  (`max(elapsedFraction, answered/10)`) that tightens the speed window 4.0 s → 1.8 s and
  pulls more distractors from the confusable set · the reshuffled question queue guaranteeing
  full organelle coverage before repeats · the streak multiplier reported to the host via
  `noteStreak` · the single-Ticker particle field bursting on each correct answer.
- **T — Testing (experimental / in-flight):** content accuracy of the nine organelle jobs
  and facts is the live QA surface · star thresholds `[500, 1000, 1600]` and `humanMax`
  1800 are first-pass estimates, to be tuned by playtest · semantic-category distractor
  weighting is an open refinement.
- **U — UX:** dark membrane-glow field · ORGANELLE scale chip · big centered clue under a
  "Tap the organelle that" label · a 2×2 option grid that resizes to the viewport (never
  clips) · correct=green / wrong=red shake · a bottom fact card (name · job · fun fact) that
  overlays rather than steals column space · tap-to-skip · timer reddens under 5 s.
- **H — Heuristics (how you actually win):** answer on instinct while the window is wide ·
  never break the streak for a guess — the multiplier compounds harder than one fast tap ·
  learn the confusable pairs (mito/chloro, ribosome/ER, Golgi/ER/vacuole) because that's
  where the late-game points and traps live.
- **S — Systems (what makes the world feel alive):** the cell-as-a-city model where each
  organelle is a worker with one job · the self-tightening difficulty loop that rewards both
  speed and accuracy · the fact-card feedback channel that turns every answer — right or
  wrong — into a micro-lesson.

---

## Potato angle

The cell-city framing is pure Potatuhs: a potato is built cell by cell, and the chloroplast
clue ("captures sunlight to make sugar") is exactly how a potato plant fills its tubers with
starch. Mitochondria vs. chloroplast — burn sugar vs. make sugar — is the whole energy story
of how a spud grows in the field and how it powers you when you eat it.
