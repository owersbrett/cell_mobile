# POTATUHS — Osmosis v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Osmosis v2 — the UX-refined cell-scale homeostasis game. Game id `osmosis_v2`
  on `BioScale.cell` (`OsmosisV2Game`). A membrane-transport / water-balance game re-skinned as a
  **potato cell** and rebuilt to the teardown brief so the control is obvious and cause→effect is
  immediate.

- **O — Objectives:** post the highest score in the 60 s session by holding the balance knob in the
  green **isotonic** zone (cell stays at firm turgor → score) against an escalating drift, banking a
  capped combo multiplier and surviving the final-surge ×2 climax.

- **T — Tasks (the play to-do list):** grab the big BALANCE knob · drag it into the green centre ·
  keep dragging to counter the drift that shoves it off · null the flux at isotonic to freeze
  volume · recover the cell after it drifts out (+15) · ride the FINAL SURGE for double points.

- **A — Automations (firing in the background):** the **drift force** that re-rolls and shoves the
  knob (range `0.40→1.10`/s, re-roll `2.2s→0.7s`) · the **immediate osmotic flux**
  (`dV/dt = −0.55 × knob`) · the **eased knob drag** (glides to finger, no edge-slam) · the **capped
  combo multiplier** (`1×→3×`) · **fail-and-recover** (lyse/crenate reset to firm turgor) · the
  **FINAL SURGE** escalation + end flourish.

- **T — Testing (experimental / in-flight):** star thresholds `[400,900,1500]` / `humanMax 1500`
  are a first estimate pending playtests · `_kFlux 0.55` immediacy vs `_kIsoTol 0.14` deadband want
  co-tuning so green is holdable but not trivial · drop-and-resume not persisted.

- **U — UX:** the affordance fix — an **explicit bottom BALANCE DECK** (fat track, green isotonic
  zone, big gripped knob, WATER/SALT labels, "DRAG TO BALANCE" header) replaces the original's
  invisible whole-screen slider · a first-run ghost hand demos the drag and fades on touch · ONE
  thing to track (the knob); the potato cell + fused green ring is the consequence read-out · capped
  ×N multiplier chip · alarm vignette + banner in the surge.

- **H — Heuristics (how you actually win):** small constant nudges beat big slams (the ease helps,
  but overshoot still kills) · centre the knob FIRST to stop the bleed, then recover the cell · in
  the final third the pushes come fast — anticipate the drift, don't chase it · a clean run parked
  green banks a long streak and a maxed ×3, and the surge ×2 is where leads are made.

- **S — Systems (what makes the cell feel alive):** passive osmosis the player can never directly
  fight — only the solute balance outside is a lever · a **potato** membrane that strains, pales,
  reddens and buckles as a readable consequence · an environment that escalates from a gentle wander
  into a lurching surge · turgor as a narrow homeostatic window, the razor's edge every real cell
  rides — a firm fry vs a limp one.
