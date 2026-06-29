# converge — UX Teardown
scale: infinities · duration: 55s · scoreUnit: points
## Scores (1–5)  → TOTAL: 28/35
- Instant legibility: 3 — The frame is clear: a mode chip ("CONVERGE OR DIVERGE?" / "WHAT'S THE LIMIT?"), the series expression ("½ + ¼ + ⅛ + ⋯"), a live partial-sum chart climbing the screen, and big buttons. The chart visualizing "settles vs runs away" is a genuinely good instant read of the concept. But the JUDGMENT is hard math — telling that the harmonic series diverges while it crawls (`1 + ½ + ⅓ + ¼…`) is not a <3s call for a party audience; the chart helps but the math floor is high.
- Affordance clarity: 5 — Two big buttons CONVERGES / DIVERGES, or three limit-value options (`_buildAnswerArea`). Unambiguous, well-sized, glowing. Perfect.
- Juice & feedback: 4 — Within the single Ticker→`_ChartPainter` budget: a 16-particle burst + `+pts ×mult` pop on correct, a gold burst on streak steps, button border resolves green(correct)/red(wrong)/highlight-true-answer, and crucially the dashed asymptote SNAPS in on reveal (`showLimit`) showing where the sum was heading — excellent teaching juice. The streaming chart itself is live motion.
- Fair/readable competition: 4 — `scoreUnit: points`, humanMax 1600; speed bonus (`_kMaxPoints`→`_kFloorPoints` over 5s) × streak multiplier. Comparable, host HUD keeps the standing legible. Binary/ternary calls are fair. Good.
- Skill depth: 4 — The deepest-knowledge game of the set: geometric ratio tests, harmonic divergence, p-series (1/n² converges, 1/√n diverges), telescoping, alternating harmonic → ln2, Grandi's oscillator. Calling EARLY before the shape is obvious scores most (`_speedBonus` decays from round start) — a real risk/reward skill. High ceiling; also a high floor that may alienate non-math players.
- Pace & climax: 4 — Accelerates: terms stream faster (`_termInterval` 0.55→0.18s), and the difficulty gate widens with progress (`_pickSeries` cap = `progress*2.4`), so subtle slow-divergers and p-series arrive late. The `_kRevealHold` 1.9s is a brake but skippable (`_skipReveal`). Good build.
- Polish: 4 — The streaming partial-sum chart is the standout — glow pass + crisp line, pulsing newest dot, zero baseline, dashed limit asymptote, on-brand cyan(converge)/ember(diverge). Very polished and legibly mathematical.
## Top 2–3 UX failures (cite the mechanic)
1. High math floor for a party game: the deeper series (harmonic, 1/√n, telescoping, Grandi) demand real calculus intuition; without it, players guess and the "skill" feels like trivia luck rather than a readable in-the-moment call.
2. The chart's vertical auto-range (`lo/hi` from data + pad) can make a slow-diverging harmonic series LOOK like it's flattening, which is pedagogically the point but can feel unfair on a fast call — the visual sometimes fights the correct answer.
3. The 1.9s reveal hold (`_kRevealHold`), though skippable, brakes the accelerating cadence between rounds.
## Redesign brief — what converge_v2 MUST change
- Lower the floor without losing the lesson: add a brief, fading on-chart hint for the hard series early in a run (e.g. "terms shrink too slowly" ghost annotation) that disappears as difficulty climbs, so newcomers can make a reasoned call, not a guess.
- Resolve the auto-range ambiguity: when a divergent series is crawling (harmonic, 1/√n), make the chart subtly signal "still climbing" — e.g. a creeping trend arrow or a fixed reference gridline — so the read is honest and the early-call risk feels fair.
- Trim the inter-round brake: shorten/auto-skip `_kRevealHold` on correct calls so a hot streak chains fast; keep the full reveal for wrong calls.
- Add a climax: a final fast burst of short, decisive series so the accelerating stream resolves into a tense finish.
## Keep (education + what works)
- The lesson is the best in the set and must be fully preserved: a limit is what the partial sums settle toward; convergent (geometric r<1, p-series p>1, telescoping, alternating) vs divergent (harmonic, 1/√n, Grandi). The `behavior` strings and the dashed-asymptote reveal teach precisely. Keep the entire `_kSeries` roster and both judge/limit modes.
- The streaming chart, the two-big-button affordance, and the speed×streak scoring are excellent — keep them.
