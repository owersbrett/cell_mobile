# food_web — UX Teardown
scale: ecosystem · duration: 50s · scoreUnit: links

## Scores (1–5)  → TOTAL: 25/35
- Instant legibility: 4 — Tiered layout (PRODUCERS at the bottom, APEX up top, labelled down the left margin) + emoji organisms + the header "DRAG EACH ORGANISM → WHAT EATS IT". The trophic spatial metaphor is readable, though the "energy flows UP" rule needs the instruction beat to land.
- Affordance clarity: 4 — Drag node-to-node (`onPanStart/Update/End`, `_nodeAt`), with a pulsing guide halo on any organism that still has an unfound link (`_hasOpenLink`). Clear. Slight softness: the drag must *release on* the target node, and hit radius is normalised (`radius: 0.085`), so near-misses on a dense top row can fail silently.
- Juice & feedback: 4 — Correct link = glowing arrow with a travelling energy pulse, `+pts` pop, burst, "ENERGY FLOWS UP!" flash; wrong = red fizzle dash with a *reason* ("Hawk doesn't eat Grass" / "energy flows up"); web-complete = gold ring + bonus. Good, teachy feedback.
- Fair/readable competition: 3 — `links` / `webs` is comparable, and the `LINKS x/y` chip shows live progress (good for pass-and-play). But it's knowledge-gated (who-eats-what) and webs are randomly generated, so two players don't face identical puzzles; the contest is recall + drag speed.
- Skill depth: 3 — Depth is in puzzle density (webs grow: more tiers, apex pair, decomposers) but the underlying act is recall of a fixed 16-organism diet table (`_kPool`). Once learned, it's pattern-completion against the clock — limited reuse ceiling.
- Pace & climax: 3 — Each web is a discrete solve, then an 850ms `Future.delayed` pause before the next (`_checkComplete`). Difficulty steps up per completion but within a web the pacing is flat "find the remaining links," and the inter-web pause breaks flow rather than accelerating into a climax.
- Polish: 4 — Trophic palette, tier labels, energy-pulse arrows, decomposer dashed-purple bonus links — coherent and on-theme. Emoji organisms are a slight style mismatch with the canvas FX.

## Top 2–3 UX failures (cite the mechanic)
1. **Discrete-puzzle pacing, no climax.** The round is a sequence of independent web solves separated by an 850ms gap; there's no escalating time pressure *within* a web, so the last 10s feel like the first. A great party game should tighten toward the buzzer.
2. **Recall-gated, randomised competition.** Win = knowing the diet table; random web generation means unequal puzzles between players and no shared-board head-to-head. Skill and luck are entangled.
3. **Silent near-miss drags.** On dense upper rows the normalised hit-test can drop a release between two close nodes with no feedback, reading as an unresponsive control rather than a wrong answer.

## Redesign brief — what food_web_v2 MUST change
- **Add intra-web pressure**: a draining "energy budget" or collapsing tier that forces fast wiring, so each web has its own rising tension and the round *accelerates* toward the buzzer instead of pausing between solves.
- **Tighten the contest**: a shared-board pass-and-play / party mode (same web for everyone, race to complete) removes draw-luck; or a continuous single growing web rather than discrete regenerations.
- **Fix near-miss feedback**: snap-to-nearest-node on release with a clear "no link there" fizzle even on empty space, so the control never feels dead.
- **Reward chains, not just links**: bonus for completing a full producer→apex *path* in order, deepening the strategy beyond enumerate-every-edge.

## Keep (education + what works)
- The trophic pyramid IS the board: energy flows up, prey→predator direction matters, and wrong links teach *why* with named reasons. This is the lesson — preserve it exactly.
- Decomposers accepting energy from anything (bonus dashed link) is a clean, correct teach of matter recycling.
- Live `LINKS x/y` progress and the guide halos make goals legible — keep them.
