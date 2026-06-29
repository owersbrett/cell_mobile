# organelle_match — UX Teardown
scale: organelle · duration: 60s · scoreUnit: points
## Scores (1–5)  → TOTAL: 22/35
- Instant legibility: 3 — Familiar 4-card "tap one" quiz shape reads instantly, but the actual task is gated on READING a text clue ("Tap the organelle that {clue}") + reading 4 text labels, so it fails the no-reading bar.
- Affordance clarity: 5 — Option cards are unambiguous tap targets (`GestureDetector` + button-styled `AnimatedContainer`, lines 763–804); no swipe/drag confusion anywhere.
- Juice & feedback: 4 — Correct = green particle burst, streak milestone = gold burst (lines 426–429), wrong = red shake (line 760), score glow + fact flare; solid, all on one Ticker→one `_BgPainter`.
- Fair/readable competition: 2 — Pure recall race with a streak multiplier (`mult = 1 + streak~/3`) and no catch-up; a player who already knows the 9 organelles runs away from a novice on prior knowledge, not in-game skill.
- Skill depth: 2 — Ceiling is "memorize 9 organelles, tap fast." Only 9 defs × 3 clue phrasings (lines 89–189); once learned it collapses to reaction time, with the confusable-distractor ramp the lone wrinkle.
- Pace & climax: 2 — The mandatory ~2.3s fact-card flare after EVERY answer (`_postAnswerTimer = _kFactFlareDuration`, line 439) stalls the loop; the round is ~15 Q's of answer→dead-air with no accelerating climax, just timer expiry.
- Polish: 4 — Clean Potatuhs ink/teal palette, scale chip, HUD with low-time red flash, perf-clean; minor: text-dense for a "party" game.
## Top 2–3 UX failures (concrete, cite the mechanic)
1. **Forced fact-card interrupt kills pace.** `_kFactFlareDuration = 2.3` blocks the next clue (`_simulate` only loads next question when `_postAnswerTimer <= 0`, lines 369–371). Tap-to-skip exists but the default rhythm is answer→pause→answer; over 60s the speed-window tightening (4.0→1.8s) never produces a felt acceleration because the flare resets cadence each time.
2. **Runaway knowledge leader, no rubber-band.** Scoring is `speedBonus × streakMultiplier` with no penalty and no comeback path; in pass-and-play the bio-literate player compounds a streak multiplier while a novice keeps resetting to ×1 — the standing is decided early and stays decided.
3. **Thin replay ceiling.** 9 organelles and 3 clue strings each means the answer set is exhausted in ~2 rounds; mastery = pure tap speed, so there's little reason to replay once memorized.
## Redesign brief — what organelle_match_v2 MUST change to clear the bar
- Make the post-answer feedback NON-blocking (a brief toast / inline flash on the card), reserving the full fact card for MISSES only, so the loop never stalls and the tightening speed window actually reads as acceleration.
- Add a climax: final ~10s "rapid fire" where the speed window collapses and points double — give the 60s arc a finish.
- Add party fairness: a catch-up rule (late clues worth more, or trailing player gets a small multiplier) so prior biology knowledge doesn't lock the standing.
- Deepen skill/replay: add a risk/reward "bank vs push the streak" choice and/or a reverse mode (show the organelle, pick its job) to widen the question space beyond 9×3.
## Keep (the education + what already works — do not lose)
- The core lesson — organelle → function mapping for all 9 organelles (nucleus, mitochondria, ribosome, chloroplast, Golgi, lysosome, ER, vacuole, cell membrane), each with job tag + fun fact + confusable set (`_kOrganelles`, lines 89–189). This is the teaching; do NOT cut it.
- The no-penalty wrong answer (forgiving, keeps novices in) and the confusable-distractor difficulty ramp (real pedagogical sharpening).
- Clean tap affordance, particle juice, and the one-Ticker→one-CustomPainter perf structure.
