# POTATUHS — Neuron Connect

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Neuron Connect — the cosmic-structures-scale circuit router. Self-contained module
  (`lib/games/cosmic_structures/neuron_connect/neuron_connect_game.dart`, `NeuronConnectGame`); on
  `BioScale.cosmicStructures`, host-driven.
- **O — Objectives:** post the highest score across levels by completing each circuit — route the signal
  source → target so the path lights up end-to-end and fires. Sub-goals: clear deeper, denser grids; at
  threshold levels, thread the signal through stacked 3D layers.
- **T — Tasks (the play to-do list):** flick each neuron to aim its gate (cardinal nearest the swipe) ·
  read "incomplete" vs "live" wires to see how close the circuit is · route around locked nodes and
  blockers · at deep levels switch the focused layer and send the signal through via / interlayer nodes ·
  fire when the path closes.
- **A — Automations (firing in the background):** the host-owned intro / countdown / results clock (game
  begins in-trial immediately) · the per-frame tick driving the signal sweep, `_JuiceParticle` bursts,
  and soma glow · BFS-guaranteed solvable level generation · the fire-signal + fact-flare payoff that
  auto-triggers on CIRCUIT COMPLETE.
- **T — Testing (experimental / in-flight):** phased build — (1) flick-to-aim + circuit framing, then
  (2) the 3D-layer system (isometric/parallax stacked grids, layer selector, signal dipping at vias) for
  deeper levels. The depth dimension and escalating interlayer dependencies are the in-flight ambition.
- **U — UX:** Canvas-only board · flick a neuron to point its gate (tactile, directional — replaces
  tap-to-cycle) · faint incomplete vs bright live wire states · active layer drawn bright, others dimmed,
  signal visibly dipping between layers · particle payoff + fact flares on completion.
- **H — Heuristics (how you actually win):** trace backward from the target to find the one needed gate
  orientation · solve locked-node constraints first since they can't move · on 3D levels, plan the
  interlayer hops before flicking — reaching some turnable nodes *requires* routing through another layer
  first · close the circuit before fiddling for style.
- **S — Systems (what makes the world feel alive):** the glowing neuron-network theming doubles as the
  **Cosmic Web** — filaments connecting nodes across voids — so fact flares teach large-scale structure
  while you play · the signal sweep, soma orbs, and depth-stacked layers make the board read as a living,
  three-dimensional universe.
