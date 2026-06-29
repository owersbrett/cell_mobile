# POTATUHS — Tzimtzum

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Tzimtzum — the Nothings-scale constant-rate gesture game. Self-contained module
  (`lib/games/nothings/tzimtzum/`); promoted to the registry + MiniGameHost. Shares the Nothings scale
  with Big Bang and Bit Memory (a scale may host more than one game). Its claim to fame: the catalog's
  **only "hold a constant rate" verb** — a two-finger pinch/stretch scored on steadiness, not taps.
- **O — Objectives:** bank the most points before the ~45s clock ends. Sub-goals: keep the rate marker
  parked in the ideal band, complete each hold for its full duration, and chain **clean** holds into a
  streak — including the longer, tighter late-round prompts that pay the most.
- **T — Tasks (the play to-do list):** read the prompt (PINCH vs STRETCH, the duration) · plant two
  fingers · start a smooth contraction/expansion · **watch the gauge, not your fingers** and glide the
  marker into the green band · hold that exact rate until the progress arc closes · repeat the opposite
  direction.
- **T — Tasks → Automations (firing in the background):** the per-tick steadiness integrator
  (`∫ tickQuality dt`) · the alternating pinch/stretch prompt generator with its duration/tolerance ramp ·
  the hold-completion + wall-clock-grace resolver · the result flash → next-prompt advance · auto-start of
  the first prompt when the host enters play.
- **T — Testing (experimental / in-flight):** haptics/sound and rim-inflow particles live in AGENT.md as
  non-blocking ideas; `humanMax`/`starThresholds` are first-pass and re-tuned by playtest. Hard invariants
  under test by playthrough: two-finger-only input, symmetric too-fast/too-slow penalty, direction
  gating, and one-Ticker/one-Painter performance.
- **U — UX:** one clean canvas — a field of light with a void that withdraws (pinch) or floods back
  (stretch) following your fingers, a glowing rim at the boundary, a hold-progress arc around it · a live
  **rate gauge** with the ideal band highlighted and a marker that turns red on wrong-direction motion ·
  a **steadiness meter** (red→green) · a brief PERFECT/STEADY/TOO FAST/TOO SLOW/INCOMPLETE flash with a
  `+points` pop · a calm ready state before the host's countdown.
- **H — Heuristics (how you actually win):** **slower and smoother than instinct** — the gauge rewards a
  glide, not a snap · never "finish early," the rate is scored, not the finish · keep your eyes on the
  band and let your hands follow · chain clean holds for the streak award · spend extra care on the long
  late prompts (they pay the most and the band is narrowest).
- **S — Systems (what makes the world feel alive):** the **withdrawal model** — light retreats to open a
  measured void, dramatizing tzimtzum as you play · the **constant-rate scoring engine** that makes
  *steadiness* the currency (a verb unique in the catalog) · the **difficulty ramp** (longer holds,
  tighter band) that turns a 45-second run into a rising test of restraint · the streak economy that
  rewards repeated, controlled contraction over lucky one-offs.
