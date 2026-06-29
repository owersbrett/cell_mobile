# life_cycle — UX Teardown
scale: organism · duration: 50s · scoreUnit: transitions

## Scores (1–5)  → TOTAL: 25/35
- Instant legibility: 5 — Canonical quiz shape: prompt "What comes after &lt;stage&gt;?" with a turning wheel above and four option cards below (`_buildPrompt` / `_buildOptionGrid`). The metamorphosis-type chip and glowing current node make the task obvious instantly.
- Affordance clarity: 5 — Tap one of four cards (`_onTap`). Cards are real `GestureDetector`s with `AnimatedContainer` press states; zero gesture ambiguity.
- Juice & feedback: 3 — Correct → green burst + streak gold burst (`FxBurst.spawn`), card border/glow swap, and a flare. But it is fundamentally quiz juice — card recolour + particles. The turning wheel is decorative (its speed ramps but doesn't change the answer), so the screen doesn't *pop* on a correct pick the way an arcade game does.
- Fair/readable competition: 3 — `transitions` is a clean comparable number for pass-and-play, but the win condition is *biology knowledge*: whoever has memorised the cycles wins, and random organism draws mean two players face different difficulty. Onlookers can't tell who's "better" vs who got easier draws.
- Skill depth: 3 — Real layer in the distractor design (later distractors are SIBLING stages from the same cycle, forcing order-knowledge not word-recognition — `_buildOptions` `wantSiblings`). But the ceiling is "memorise 14 organisms" plus a speed bonus; once known, it's recall + tap speed.
- Pace & climax: 2 — The biggest flaw. The answer flare lingers `_kFlareDuration = 2.0s` between every round (tap-to-skip exists but isn't signposted as urgent), and the speed bonus decays over 3.5s. Cadence is stop-start Q&A; difficulty "ramp" (faster wheel, higher tiers) doesn't create an accelerating climax — the last question feels like the first.
- Polish: 4 — Polished layout, good responsive handling (`SingleChildScrollView` fallback under 480px), coherent per-metamorphosis colour coding. Emoji glyphs are a slight brand mismatch vs the canvas art elsewhere.

## Top 2–3 UX failures (cite the mechanic)
1. **The flare stalls the round.** A 2.0s educational flare after every answer (`_flareTimer = _kFlareDuration`) is the right instinct for teaching but kills pace — in a 50s round that's a huge fraction spent reading, not playing. Skip is available but passive.
2. **Decorative wheel.** The turning life-cycle wheel (`_WheelPainter`) is the signature visual but is non-interactive — the player answers from the cards, never the wheel. The juice and the mechanic are disconnected.
3. **Knowledge-gated, draw-dependent competition.** Random organism/tier selection means head-to-head fairness depends on luck of the draw, and there's no catch-up or shared-question structure for party play.

## Redesign brief — what life_cycle_v2 MUST change
- **Keep the lesson, fix the pace**: move the biology fact into a *non-blocking* ribbon that doesn't gate the next question — auto-advance fast on correct, only dwell on a miss. Target a dense run of many quick transitions.
- **Make the wheel the mechanic**: let the player *tap the next node on the wheel* (or drag the stage into place) so the signature visual and the input are the same object — turns a flat quiz into a spatial-prediction game.
- **Add an accelerating climax**: tie wheel speed to a closing time pressure that actually matters (e.g. answer before the glowing current-node sweeps past), so the last 10s genuinely speed up.
- **Fairer party framing**: a shared-question pass-and-play mode (same organism, race the answer) removes the draw-luck problem.

## Keep (education + what works)
- The metamorphosis taxonomy is the lesson and it's well-built: complete / incomplete / direct / plant, with the type chip always visible and sibling-distractors that force true order-knowledge. Preserve all of it.
- Top-tier legibility and four-card affordance.
- The potato as a playable cycle (seed potato → sprout → … → tuber) — on-brand and a good organism-scale headliner.
