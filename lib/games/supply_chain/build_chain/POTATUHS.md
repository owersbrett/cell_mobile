# POTATUHS — Build the Chain

> The POTATUHS lens applied to one game: every game is itself a **Project** with
> Objectives, Tasks, Automations, Testing, UX, Heuristics, and Systems. One profile per
> game (template instance).

- **P — Project:** Build the Chain — the supply-chain-scale **structure & vocabulary
  primer**. Shipped build in `lib/games/supply_chain/build_chain/build_chain_game.dart`
  (`BuildChainGame`). Sister game to Delivery on `BioScale.supplyChain`: Delivery teaches
  *routing* (the shortest path through stops); Build the Chain teaches *the chain itself*
  (which named stages, in what order).

- **O — Objectives:** assemble the most potato supply chains in 60 s. Score on three
  levers: **correct placement** (each stage dropped in its right slot), **clean assembly**
  (lock the whole chain in order for a completion + speed bonus), and **flow upkeep**
  (deliver potatoes and clear stalls during the flow phase).

- **T — Tasks (the play to-do list):** drag each shuffled stage tile into its sequential
  slot (upstream → downstream) · read the role card to learn what each stage does · rear-
  range when an arrow goes red (that's where the chain snaps) · lock the chain in order ·
  during flow, tap any stalled stage to keep goods moving · take the next, longer/variant
  chain.

- **A — Automations (firing in the background):** `_composeChain` generates each round's
  correct order (rank-sorted subset, growing with level, with an export-branch variant) ·
  per-placement correctness check feeding the colour-coded arrows · the flow simulation
  (single potato on a belt, probabilistic stalls, deliver-goal counter) · streak tracking
  across placements and clean chains · `MiniGameHost` host-owned timer, 3-2-1 countdown,
  score HUD, results and wind-down.

- **T — Testing (experimental / in-flight):** the shipped build is the **linear-chain**
  version. Designed-but-not-built: a true **fork** (Process → Packaging → {Store, Export}
  on a branching belt), **multiple potatoes** on the line at once, and a visible
  **upstream order/money counter-flow** to dramatize the "three flows" lesson. See
  AGENT.md TODOs.

- **U — UX:** a row of numbered slots up top with a soft conveyor belt and directional
  arrows; a tray of draggable emoji-iconed stage tiles below; a transient role card that
  names each stage's job on tap/placement; supply-chain orange accent with teal "goods
  flow" / red "chain break" signalling. Canvas-drawn, single ticker, no raster assets.

- **H — Heuristics (how you actually win):** learn the **rank order** of the stages (raw
  → make → store → move → sell) and place from the outside in (Farm first, Store/Export
  last) · place **fast** to bank the speed bonus and grow the streak · watch the arrows —
  a red one tells you exactly which two stages to swap · in flow, prioritize the **TAP!**
  stage instantly, because a missed stall kills the clean-line bonus.

- **S — Systems (what makes the world feel alive):** the escalating chain that grows a
  stage per level and forks to export branches · the goods-flow animation that rewards a
  correctly-ordered line by literally running potatoes through it · the bottleneck/stall
  pressure that turns a static ordering puzzle into a living line you have to keep moving
  · the potato supply chain as the concrete, edible model of every real-world supply chain.
