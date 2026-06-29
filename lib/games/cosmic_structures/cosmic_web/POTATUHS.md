# POTATUHS — Cosmic Web

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Cosmic Web ("Trace the Filaments") — the cosmicStructures-scale connect-the-nodes
  game. Shipped build in `lib/games/cosmic_structures/cosmic_web/cosmic_web_game.dart`
  (`CosmicWebGame`). The proper, on-theme successor to the deleted **Neuron Connect** — same
  connect-the-nodes feel, correctly themed to the large-scale structure of the universe.
- **O — Objectives:** bank the most points by lighting the dark-matter filaments that link galaxy
  superclusters, web after web. Two levers: **accuracy** (read where the filaments are; never cross a
  void) and **speed** (a fast trace banks a completion bonus and keeps a chain combo alive). Each
  completed web is replaced by a **denser** one.
- **T — Tasks (the play to-do list):** drag cluster → cluster along a faint filament · light every
  filament in the web · avoid linking across the voids (chain breaks) · complete the web fast for the
  speed bonus · take the next, larger, fainter web.
- **A — Automations (firing in the background):** the **Euclidean MST + loop-edge** generator that
  shapes each web's filament scaffold · auto-detection that all filaments are lit (instant complete) ·
  the rubber-band validity preview (gold vs white) · the complete-flash / void-flash feedback decay ·
  chain-combo tracking across links · MiniGameHost host-owned timer, 3-2-1 countdown, results and
  wind-down.
- **T — Testing (experimental / in-flight):** shipped build is the pure trace-the-web version. Future
  passes (see AGENT.md): make void blobs literally *block* a link that passes through them; a brief
  screen-shake / "void map" reveal on a miss; partial-web carry scoring.
- **U — UX:** a normalised 0..1 deep-space field with `GameFx.atmosphere` drifting motes · dark-matter
  violet accent with warm-gold ignited filaments · supercluster orbs (`GameFx.orb`) that pulse while
  threads are dark and turn gold when fully traced · a filament-progress pill and chain badge · a
  void-miss cue line. Canvas-drawn, no raster assets.
- **H — Heuristics (how you actually win):** read the **geometry** — filaments hug nearest neighbours
  and wrap the dark voids, so trace short adjacent hops first · watch the **rubber-band colour** (gold
  = real filament, white = void) to never break your chain · go **fast** to bank the speed bonus and
  compound the chain · on a denser, fainter web, slow down just enough to read the threads before they
  cost you the combo.
- **S — Systems (what makes the world feel alive):** the escalating web that gains clusters, filaments,
  and voids — and loses thread brightness — each completion, a cosmos that always wants you to look
  closer · the structure-formation theme (an invisible dark-matter scaffold that lights up as matter
  falls in) · the cosmic-web framing — superclusters, filaments, and the vast voids between them, the
  largest structures in existence rendered as a thing you trace with your finger.
