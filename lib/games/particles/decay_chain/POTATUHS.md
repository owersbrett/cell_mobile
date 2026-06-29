# POTATUHS — Decay Chain

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Decay Chain — a particles-scale CATCH-THE-PRODUCTS game on `BioScale.particles`
  (`DecayChainGame`, `lib/games/particles/decay_chain/`). An unstable particle decays in a detector
  and you tap the real products before they escape.
- **O — Objectives:** post the highest particle-catch score in the ~50 s timed run. Sub-goals: land
  CLEAN decays (every real product, no impostor, no escape) to build a streak; trigger and harvest
  multi-step chains (`π⁻ → μ⁻ → e⁻`); refuse impostors that break conservation of charge.
- **T — Tasks (the play to-do list):** read the decay equation up top · watch the fuse arc wind down
  · when it bursts, tap each real product (charge-coloured orbs) before it leaves the detector ·
  DON'T tap the flickering impostor (−12) · chase clean decays for the streak bonus · catch unstable
  products (muon/pion) to spawn the chain.
- **A — Automations (firing in the background):** the central reactor reseeds on a cadence
  (`1.6 → 0.7 s`) · fuses count down and burst into product particles · products fly out and escape
  past the detector · batch bookkeeping awards CLEAN decays and resets streaks · caught unstable
  products schedule their own re-decay · the host clock / countdown / results / AI opponents from
  `MiniGameHost`.
- **T — Testing (experimental / in-flight):** `flutter analyze lib/games/particles/decay_chain/` =
  0 issues (verified). Open tuning: playtest `humanMax` / `starThresholds`; confirm chain depth never
  clutters the screen at peak difficulty.
- **U — UX:** a single full-screen tap surface over a rotating detector ring · a pulsing parent with
  a lime→red decay fuse · charge-coloured product orbs (blue −1 / orange +1 / grey 0) with symbols
  and motion trails · flickering warning ring on impostors · CLEAN/penalty screen flashes and score
  pops · a calm "REACTOR PRIMED" ready state. Canvas-drawn only — no raster assets.
- **H — Heuristics (how you actually win):** read the equation first, then the charges — the impostor
  is the orb that isn't in the equation · prioritise the fastest-escaping products · take chains: a
  caught muon pays again · one impostor wipes a streak, so when unsure, don't tap.
- **S — Systems (what makes the world feel alive):** the conservation-of-charge check is the engine —
  every decay balances and the impostor is the thing that doesn't · the multi-step chain
  (`π → μ → e`) mirrors real particle cascades · the difficulty ramp accelerates the same reading-
  charge-under-pressure loop instead of changing the game.
