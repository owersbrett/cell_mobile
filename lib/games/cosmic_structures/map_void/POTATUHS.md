# POTATUHS — Map the Void

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Map the Void — the cosmic-structures-scale classification game. Self-contained module
  (`lib/games/cosmic_structures/map_void/map_void_game.dart`, `MapVoidGame`); on
  `BioScale.cosmicStructures`, host-driven, 60s.
- **O — Objectives:** post the highest score by correctly classifying as many survey regions as possible
  — tag each framed patch as CLUSTER, FILAMENT, or VOID, fast and in long streaks. Sub-goal: survive the
  acceleration (shorter windows, subtler density, void decoys) without panic-tagging structure.
- **T — Tasks (the play to-do list):** read the galaxy density inside the scope · tag VOID for emptiness,
  FILAMENT for a thread, CLUSTER for a knot · beat the depleting urgency arc for a bigger speed bonus ·
  chain correct tags to climb the streak multiplier · resist over-tagging — most patches are void.
- **A — Automations (firing in the background):** the host-owned intro / countdown / score / timer /
  results clock (game begins in-trial immediately on `isRunning`) · one `Ticker` driving the difficulty
  ramp, the scope sweep, the urgency arc, and `_Particle` bursts · void-weighted region generation that
  thins clusters and seeds void decoys as difficulty climbs · the correct/wrong flash + reveal that
  auto-advances the sweep.
- **T — Testing (experimental / in-flight):** `humanMax` and `starThresholds` are first-pass and need a
  playtest re-tune · candidate ambition: an *adaptive* void share that ratchets up if the player keeps
  mis-tagging emptiness as structure, pushing the lesson harder than the pure time ramp does.
- **U — UX:** single CustomPainter survey field under a RepaintBoundary · violet scope reticle with
  crosshairs and a depleting decision arc · galaxy patches fade in as the scope arrives · three fixed
  classify buttons that light green (correct) / red (mis-pick) on reveal · a floating speed/streak banner
  · calm ambient field before the round starts.
- **H — Heuristics (how you actually win):** default to VOID — it's the most common and the fastest tag ·
  only commit to CLUSTER when you see a true packed knot, FILAMENT when dots line up as a thread · go fast
  while the streak multiplier is hot, but don't gamble structure tags on faint void decoys · a reset
  streak costs far more than one cautiously-skipped fast bonus.
- **S — Systems (what makes the world feel alive):** the scope physically *sweeps* the sky and the
  galaxies it frames teach the cosmic web — clusters (knots) linked by filaments (threads) around voids
  (emptiness) — so the scoring itself encodes the headline fact that the universe is mostly empty;
  ambient violet glow, a static cosmic-web backdrop, and spark bursts make the survey read as a living
  slice of large-scale structure.
