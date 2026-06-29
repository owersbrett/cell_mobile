# POTATUHS — Standard Model v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Standard Model v2 — the UX-refinement-pass rebuild of the particles-scale
  **sort/classify** game (`StandardModelV2Game`,
  `lib/games/particles/standard_model_v2/standard_model_v2_game.dart`). Particles stream down; you
  classify each into its family bin (QUARKS / LEPTONS / BOSONS). Same lesson as v1; v2 unthrottles the
  verb and adds a finish.

- **O — Objectives:** correctly sort the most particles in the ~55 s timed run. Sub-goals: build a
  streak for the multiplier; arm a bin to one-tap a cluster; ride the BEAM BURST climax with the ×8
  multiplier; survive the tell fade-out where only the symbol remains.

- **T — Tasks (the play to-do list):** read the tells (charge badge, colour rim, mass/size, symbol) ·
  pick a verb — tap-then-bin, arm-and-fire, flick, or drag · don't let particles sink past the
  detector · chase the streak, avoid fizzles · in the last 10 s, clear as fast as the multiplier lets you.

- **T — Tasks become Automations (background):** the spawn timer feeding the stream · per-frame fall +
  miss detection · difficulty climbing on `(sorted ÷ 4) + (elapsed ÷ 14)` driving spawn rate, fall
  speed, concurrency, tricky-bias and tell fade · the fading legend · the climax detector on
  `session.remaining` · the milestone flash on every 10th sort · burst + score-pop fx · host
  clock / countdown / results and AI opponents.

- **T — Testing (experimental / in-flight):** core loop stable; `flutter analyze` clean. Open: tune
  `humanMax` / `starThresholds` by playtest now that the verb is faster; possible high-tier
  generation sub-sort (design first).

- **U — UX:** a full-screen field over an atmospheric particle background · orbs with symbol glyph,
  charge badge, animated colour-charge rim, mass-scaled size · three glowing family bins that light on
  hover, glow when ARMED, and pulse the correct answer on a wrong drop · a fading mini-legend that
  prints each family's members early · name + classification flash on a correct drop · BEAM BURST
  banner + screen-wide milestone flashes for the climax. Canvas-drawn only — no raster assets.

- **H — Heuristics (how you actually win):** arm a bin when a cluster of one family is on screen and
  tap them off in a burst · grab particles high for the speed bonus · never fire into a bin you're
  unsure of — a fizzle resets the streak that drives your multiplier · learn the symbols early while
  the legend and colours still help · remember the hard pairs: neutrinos are leptons, the gluon is a
  boson, both read charge 0.

- **S — Systems (what makes the world feel alive):** the WOW teaching layer is preserved — the
  difficulty ramp is the **removal of hints**, so the game gets harder by demanding real knowledge,
  not faster reflexes. v2 layers in a **skill-expressive verb** (arm-and-fire turns knowledge into
  throughput) and a **spectator-legible climax** (BEAM BURST + milestone flash), turning a steady
  sorter into a game with a finish line you can feel.
