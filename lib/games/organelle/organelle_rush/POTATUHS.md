# POTATUHS — Organelle Rush

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Organelle Rush — the organelle-scale WarioWare rush. Self-contained module
  (`lib/games/organelle/organelle_rush/`, widget `OrganelleRushGame`); registers on
  `BioScale.organelle` and mounts in MiniGameHost. **Status: UNBUILT (forward build-spec).**
- **O — Objectives:** post the highest aggregate score across eight ~20 s micro-games (~160–180 s
  total). Sub-goals: nail each segment's perfect bonus (+20–30), clear all eight for the +100
  all-clear, and absorb the ORGANELLE_REVEAL fact card each segment leaves behind.
- **T — Tasks (the play to-do list):** tap the inside-out zoom targets (Seg 1) · sort ER vesicles by
  lane (Seg 2) · swipe Golgi cargo to the right chute (Seg 3) · tap the complementary DNA base
  (Seg 4) · match codon→amino-acid (Seg 5) · pair glucose+O₂ then grab ATP (Seg 6) · drag-aim-fire
  spindle fibers (Seg 7) · sweep peroxisomes through free radicals (Seg 8).
- **A — Automations (firing in the background):** the host's per-segment ~20 s sub-timer that hard-caps
  and advances each micro-game · the per-frame spawn/speed ramp inside every segment · auto-shuffle of
  segment order on replay (all but Seg 1) · the ORGANELLE_REVEAL flare auto-cycling its fact cards ·
  the MiniGameHost session clock + intro/countdown/results wrapping the whole rush.
- **T — Testing (experimental / in-flight):** the whole game is unbuilt — a forward spec. Segment 1
  always-first vs. shuffle of 2–8 is an open tuning seam; per-segment ramps (spawn rate, codon timer,
  combo window) are exposed for tuning; a future "disrupt variant" is flagged but not specified.
- **U — UX:** eight distinct control idioms back-to-back (tap rings, lane-tap, swipe-sort, falling-base
  tap, codon-match tap, proximity-pair tap, drag-aim-fire, drag-sweep) · Canvas-drawn anatomy
  cross-sections · the cinematic ORGANELLE_REVEAL card holding on the "round complete" banner ·
  cosmetic damage meters (no mechanical loss) so missing never gates the breadth tour.
- **H — Heuristics (how you actually win):** chase perfect bonuses, not raw taps — +20–30 each dwarfs
  single interactions · learn the two recall segments (DNA pairing A-T/G-C, the on-screen codon table)
  before they speed up · in Mitochondria never hoard glucose without O₂ (fermentation-stink penalty) ·
  treat misses as cheap (no fail state) and prioritize the all-clear +100.
- **S — Systems (what makes the world feel alive):** the framing zoom into a potato tuber's cell · the
  "cell as a city of simultaneous specialists" theme · each segment IS its organelle's real job
  (sorting is the Golgi, pairing is base-pair complementarity) · the Seg-5 "unsung heroes" seed that
  Protein Factory later pays off · ATP coins that visually rhyme with the Molecular-scale ATP icon.
