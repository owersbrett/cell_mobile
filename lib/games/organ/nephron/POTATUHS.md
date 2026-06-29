# POTATUHS — Nephron

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Nephron — the organ-scale game (run the kidney's filter). Self-contained module
  (`NephronGame` in `lib/games/organ/nephron/`); on `BioScale.organ`. Host owns the
  clock/countdown/score/results; the module renders only the play area.
- **O — Objectives:** post the highest score across the 60 s round by **filtering blood correctly** —
  reabsorb every nutrient back into the blood, route every toxin to the urine, and keep BLOOD PURITY out
  of the red. Sub-goals: chain correct calls for the streak multiplier (up to ×3) and survive the LV ramp.
- **T — Tasks (the play to-do list):** read each falling molecule (symbol + label) · **flick good ones
  LEFT** into the blood before they fall out · let waste fall, or **flick it RIGHT** to urine · never keep
  a toxin in the blood · watch for the LV3 trap — *needed* vs *excess* sodium look identical, read the tag.
- **A — Automations (firing in the background):** ONE Ticker spawning molecules from the glomerulus,
  advancing their fall, animating commits to the gutters, stepping particles + score pops · the difficulty
  ramp (faster flow, more types, subtler calls every level) · blood-purity drain/regen · the streak
  multiplier · the `endEarly` trip when purity hits zero.
- **T — Testing (experimental / in-flight):** tune `humanMax`/`starThresholds` and the health constants
  so a careless player *can* clog the filter while a skilled one never does; confirm the subtle sodium call
  reads fairly at LV3+ speed; verify clean session re-entry after both a timeout and an `endEarly`.
- **U — UX:** Canvas-only — a central wavy tubule with downward plasma flow, a coiled glomerulus at the
  top, a red BLOOD vessel on the left and an amber URINE duct on the right, labelled molecule orbs, an
  urgency ring near the exit, a BLOOD PURITY bar + LV/×mult HUD, and a calm ready overlay explaining the
  flick controls.
- **H — Heuristics (how you actually win):** prioritise **reabsorbing nutrients** — waste exits for free if
  you ignore it, but a missed nutrient is gone · don't panic-flick; a wrong reabsorb (waste in blood) is
  the most expensive mistake · keep the streak alive — the multiplier is where the score compounds · at
  high levels, *read the label*, don't trust the colour.
- **S — Systems (what makes the world feel alive):** the nephron *is* the living system — blood pours in
  indiscriminately and the player performs the kidney's selective reabsorption by hand. The lesson (a
  kidney dumps everything then rescues the good stuff — see EDUCATION.md) is embodied in the "default =
  urine, reabsorption = active" mechanic, not narrated.
