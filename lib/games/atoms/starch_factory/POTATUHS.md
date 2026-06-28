# POTATUHS — Starch Factory

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Starch Factory — the atoms-scale conveyor-sorter set inside the amyloplast. Game
  id `starch_factory` on `BioScale.atoms`; the potato-flavoured *variety* game-2 of the Atoms scale.
- **O — Objectives:** survive endlessly by routing each coloured glucose/carbon molecule to its
  matching funnel, keeping the STARCH bar above zero. Sub-goal: build long combo chains for score.
- **T — Tasks (the play to-do list):** read each lead molecule's colour · tap a lane to select it ·
  tap a second lane to swap all in-flight molecules between the two · re-route mid-flight after every
  endpoint shuffle · feed correct routes to replenish starch and grow the combo multiplier.
- **A — Automations (firing in the background):** the never-stopping conveyor whose scroll speed
  ramps with elapsed time · the steady STARCH drain (rising over 90 s) · the lane-endpoint swap timer
  (10 s → 4.5 s floor) with its 1.5 s warning pulse · lane unlocks auto-firing at score 1000 (4th) and
  10000 (5th).
- **T — Testing (experimental / in-flight):** the optional **glucose-label upgrade** — rename each
  colour to `C₆H₁₂O₆` with a C-6 count badge to make the carbon-chain metaphor explicit (noted as a
  non-required variety-slot enhancement, not yet built).
- **U — UX:** `CustomPainter` hex molecules with letter labels (G/A/B/P/D) · larger glowing endpoint
  funnels trailing a chain of mini-hexes · top STARCH bar shading green→yellow→red · a centre swap
  countdown that pulses red in its last 25% · a translucent border on the selected lane.
- **H — Heuristics (how you actually win):** swap early so the leader still lands first · prioritise
  the lane about to resolve over distant ones · bank the <20% starch +10 bonus when desperate but
  don't gamble a wrong route (−7%) · keep a clean combo running — the `×(1+combo×0.15)` scaling pays.
- **S — Systems (what makes the world feel alive):** the relentless belt that never stops · endpoints
  that shuffle out from under you on a shrinking timer · the amyloplast theme where each correct route
  literally extends the starch polymer — the organelle that makes a potato a potato, mid-assembly.
