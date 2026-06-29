# Food Web — POTATUHS

Part of **Explore The Cell** (cell_mobile) → the GAMES rubric in the flesh.
Scale: `BioScale.ecosystem`. One self-contained module under
`lib/games/ecosystem/food_web/`.

## GAMES status
- **G — Game:** `food_web_game.dart` — playable drag-to-wire food web. ✅
- **A — Agent:** `AGENT.md`. ✅
- **M — Manual:** `GAME.md`. ✅
- **E — Education:** `EDUCATION.md`. ✅
- **S — Session:** host-owned clock; `_onSession` regenerates a clean board on a
  fresh run, so a session closes and a new one re-enters. ✅

## Brand fit
The verb is CONNECT/WIRE at the ecosystem scale — energy flows up the pyramid,
the same "wire the system, watch it light up" feel as Delivery (supply chain)
and the synapse games, but teaching ecology. Uses the shared Potatuhs render
kit (`fx.dart`, `theme/potatuhs.dart`): atmosphere background, glowing orbs,
travelling energy pulses, FxBurst/FxPop juice. Accent green keeps it legibly
"ecosystem".

## Dependency rule
Imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and Flutter.
No cross-game imports. One Ticker → one CustomPainter; structural-only setState.
