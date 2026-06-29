# pattern_lock — UX Teardown
scale: somethings · duration: 50s · scoreUnit: patterns
## Scores (1–5)  → TOTAL: 26/35
- Instant legibility: 4 — Clean quiz frame: a sequence row of cells, a glowing "?" cell (`_qCell`), the prompt "What comes next?", and a 2×2 option grid. The family chip (ARITHMETIC / GEOMETRIC / SHAPE CYCLE…) labels the rule type. You grasp it in one look. Slight ding: the family chip arguably hands you too much, and the late odd-one-out mode swaps the interaction.
- Affordance clarity: 4 — Tap an option card (`_onOptionTap`). In odd-mode the sequence cells become tappable with "Tap the cell that breaks it" + a `touch_app` icon (`_buildOddHint`). The mode switch is signposted, though it's a different target than every prior round.
- Juice & feedback: 3 — Particle burst on correct, a gold burst on every streak-step (`_resolve`), green/red card borders, and a reveal card with the rule + a teach line. Adequate but mostly static-card UI — the only motion is the burst and the ambient `_BgPainter` orbs; it doesn't feel kinetic.
- Fair/readable competition: 4 — Speed bonus (`_kMaxPoints`→`_kFloorPoints` over a level-shrinking window) × streak multiplier; `scoreUnit: patterns`, humanMax 2800. Score + ×mult live in the HUD. Comparable and readable across players — standard solid quiz fairness.
- Skill depth: 4 — Real recognition ceiling: families escalate by level (`_allowed`: arithmetic/geometric → squares/rotation → fibonacci/triangular → alternating), sequences lengthen to 5, the decay window tightens 4.0→2.5s, and the "find the one that BREAKS the rule" variant (`oddMode`) demands a different, harder read. Good for repeat play.
- Pace & climax: 3 — Difficulty accelerates by `_level()` (elapsed-fraction gated 0→3). But the `_kRevealDuration` 2.4s reveal card after EVERY answer is a hard brake on flow — it's skippable (`_skipReveal` on tap), yet the default rhythm is answer→stop→read→continue, which fights an "accelerating to a climax" feel. No distinct finish.
- Polish: 4 — Polished and on-brand: FittedBox number cells, ROYGBIV color swatches with glow, rotating arrow glyphs (`Transform.rotate`), a tidy reveal card, and a calm dual-orb background. Clean.
## Top 2–3 UX failures (cite the mechanic)
1. The per-answer reveal card (`_kRevealDuration` 2.4s) brakes pace on every question; even though skippable, the default cadence is stop-and-read, undercutting the 50s accelerating arc.
2. Juice is static — correct/wrong is communicated mostly by card border color + one burst; the sequence itself never animates (no "lock-in" motion on the answer), so big plays don't feel big.
3. The family chip + rule reveal can over-explain, lowering the recognition challenge early; the real difficulty only arrives at level 2–3.
## Redesign brief — what pattern_lock_v2 MUST change
- Keep the teach but stop braking: collapse the reveal into a fast inline confirmation (the "?" cell flips to the answer with a snap, rule + teach as a brief non-blocking toast) so correct answers chain without a 2.4s wall; reserve the full card for wrong answers.
- Add kinetic juice on lock-in: animate the chosen value sliding into the "?" cell and the sequence "completing" with a satisfying snap + screen pulse scaled by streak, so a fast correct read feels like a hit.
- Sharpen the climax: a final ~10s "lightning round" where the chip hides and the window is tightest, turning the accelerate into a real finish.
- Consider gating the family chip behind difficulty (hide it at level 2+) so skill expression grows with the run.
## Keep (education + what works)
- The lesson is solid and intact: sequences as ONE simple rule (arithmetic vs geometric vs Fibonacci vs triangular vs alternating, plus rotation/cycle), with every answer revealing the rule and a plain-language `teach` line. The odd-one-out variant teaches rule-violation detection. Preserve the family taxonomy and teach text.
- The speed×streak scoring and clean option-grid affordance work — keep them.
