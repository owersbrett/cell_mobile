# POTATUHS — Standard Model

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Standard Model — the particles-scale **sort/place** game. Registry game on
  `BioScale.particles` (`StandardModelGame`, `lib/games/particles/standard_model/standard_model_game.dart`).
  Particles stream down; you drag each into its family bin (QUARKS / LEPTONS / BOSONS). Deliberately
  distinct from the scale's timing games Collider & Accelerator — this one tests classification.

- **O — Objectives:** correctly sort the most particles in the ~50 s timed run. Sub-goals: build a
  streak for the multiplier; catch particles high in the field for the speed bonus; survive the tell
  fade-out at high tiers, where only the symbol remains.

- **T — Tasks (the play to-do list):** watch particles drift down · read the tells (charge badge,
  colour rim, mass/size, symbol) · drag each into QUARKS / LEPTONS / BOSONS · don't let particles
  sink past the detector line · chase the streak, avoid fizzles.

- **A — Automations (firing in the background):** the spawn timer feeding the stream · per-frame fall
  + miss detection · difficulty climbing on `(sorted ÷ 4) + (elapsed ÷ 14)` and driving spawn rate,
  fall speed, concurrency, tricky-particle bias and tell fade · burst + score-pop fx · the host
  clock / countdown / results and AI opponents from `MiniGameHost`.

- **T — Testing (experimental / in-flight):** core loop is stable; `flutter analyze` clean. Open
  design question: an optional high-tier sub-sort by generation (would need a contextual fourth bin —
  design before building). Possible polish: persist best score / streak.

- **U — UX:** a full-screen drag field over an atmospheric particle background · orbs carrying a
  symbol glyph, a charge badge, an animated colour-charge rim, and mass-scaled size · three glowing
  family bins that light on hover · name + classification flash on a correct drop · red fizzle on a
  wrong one. Canvas-drawn only — no raster assets. Calm "Drag each particle to its family" hint in
  the ready state.

- **H — Heuristics (how you actually win):** grab particles high so the speed bonus lands · never
  panic-drop into a bin you're unsure of — a fizzle resets your streak, a miss only costs the catch ·
  learn the symbols early while the colours still help, because the tells vanish later · remember the
  hard pairs: neutrinos are leptons, the gluon is a boson, both read charge 0.

- **S — Systems (what makes the world feel alive):** the WOW teaching layer — the difficulty ramp is
  literally the **removal of hints**, so the game gets harder by demanding real knowledge, not faster
  reflexes · the three-family map of all known matter as the board itself · the classify flash that
  names and contextualizes every particle you place (generation, charge, force role).
