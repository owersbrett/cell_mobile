# POTATUHS — Meiosis

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Meiosis — the cell-scale two-division gamete-maker. Game id `meiosis` on the Cell
  scale; a six-in-one (8 micro-games across Division I + II). **STATUS: spec only — no code yet;** the
  GAME.md is the build brief.
- **O — Objectives:** post the highest solo score (~90 s run) by clearing all 8 meiotic phases and
  ending in 4 unique haploid gametes. Sub-goal: land all 4 crossing-over swaps in Prophase I (+30 each).
- **T — Tasks (the play to-do list):** swap a gene band between each homologous pair (Prophase I) ·
  drag bivalents/chromosomes to the centre plate (Metaphase I/II) · swipe pairs to opposite poles
  (Anaphase I/II) · tap nucleus outlines to seal then drag the cleavage furrow (Telophase/Cytokinesis).
- **A — Automations (firing in the background):** the per-phase countdown timer auto-advancing each
  stage if it expires (50 base, no speed bonus) · the interstitial "NO DNA REPLICATION" banner gating
  Division II · the crossover spark/chiasmata (X-mark) effects · the 4-gamete fan-out burst finale.
- **T — Testing (experimental / in-flight):** the whole game is **unbuilt** — Prophase I drag-and-swap
  is a brand-new gesture to author, plus bivalent rendering, the side-by-side dual-cell Division II
  layout, and the 2n→n ploidy-label system. Much of the phase-timer/results scaffold is to be reused
  from Mitosis Rush.
- **U — UX:** drag-band-to-homologue for crossing over · drag-to-plate, vertical swipe, and
  tap-to-seal gestures across phases · `CustomPainter` chromosomes with centromeres and chiasma X
  marks · per-phase progress labels (`CROSSING OVER` → `FOUR GAMETES`) · non-punishing silent fails.
- **H — Heuristics (how you actually win):** nail all 4 Prophase I crossovers — they're the only
  partial-credit bonus and the hardest phase (15 s) · finish non-crossover phases early for up to
  +100 speed bonus · in Division II split attention evenly across both cells to hit all 4 targets fast.
- **S — Systems (what makes the world feel alive):** one cell visibly carried through two real
  divisions with a clear I/II boundary · genetic recombination made tactile · the potato-breeding
  arc — crossing over is how every new cultivar's gametes were shuffled; 4 gametes = 4 possible seeds.
