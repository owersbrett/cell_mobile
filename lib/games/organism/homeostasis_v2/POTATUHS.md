# Homeostasis v2 — Potatuhs notes

Part of **cell_mobile** (Explore The Cell), the GAMES-rubric launch artifact for
the Hot Potato Games summer vertical. Built in the **UX Refinement Pass** — a
sharper alternative to `homeostasis` that coexists for Brett to judge.

- **GAMES status:** G (game widget) · A (AGENT.md) · M (GAME.md) ·
  E (EDUCATION.md) · S (host-driven session re-entry). Built complete.
- **Scale:** `BioScale.organism` — the body as one balanced system, a level up
  from the cell/organ games.
- **Verb:** MULTI-BALANCE. Keep several negative-feedback loops in their bands at
  once — the organism-scale escalation.
- **Why v2:** the teardown flagged a four-gauge cockpit that overloaded cold-start
  and read as an opaque dashboard to spectators. v2 stages the gauges in one at a
  time and drives a whole-screen health vignette + vital-sign pulse off the all-in
  state, so player and onlooker read the standing instantly. Over-correction now
  costs (whiplash), making the negative-feedback lesson load-bearing.
- **Voice:** calm-control HUD; teal "balance" accent. The body quietly defending
  its set points — until it isn't, and the whole screen goes red. "Don't worry
  about it." Butter would approve (right up to CRITICAL).
- **Module discipline:** self-contained per EXTRACTION_RECIPE. Imports only
  `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, Flutter. Touches no other
  game, registry, catalog, or host.
- **Perf:** one ticker → one CustomPainter; flat per-frame work, geometry shared
  between paint and hit-test.
