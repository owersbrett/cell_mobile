# POTATUHS — Decay Chain v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Decay Chain v2 — a particles-scale CATCH-THE-PRODUCTS game on `BioScale.particles`
  (`DecayChainV2Game`, `lib/games/particles/decay_chain_v2/`). A UX-refinement-pass rebuild: an
  unstable particle decays in a detector and you tap the real products before they escape, refusing
  the ✗ impostor.
- **O — Objectives:** post the highest particle-catch score in the ~52 s timed run. Sub-goals: land
  CLEAN decays (every real product, no impostor, no escape) to build a streak; trigger and harvest
  multi-step chains (`π⁻ → μ⁻ → e⁻`); refuse impostors that break conservation of charge; ride the
  MELTDOWN combo multiplier in the climax.
- **T — Tasks (the play to-do list):** read the decay equation chips up top · watch the fuse arc wind
  down · when it bursts, tap each real product (charge-coloured, charge-badged orbs) before it leaves
  the detector · DON'T tap the segmented-red-ring ✗ impostor (−12) · chase clean decays for the
  streak bonus · catch unstable products (muon/pion) to spawn the chain · in MELTDOWN, keep the catch
  combo alive for the multiplier.
- **A — Automations (firing in the background):** the central reactor reseeds on a cadence
  (`1.6 → 0.75 s`, faster in meltdown) · fuses count down and burst into product particles · products
  fly out and escape past the detector · batch bookkeeping awards CLEAN decays and resets streaks ·
  caught unstable products schedule their own re-decay · the novice charge-aid fades on `_aid` · the
  meltdown window arms at `_prog ≥ 0.76` · the host clock / countdown / results / AI opponents from
  `MiniGameHost`.
- **T — Testing (experimental / in-flight):** `flutter analyze lib/games/particles/decay_chain_v2/` =
  0 issues (verified). Open tuning: playtest `humanMax` / `starThresholds`; confirm the meltdown
  combo multiplier stays fair (bounded ≤ ×2, no runaway); confirm chain depth never clutters the
  screen at peak difficulty.
- **U — UX:** a single full-screen tap surface over a rotating detector ring · a pulsing parent with
  a lime→red decay fuse · charge-coloured product orbs (blue −1 / orange +1 / grey 0) with symbols
  and big +/−/0 charge badges that fade · a bold segmented red ring + ✗ badge on impostors (readable
  under motion) · an equation HUD of charge-coloured chips that light when their product is live ·
  CLEAN/penalty screen flashes, score pops, big centred milestone flashes, and a pulsing red meltdown
  vignette + COMBO readout. Canvas-drawn only — no raster assets.
- **H — Heuristics (how you actually win):** read the equation first, then the charges — the impostor
  is the orb wearing the ✗ · prioritise the fastest-escaping products · take chains: a caught muon
  pays again · one impostor wipes a streak (and the combo), so when unsure, don't tap · in meltdown,
  protect the combo — a clean run of catches doubles your points.
- **S — Systems (what makes the world feel alive):** the conservation-of-charge check is the engine —
  every decay balances and the impostor is the thing that doesn't · the multi-step chain
  (`π → μ → e`) mirrors real particle cascades · the difficulty ramp + aid-fade accelerates the same
  reading-charge-under-pressure loop instead of changing the game · the MELTDOWN climax resolves the
  ramp into a read-from-across-the-room finish beat.
