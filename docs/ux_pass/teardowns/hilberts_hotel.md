# hilberts_hotel — UX Teardown
scale: infinities · duration: 50s · scoreUnit: check-ins
## Scores (1–5)  → TOTAL: 20/35
- Instant legibility: 2 — The core read is a text banner (`_arrival.headline` "ℵ₀ BUSES — EACH ℵ₀") plus three text rule cards with math notation ("n → n+1", "n → 2n", "Prime powers"). You must *read and parse symbols* every round; nothing about the corridor tells you what to do in <3s. This is a multiple-choice quiz wearing an animation.
- Affordance clarity: 4 — Rule cards are obvious tappables (chevron, card chrome, `_optionCard`→`_onRule`). The corridor is correctly non-interactive. Minor: the field-tap-to-skip (`_onTapField`) is only revealed by the "TAP TO CONTINUE" label during feedback.
- Juice & feedback: 3 — Good canvas juice (gold open-room glow, `_maybeSpark` 10-spark bursts, red `_flashRoom`, sliding potato guests, ∞ fade) all on one Ticker→painter. But the loop is gated by a mandatory `_kFeedbackDur = 2.2s` explanation hold that kills momentum every single round.
- Fair/readable competition: 3 — Deterministic grade (`rule.solves.contains(_arrival)`), curated distractors that genuinely fail, so it's fair and score-comparable. But it's turn-based reading — nothing for a watching opponent to feel; pass-and-play it's "take the quiz."
- Skill depth: 2 — There are exactly three arrival types, each with exactly one correct rule (`_kCorrect`). Once you memorize guest→+1, bus→2n, buses→primes (≈3 rounds), all remaining skill is pure reaction speed. No ceiling, no decisions, no combos.
- Pace & climax: 2 — Escalation exists (harder arrivals enter at progress 0.28/0.58, 4th option at 0.40) but the 2.2s feedback gate between every round flattens any acceleration. No build to a finish — it's a metronome of read→wait→read.
- Polish: 4 — Clean brand execution: marquee glow, gold/sienna palette, ovoid potato guests with eyes, ∞ continuation label. No visible jank, single-painter budget respected.
## Top 2–3 UX failures (cite the mechanic)
1. **It's a reading quiz, not a game.** The decision lives entirely in parsing the banner text + the symbolic rule cards (`_buildBanner` / `_optionCard`). Legibility is gated on literacy in set theory, not on a glanceable game state.
2. **Three fixed answers = zero depth.** `_kCorrect` is a 3-entry map; after a few rounds the player is just speed-tapping a memorized lookup. The `_streak`/speed-bonus scoring can't manufacture mastery on top of a solved decision.
3. **The 2.2s feedback hold breaks pace.** `_kFeedbackDur` forces a dead beat after every answer; the round never accelerates the way the rubric's 45–60s climax demands.
## Redesign brief — what hilberts_hotel_v2 MUST change
- Make the corridor itself the verb: instead of picking a labeled rule, **the player performs the reassignment by tapping/swiping guests** (e.g. drag the shift, double rooms, or assign bus seats) so the bijection is *enacted spatially*, not selected from a text menu — legibility comes from the rooms, not the words.
- Add depth via **escalating, mixed arrivals in flight** (a queue of buses to place simultaneously, partial credit for how many seats you legally fit) so there's a real, repeat-rewarding ceiling beyond a 3-answer lookup.
- Replace the mandatory 2.2s hold with **inline, non-blocking consequence** (the double-book/eviction animates live, score ticks continuously) so the round can accelerate to a flood-of-buses climax in the last 10s.
## Keep (education + what works)
- The paradox is genuinely taught: the corridor visibly resets to full each round (`_fillHotel`) yet always makes room — keep that "full ∞ hotel still fits more" beat, it's the whole lesson.
- Keep the three real bijections (n→n+1, n→2n, prime-powers) and the *honest* distractors that physically fail (dump-to-1 double-books, n−1 evicts guest 1, append hits a dead end) — the failure animations are the best teaching moments.
- Keep the marquee ready-state and brand palette; the look is already polished.
