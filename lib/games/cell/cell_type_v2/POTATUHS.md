# POTATUHS — Cell Type v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Cell Type v2 — the UX-refined cell-scale classification game. Game id
  `cell_type_v2` on `BioScale.cell` (`CellTypeV2Game`). Read a procedurally-drawn cell and name it
  PLANT / ANIMAL / BACTERIAL / FUNGAL, rebuilt to the teardown brief so the round accelerates and the
  scoring rewards real recognition, not just a memorised tap.

- **O — Objectives:** post the highest score in the 60 s session by **snap-reading** specimens while
  they're still hazy (big read bonus, high risk) and chaining correct calls into the capped streak
  multiplier, then doubling down in the FINAL CELLS ×2 climax.

- **T — Tasks (the play to-do list):** scan the silhouette + size first · resolve the deciding tell
  (nucleus? wall? green?) · commit BEFORE the bonus ring drains for the ×1.8 snap · don't break the
  streak on a greedy bad snap · use the legend until the tells are in your hands · feast in the surge.

- **A — Automations (firing in the background):** the **resolve clock** (each cell sharpens over
  `1.5s→0.9s`, faster in the surge) · the **bonus ring + read multiplier** draining `×1.8→×1.0` ·
  the **tell-degradation by progress** (subtle plants, rod→coccus bacteria, fungal≈plant) · the
  **capped streak multiplier** (`+1×` per 3, cap `×3`) · **instant confirm + next-cell load** (no
  gate) · the **non-blocking toasts** (short tell on hit, full fact on miss) · the **FINAL CELLS**
  escalation + TIME! flourish.

- **T — Testing (experimental / in-flight):** star thresholds `[700,1400,2200]` / `humanMax 2200`
  are a first estimate pending playtests · `_kReadMax 1.8` vs the focus window want co-tuning so the
  snap is tempting but a blind guess still loses on miss-rate · drop-and-resume not persisted.

- **U — UX:** the pace fix — the original's mandatory 1.9 s flare is **gone**; the round accelerates ·
  the legibility fix — a **visible bonus ring + live ×N** replaces the original's invisible shrinking
  decay window · the scaffold fix — a persistent on-screen **LEGEND** (the decision tree) that fades
  with mastery · canvas choice buttons with brief press feedback · alarm vignette + banner in the
  climax.

- **H — Heuristics (how you actually win):** read **size first** — a tiny cell is bacterial before
  any other tell resolves · green = plant, walled-but-not-green = fungal, no wall = animal, no nucleus
  = bacterial · the snap is worth it only when you're *sure* — a reset streak costs more than a
  ×1.8 · in the surge, trust the silhouette and bank fast, the ×2 is where leads are made or erased.

- **S — Systems (what makes it feel alive):** a microscope that brings each specimen **into focus**,
  turning recognition speed into a scored, legible risk · procedurally accurate organelles that ARE
  the evidence · a difficulty ramp you can *see* (legend fading, tells degrading, focus quickening) ·
  a capped economy where a trailing player can always snap their way back — the fair, readable
  standing a party game lives or dies on.
