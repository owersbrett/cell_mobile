# POTATUHS — Organ Rush

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Organ Rush — the organ-scale rapid-fire identification quiz that ping-pongs
  between the **human body** and the **plant/potato body**. Planned widget `OrganQuizGame` in
  `lib/games/arcade/organ_quiz.dart`; data in `lib/games/organ/organ_quiz_data.dart` (`kOrganQuiz`).
- **O — Objectives:** score the most points in a timed round (~45–60 s) by tapping the right organ
  fast. Sub-goals: answer sub-second for max points; build a correct-answer streak; soak the
  fun-fact on every answer.
- **T — Tasks (the play to-do list):** read "The part that …" · tap the correct organ of 4 option
  cards · answer before the per-question timer decays the points · keep the streak alive · glance
  the fact flare, then take the next question as it loads.
- **A — Automations (firing in the background):** the **per-question point-decay timer** (full
  points early, sliding to a floor) · auto-alternating realm (human → plant → human …) · the
  **fun-fact flare** that auto-shows then clears non-blocking · option-shuffle per question + no
  repeat until the pool recycles · MiniGameHost clock/countdown/results.
- **T — Testing (experimental / in-flight):** built to spec, not yet shipped — the widget and the
  **registry swap** (point the Organ spec's builder at `OrganQuizGame`, rename to "Organ Rush",
  scoreUnit "points") are a lead follow-up. A streak multiplier is flagged as a "consider it" tuning
  knob; wrong-answer penalty is kept soft (never hard-fail).
- **U — UX:** four tappable option cards styled to the app · a per-question timer the player can feel
  draining · a brief **shake** on a wrong tap with the correct organ highlighting · the fun-fact
  flare after each answer · Canvas-drawn background/fx, no raster assets.
- **H — Heuristics (how you actually win):** answer **fast** — the decay curve rewards sub-second
  taps far more than safe slow ones · keep the streak unbroken if the multiplier is in · don't
  freeze on plant questions (the tuber is a *stem*, eyes are buds) · take the small wrong-answer hit
  and move on rather than stalling.
- **S — Systems (what makes the world feel alive):** the **two-bodies** through-line — every body,
  animal or plant, is organs doing jobs · the human↔potato ping-pong that keeps the brand present ·
  the fact flare turning every answer into a micro-lesson, the signature Explore mechanic that makes
  the quiz feel like a living teaching machine.
