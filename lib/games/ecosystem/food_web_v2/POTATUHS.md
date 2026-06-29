# Food Web v2 — POTATUHS

Part of **Explore The Cell** (cell_mobile) → the GAMES rubric in the flesh.
Scale: `BioScale.ecosystem`. One self-contained module under
`lib/games/ecosystem/food_web_v2/`. UX-refinement-pass rebuild of `food_web`.

## GAMES status
- **G — Game:** `food_web_v2_game.dart` — playable drag-to-route living pyramid. ✅
- **A — Agent:** `AGENT.md`. ✅
- **M — Manual:** `GAME.md`. ✅
- **E — Education:** `EDUCATION.md`. ✅
- **S — Session:** host-owned clock; `_resetRun` rebuilds a clean pyramid on a
  fresh run, so a session closes and a new one re-enters. ✅

## What changed from v1 (teardown)
v1 scored 25/35 — flagged for discrete-puzzle pacing with an inter-web pause,
recall-gated random-web competition, and silent near-miss drags. v2 keeps the
exact ecology lesson but turns it into a **continuous** living pyramid you keep
fed: meters always drain, you always route, a final-10s surge accelerates into
the buzzer, the board is fixed/deterministic (fair contest), valid targets are
shown on grab (no memory gate), release snaps with always-on feedback, and full
producer→apex chains are the headline bonus.

## Brand fit
The verb is ROUTE/FEED at the ecosystem scale — energy climbing the pyramid, the
same "keep the system lit" feel as Delivery (supply chain) and the synapse
games, teaching ecology. Uses the shared Potatuhs render kit (`fx.dart`,
`theme/potatuhs.dart`): atmosphere background, glowing orbs, travelling energy
packets, FxBurst/FxPop juice, a glanceable PYRAMID HEALTH dial. Accent green
keeps it legibly "ecosystem".

## Dependency rule
Imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and Flutter.
No cross-game imports. One Ticker → one CustomPainter; field-mutation rendering.
