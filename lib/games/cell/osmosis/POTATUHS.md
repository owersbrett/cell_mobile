# POTATUHS — Osmosis

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Osmosis — the cell-scale homeostasis game. Game id `osmosis` on `BioScale.cell`
  (`OsmosisGame`); a membrane-transport / water-balance game where the player titrates the solution
  to hold a single cell at isotonic turgor.

- **O — Objectives:** post the highest score in the 60 s session by keeping the cell **inside the
  safe size band** (`+6/s`) and **recovering it** when it drifts out (`+35`), while the environment
  swings harder and faster the longer you survive.

- **T — Tasks (the play to-do list):** read the top tonicity needle · drag the whole-screen slider
  toward WATER (left) to swell or SOLUTE (right) to shrink · null the flux at isotonic to freeze
  volume · over-correct briefly to steer the cell back to centre · avoid the lyse (top) and crenate
  (bottom) zones on the cell-size gauge.

- **A — Automations (firing in the background):** the environment **drift** that re-rolls a random
  target tonicity and eases toward it · the **osmotic flux integrator** (`dV/dt = −0.20 × T`) ·
  the **progress ramp** widening the drift range `0.35→0.90` and speeding re-rolls `2.4s→0.7s` ·
  the **pump auto-return** to isotonic when you let go · recovery detection and fail-and-recover
  (lyse/crenate reset to healthy turgor).

- **T — Testing (experimental / in-flight):** star thresholds `[220,450,700]` / `humanMax 700` are
  a **first estimate** pending real playtests · drop-and-resume of `_volume`/`_drift`/`_inject` is
  **not persisted** (re-inits on mount) · the fail-event reset volume (0.50) may want tuning so a
  burst feels punishing without being a death spiral.

- **U — UX:** one-finger control — the entire screen is a horizontal slider; tap to jump, drag to
  fine-tune, release to neutral · top tonicity meter as the live read-out · right vertical cell-size
  gauge with green safe band and red danger zones · the cell visibly swells (taut/red) or crenates
  (spiky) · flux arrows show water direction · calm ready state before the host starts the clock.

- **H — Heuristics (how you actually win):** centre the needle FIRST to stop the bleed, THEN
  over-correct to recover · small constant nudges beat big slams (you'll overshoot into the danger
  zone) · in the final third the swings come fast — anticipate the drift, don't chase it · a clean
  run parked near isotonic banks a long healthy streak plus steady drip — that's the 3-star line.

- **S — Systems (what makes the cell feel alive):** passive osmosis the player can never directly
  fight — only the solute balance outside is a lever · a membrane that strains, reddens, and buckles
  as a readable consequence · an environment that escalates from a gentle wander into a lurching
  tide · turgor as a narrow homeostatic window, the same razor's edge every real cell rides.
