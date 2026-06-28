# POTATUHS — Molecule Mixer

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Molecule Mixer — the molecular-scale tap-to-assemble game. Registry module
  (`lib/games/arcade/molecule_mixer.dart`, `MoleculeMixerGame`); on `BioScale.molecular`, host-owned
  timer/results.
- **O — Objectives:** post the highest score in a timed attack — tap the right atoms to complete target
  molecules, each completion banking +4s. Sub-goals: respect backbone gating, avoid wrong taps, and ride
  the time bonus deep into the advanced targets.
- **T — Tasks (the play to-do list):** read the target panel (formula, name, slot indicators) · tap the
  correct drifting atoms (H, O, C, N, Cl) into the construction zone · place the **backbone hub first**
  (carbon/oxygen/nitrogen before peripherals) · complete the molecule for +30 and +4s · move to the next
  target before time runs out.
- **A — Automations (firing in the background):** the host-owned session timer · a pool of atom bubbles
  drifting and bouncing across the field · the continuous speed ramp (`_speedMul = 1.0 + progress × 0.7`,
  up to 70% faster) · the difficulty bias (after 18s elapsed or 3 completions, 65% toward advanced 4–5
  atom targets) · the **supply guarantee** auto-seeding enough atoms (plus 2 spares per element) so you
  never come up short · decoys scaling up over the round.
- **T — Testing (experimental / in-flight):** the **WOW flare** build — import shared
  `molecule_locations.dart`, advance the location-card index per completion, render a non-blocking two-line
  canvas card (`MOLECULE_LOCATIONS.md`). No confirmed bugs at writing; live list in `AGENT.md`.
- **U — UX:** Canvas-only — wobbling atom bubbles with 3D radial-gradient shading + glow halos, flying-atom
  arc on tap, bond draw-in animation (glow + white core line) · generous `_kHitR = 34` one-thumb hit
  radius · "BACKBONE FIRST" amber-pulse popup (no penalty), red shake on a wrong tap · celebration banner
  + dismissible WOW flare on completion.
- **H — Heuristics (how you actually win):** always tap the backbone/CORE atom first to skip the gating
  delay · never guess — a wrong tap is −10, completion is +30, so accuracy compounds · chase completions,
  not raw atom placements, because each one banks +4s to keep the round alive · learn which targets are
  diatomic/ungated (O₂, N₂, HCl, H₂O₂) so you tap them in any order fast.
- **S — Systems (what makes the world feel alive):** a drifting molecular soup, atoms wobbling and glowing
  with depth, makes the field feel like a living medium · the WOW flares ground every molecule in a real
  potato — CO₂ stitched into glucose by RuBisCO, O₂ burned by mitochondria into ATP, H₂O in every cell —
  so the chemistry you assemble is literally the molecules of your potato.
