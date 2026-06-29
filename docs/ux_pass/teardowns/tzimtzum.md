# tzimtzum — UX Teardown
scale: nothings · duration: 45s · scoreUnit: space
## Scores (1–5)  → TOTAL: 16/35
- Instant legibility: 2 — The verb is "hold a STEADY, constant rate" — an abstract proprioceptive goal you cannot grasp in <3s. The prompt (`_paintPrompt`: "PINCH · hold 2.0s at a constant rate") plus a RATE gauge with an ideal band and a separate STEADINESS bar is a lot of instrumentation to parse before you understand the goal. The withdrawn-light void (`_paintVoid`) is gorgeous but communicates nothing about what to do.
- Affordance clarity: 1 — The whole game is a two-finger pinch/stretch on a blank canvas (`onScaleUpdate`, gated on `d.pointerCount >= 2`). There is no visible handle, ring, or grabbable target — the gesture is invisible. Critically, the deploy target is web (explore-the-cell.web.app); a two-finger pinch is essentially unperformable with a mouse, so the game is unplayable on the primary platform. Even on a phone, nothing on screen says "put two fingers here and squeeze."
- Juice & feedback: 3 — The single Ticker→`_TzimtzumPainter` is within budget and does give live feedback: the rate marker turns warn/good/accent, the hold-progress arc fills, the steadiness bar lerps warn→good, and a PERFECT/STEADY/TOO FAST flash resolves each prompt. Adequate but quiet — no impact, no spectacle.
- Fair/readable competition: 2 — In pass-and-play there is nothing to watch: a steadiness average and a private rate marker. `scoreUnit: 'space'` and the steady×completion formula (`_resolvePrompt`) produce a number with no legible drama. A two-finger gesture also kills hot-seat spectacle.
- Skill depth: 3 — Holding a genuinely constant rate is hard and has a real ceiling (`_steadiness = ∫ quality dt`, `_tol` tightens 1.0→0.5 per prompt). But it's a narrow, frustrating skill with little expressive range — you either hold steady or you don't.
- Pace & climax: 2 — Anti-climactic by construction: `_targetDur` ramps 2.0s→5.0s, so later prompts take LONGER while tolerance tightens. The arc gets slower and harder, not faster. `_kGrace` (3s) + `_kFlashTime` (1.1s) inject dead time. No accelerating finish.
- Polish: 3 — The void/chalal radial gradients and boundary rim are on-brand and lovely. But the gesture→void mapping spikes when pointer count changes (`_kDeltaClamp` band-aid in `_onScaleUpdate`), the direction-correct marker logic is subtle, and the web-unplayability is a fatal context gap.
## Top 2–3 UX failures (cite the mechanic)
1. Two-finger-only input (`onScaleUpdate` requires `pointerCount >= 2`) makes the game unplayable on the web deploy target and gives the player no visible thing to grab.
2. The goal "hold a constant rate" is abstract and instrument-heavy — the RATE gauge + STEADINESS meter + hold arc must all be read before the verb makes sense (no <3s read).
3. Difficulty ramps by LENGTHENING holds (`_targetDur` → 5s) and tightening `_tol`, so the 45s arc decelerates instead of climaxing.
## Redesign brief — what tzimtzum_v2 MUST change
- Replace (or alias) the two-finger gesture with a single-pointer drag-and-hold that works with a mouse: e.g. press and drag a visible "withdrawal handle" outward/inward at a target speed. Keep the constant-rate lesson; lose the pinch.
- Give the rate an unmistakable visual target — a moving "ghost pace car" / sweeping guide the player traces, so "steady = stay on the guide" is a <3s read with no gauge-reading.
- Re-shape the arc to accelerate: shorter holds that come faster, tolerance tightening as the climax, so 45s builds tension instead of sagging into 5s holds.
- Add a public, legible score readout for pass-and-play (a filling "space created" bar with a clear final number), and a snappy success burst so spectators feel the steady holds land.
## Keep (education + what works)
- The lesson is intact and beautiful: tzimtzum as measured self-contraction making space — too violent collapses, too timid opens nothing. Preserve the void-grows-as-light-withdraws visualization (`_paintVoid`) and the PINCH/STRETCH (contract/expand) framing.
- The completion×steadiness scoring honestly encodes "constant, restrained contraction" — keep that model; just make the input and pacing humane.
