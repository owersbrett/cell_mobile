# predator_prey — UX Teardown
scale: ecosystem · duration: 50s · scoreUnit: balance

## Scores (1–5)  → TOTAL: 23/35
- Instant legibility: 2 — The play surface is a scrolling two-line Lotka–Volterra GRAPH with a K line, an extinction floor, and HARES/LYNX counters (`_paintGraph`). Graphs demand interpretation; the ready screen is a three-line paragraph of text (`_readyHint`). A new player cannot grasp the goal in 3s without reading — the hardest onboarding in the cohort.
- Affordance clarity: 3 — Cull/release ± keys per species and a PROTECT A PATCH button are clear *as buttons*, but what each does to the curves is abstract: tapping +10 hares barely moves a line that the ODE is already pushing around. The cause→effect of an input is hard to feel.
- Juice & feedback: 3 — Restrained by the form: pops, a flash callout, shock banners ("DROUGHT — hares die off"), glow-pass lines, refuge tint. Competent but a graph can't pop like an arcade field; feedback is mostly textual.
- Fair/readable competition: 2 — `balance` (survival-time-in-band) is comparable as a number, but a live line graph is near-unreadable as a contest for a pass-and-play onlooker — you cannot glance and tell who's winning. Abstract and spectator-hostile.
- Skill depth: 5 — The standout strength. Steering coupled ODEs through boom-bust, anticipating crashes before they happen, timing the refuge, and juggling a third species (hawks at 55%) is a deep, genuinely masterable system with a high ceiling. Excellent.
- Pace & climax: 4 — Real acceleration: time-scale ramps 1.0×→2.3×, predation `βEff` +50%, shock cadence 13s→7s, and the hawks introduce a whole new tier late. The system gets visibly wilder toward the buzzer.
- Polish: 4 — Sophisticated and clean: glow+core line rendering, labelled K and extinction lines, phase-guarded widget rebuilds (no per-frame setState over the button tree), forgiving reseed-on-extinction. The most technically accomplished build here.

## Top 2–3 UX failures (cite the mechanic)
1. **Graph-as-gameplay is illegible at a glance.** The core surface is a data visualisation; instant legibility (2) and spectator competition (2) both crater because reading two oscillating lines against an equilibrium band is an *acquired* skill, not a 3s grasp. The "healthy band" is even computed but **not drawn** (GAME.md TODO #1).
2. **Inputs feel weak vs the sim.** A `+10 hares` nudge is small against an ODE already swinging the population; players can't feel that their tap mattered, so agency is low despite deep underlying control.
3. **Text-heavy onboarding.** The only explanation is a paragraph on the ready screen; nothing teaches the boom-bust loop *by doing* in the first few seconds.

## Redesign brief — what predator_prey_v2 MUST change
- **Make the equilibrium readable**: draw the "healthy band" zone the code already computes (`_preyEq`/`_predEq`) as a shaded target window on the graph, and add a single dominant "ecosystem health" signal (a living scene or a balance dial) so player AND spectator can read winning/losing without parsing curves.
- **Give inputs weight**: bigger, more visible consequences per nudge (a visible shove on the line + a ripple), or reframe levers as direct gestures on the graph, so agency is felt.
- **Teach by doing**: an opening guided beat — "hares booming → tap to cull before the crash" — that walks the boom-bust loop in the first seconds instead of a text wall.
- **Spectator framing for party play**: surface the balance-streak as a screen-level state so the contest is glanceable. Keep the deep ODE system underneath — it's the asset.

## Keep (education + what works)
- The sim IS the Lotka–Volterra equations, with the live phase label naming each quadrant (BOTH RISING / PREY CRASHING / PREDATORS STARVING / PREY RECOVERING). This is a genuinely excellent teach — preserve the model, the K line, the extinction floor, and the third-species cascade.
- The forgiving reseed-on-extinction (penalty, not game-over) keeps a session always running the full clock — good for the S criterion.
- Deep, high-ceiling skill and honest acceleration — the redesign must protect both.
