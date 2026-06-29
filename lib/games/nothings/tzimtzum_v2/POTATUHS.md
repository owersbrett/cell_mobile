# POTATUHS — Tzimtzum v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Tzimtzum v2 — the UX-pass alternative to the Nothings-scale constant-rate game.
  Self-contained module (`lib/games/nothings/tzimtzum_v2/`); promoted to the registry + MiniGameHost,
  shipping **alongside** the original `tzimtzum` for A/B comparison. Shares the Nothings scale with Big
  Bang and Bit Memory. Its claim to fame: the catalog's **constant-rate "trace the withdrawal" verb**, now
  driven by a **single pointer** (mouse-playable) with an **accelerating** arc.
- **O — Objectives:** bank the most space before the ~50s clock ends. Sub-goals: keep your light edge
  parked **on the guide ring**, trace each withdrawal all the way to the center, and chain **clean**
  withdrawals into a streak — including the faster, tighter late vessels and the flagged FINAL WITHDRAWAL.
- **T — Tasks (the play to-do list):** read the `WITHDRAW` callout · press and drag the light's edge inward
  · **watch the guide ring, not your hand** and keep your edge on it · hold that exact pace as the ring
  contracts to the center · let it bloom · do it again, faster.
- **T — Tasks → Automations (firing in the background):** the per-tick alignment integrator
  (`∫ alignment dt`) · the constant-rate guide-ring driver · the accelerating duration/tightening-tolerance
  ramp keyed to vessel index · the bloom resolver (verdict + burst + `+points` pop) · the FINAL-WITHDRAWAL
  flag from `session.remaining` · auto-start of the first vessel when the host enters play.
- **T — Testing (experimental / in-flight):** haptics/sound and inflow motes live in AGENT.md as
  non-blocking ideas; `humanMax`/`starThresholds` are first-pass and re-tuned by playtest. Hard invariants
  under test by playthrough: single-pointer-only input, symmetric too-fast/too-timid penalty, no
  teleport-to-guide cheese, an accelerating (never decelerating) arc, and one-Ticker/one-Painter perf.
- **U — UX:** one clean canvas — a field of light with an edge you drag inward to open a dark void, a grab
  knob as the affordance · a single dashed **guide ring** that contracts at the ideal rate and glows green
  on contact, with a soft tolerance halo (no gauges, no meters) · a public **SPACE CREATED** fill bar for
  pass-and-play spectacle · a brief PERFECT/STEADY/TOO FAST/TOO TIMID/CREATION bloom with a `+points` pop ·
  a calm ready state before the host's countdown.
- **H — Heuristics (how you actually win):** **smoother than instinct** — the ring rewards a glide, not a
  snap · never lunge for the center, the *pace* is scored, not the finish · keep your eyes on the ring and
  let your hand follow · chain clean traces for the streak award · spend extra care on the fast, narrow
  late vessels (they are the climax and the tightest band).
- **S — Systems (what makes the world feel alive):** the **withdrawal model** — light retreats to open a
  measured void, dramatizing tzimtzum as you play · the **constant-rate alignment engine** that makes
  *steadiness* the currency · the **accelerating ramp** (faster vessels, tighter band) that turns a
  50-second run into a rising test of restraint with a FINAL-WITHDRAWAL climax · the capped per-vessel
  economy and streak award that reward repeated, controlled contraction over lucky one-offs.
