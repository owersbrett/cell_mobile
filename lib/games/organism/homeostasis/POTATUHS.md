# Homeostasis — Potatuhs notes

Part of **cell_mobile** (Explore The Cell), the GAMES-rubric launch artifact for
the Hot Potato Games summer vertical.

- **GAMES status:** G (game widget) · A (AGENT.md) · M (GAME.md) ·
  E (EDUCATION.md) · S (host-driven session re-entry). Built complete.
- **Scale:** `BioScale.organism` — the body as one balanced system, a level up
  from the cell/organ games.
- **Verb:** MULTI-BALANCE. Where `accelerator.dart` keeps one needle in one band,
  Homeostasis keeps several at once — the organism-scale escalation.
- **Voice:** calm-control HUD; teal "balance" accent. The body quietly defending
  its set points — "Don't worry about it." Butter would approve.
- **Module discipline:** self-contained per EXTRACTION_RECIPE. Imports only
  `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, Flutter. Touches no other
  game, registry, catalog, or host.
- **Perf:** one Ticker → one CustomPainter; flat per-frame work.
