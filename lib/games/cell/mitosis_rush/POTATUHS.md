# POTATUHS — Mitosis Rush

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Mitosis Rush — the cell-scale gesture-driven cell-cycle run. Game id `mitosis_rush`
  on the Cell scale; a deliberately lopsided six-in-one where Interphase (G1·S·G2) is ~90% of playtime.
  Current `MitosisRushGame` is the OLD tap/drag build awaiting the gesture redesign in this spec.
- **O — Objectives:** post the highest solo score by running one continuous cell through the full
  cycle — most of the score lives in Interphase — then ending after Cytokinesis's slice.
- **T — Tasks (the play to-do list):** reverse-pinch along the prompted axis to grow (G1/G2) · tap the
  correct complement base A↔T / G↔C as the queue scrolls (S) · pinch to condense (Prophase) · lock/key
  align (Metaphase) · reverse-pinch L→R to separate (Anaphase) · scrub (Telophase) · slice to split.
- **A — Automations (firing in the background):** the per-stage QTE timers and prompt cycling (4
  growth axes) · the scrolling base-pair queue · the escalation within Interphase (faster prompts,
  tighter helix tolerance) · the streak/combo multiplier optionally carried from Interphase into the
  mitosis sprint · the results screen on the final slice.
- **T — Testing (experimental / in-flight):** the **entire gesture redesign is the in-flight work** —
  one continuous cell object replacing the old four disconnected `_ChromatinBlob`/`_Chromosome`/
  `_ChromatidPair`/`_Nucleus` types (the visual-continuity bug) · the S-phase drawing mechanic was cut
  for unreliability and replaced by base-tap · the Metaphase lock/key placement is an open question.
- **U — UX:** a rich gesture vocabulary (reverse-pinch · pinch · tap-match · lock/key · scrub · slice)
  · everything acts on one continuous, never-teleporting cell · `CustomPainter`, no raster assets · the
  pacing contrast (long Interphase vs. fast 5-step sprint) is the felt UX and the lesson.
- **H — Heuristics (how you actually win):** treat Interphase as the score zone — bank volume on
  G1/G2 reverse-pinches and chain a clean fast S-phase streak · keep gestures crisp (sloppy mitosis
  steps score less) · carry the Interphase combo into the sprint for the multiplier bonus.
- **S — Systems (what makes the world feel alive):** the cell cycle's real proportion lived rather
  than told — you *feel* that interphase takes the longest · one cell stretched, condensed, and split
  continuously · the potato angle — a growing stolon tip runs this exact loop millions of times.
