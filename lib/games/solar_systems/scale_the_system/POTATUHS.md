# POTATUHS — Scale the System

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Scale the System — the solar-systems-scale relative-size drawing game (`SolarSortGame`
  in `mini_games_batch3.dart`). Draw two circles at the right **relative size** to compare neighboring
  bodies, then a spiral-spam finale.
- **O — Objectives:** post the highest score by drawing ratios that match true planetary scale. Sub-goals:
  nail each adjacent-neighbor pair (Sun→Mercury → … → Uranus→Neptune); earn "PERFECT SCALE" flourishes;
  cash out big on the spiral finale.
- **T — Tasks (the play to-do list):** read which two bodies the round names · draw a rough circle for
  body A · draw a second circle for body B, judging it against the first · let the round score your drawn
  radius ratio vs the true ratio · read the reveal (real ratio + fact) · in the finale, spam spirals as
  fast as you can.
- **A — Automations (firing in the background):** the circle-fit that turns each freehand gesture into a
  centroid + mean radius · the per-round accuracy scoring on a log-scale tolerance (`base × accuracy`) ·
  the reveal beat that surfaces the true ratio + fact after each attempt · the internal round/timer/results
  loop, restart, and (when promoted) the host clock and AI opponents.
- **T — Testing (experimental / in-flight):** reworked from the old freehand-spiral "Orbital Mechanic"
  game — edit ONLY the `SolarSortGame` class in the megafile · bake in the mean radii + notable-ratio
  facts · the old spiral-draw code is reused for the finale · optional gag still open: a "potato to Sun"
  tininess reveal at the very end.
- **U — UX:** freehand circle-drawing surface, forgiving (it's the ratio scored, not circle perfection) ·
  a clear prompt of which body to draw now · the first circle stays on screen while you draw the second so
  you can judge relative size · per-round reveal of the true ratio + fact. Canvas-only.
- **H — Heuristics (how you actually win):** draw the ratio, not the absolute size — the second circle's
  size relative to the first is all that scores · trust the counterintuitive truths (Venus ≈ Earth, Mars ≈
  half Earth, the Sun dwarfs everything ~285:1) over your gut · accept you literally can't draw Mercury to
  scale beside the Sun — get close · spam the spiral finale flat-out for the free points dump.
- **S — Systems (what makes the world feel alive):** the lesson IS the system — making you *draw* the ratio
  and watch how wrong your intuition is teaches real solar-system scale · per-round facts (Earth's near-twin
  Venus, half-width Mars, 11-Earth-wide Jupiter) · the spiral finale framed as the spinning protoplanetary
  disk, nodding to how systems actually form.
