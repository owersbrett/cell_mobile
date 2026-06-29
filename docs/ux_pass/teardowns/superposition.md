# superposition — UX Teardown
scale: multiverseAll · duration: 50s · scoreUnit: collapses
## Scores (1–5)  → TOTAL: 24/35
- Instant legibility: 3 — The probability bar with a "MEASURE NEAR 100%" label + a sweet-spot zone and a live "P(target) NN%" readout makes the goal legible (wait for high, tap). The Bloch sphere, ghost-trail vector and equator ellipse are atmospheric but abstract; a first-timer reads the *bar*, not the sphere.
- Affordance clarity: 4 — "Tap anywhere = MEASURE" (`onTapDown:_measure`), bottom prompt pulses "TAP TO MEASURE". One gesture, one verb, unmistakable.
- Juice & feedback: 4 — Collapse ring expanding from center, state vector snapping crisp to the measured pole, `FxBurst` per qubit, good/bad full-screen flash, `FxPop` "+pts"/"WRONG STATE". Rich and on-budget.
- Fair/readable competition: 3 — Outcome is genuinely random, weighted by P (`_rng.nextDouble() < pUp`). Educationally perfect, but it means a player who measures at 95% still loses ~1 in 20 — luck rides on top of skill, which dilutes fair head-to-head comparison in pass-and-play. Score itself reads clearly.
- Skill depth: 3 — Single qubit is pure timing against an accelerating `_omega` (1.55→4.6). The level-4 second qubit at phase ratio 0.86 (`_phase[1]` advances at 0.86×) creates a real *coincidence-timing* skill — waiting for both probability waves high at once, with joint payoff multiplying. That two-oscillator window is the genuine ceiling; the variance caps how much mastery feels rewarded.
- Pace & climax: 3 — Accelerates per level and the `_kCollapseHold = 0.62s` between collapses keeps it moving. The rare aligned two-qubit window is a nice pressure spike, but the 50s arc doesn't build to a defined finish.
- Polish: 4 — The Bloch sphere, fuzzy probability cloud at the vector tip, ghost trail and pole glow are a polished, distinctive look; atmosphere motes tie it to the multiverse set.
## Top 2–3 UX failures (cite the mechanic)
1. **Variance fights mastery.** The honest probabilistic collapse (`up = _rng.nextDouble() < pUp`) is correct physics but means perfect timing can still score WRONG STATE; players feel cheated and head-to-head results carry luck.
2. **The sphere doesn't carry the read; the bar does.** All the timing information a player actually uses is in `_paintProbabilityBar`; the elaborate Bloch sphere (`_paintQubit` ghost trail, equator, poles) is mostly decoration, so the most-painted element is the least functional.
3. **No finish spike.** Difficulty rises smoothly via `_level`, but nothing escalates in the final seconds, so the 50s ends rather than climaxes.
## Redesign brief — what superposition_v2 MUST change
- **Tame the luck without losing the lesson**: e.g. measuring near 100% should *guarantee* the favorable outcome while the *score* scales with the probability you dared to wait for — keep the gamble teaching ("measure at 50/50 = coin flip") for risk-takers, but stop punishing perfect timing with a bad RNG roll.
- **Make the sphere functional**, or shrink it: bind a readable game signal to the sphere itself (the vector tip *is* the thing you time) so legibility and decoration are the same element.
- Add a **two-qubit (or three-qubit) climax** in the last 10s where aligned windows are rare and the joint multiplier is huge, giving the arc a peak.
- Consider letting the player **choose the measurement moment under a tightening clock** so timing pressure, not RNG, owns the drama.
## Keep (education + what works)
- The collapse mechanic teaches the real thing: superposition oscillating P↑ = ½+½·sin(phase), measurement collapsing to a definite weighted state, and joint outcomes *multiplying* amplitudes (`joint *= ...`) at two qubits. That is the lesson made playable — keep it.
- Keep the probability bar with sweet-spot and live P(target) — it's the clearest UX element.
- Keep the collapse ring + vector-snap feedback; it makes an abstract event feel physical.
