# half_life — UX Teardown
scale: atoms · duration: 50s · scoreUnit: accuracy
## Scores (1–5)  → TOTAL: 21/35
- Instant legibility: 3 — Prompt ("HALF-LIFE 3.0s · MEASURE AT 50%"), 6×6 decaying grid, and a live decay curve are all on screen at once. The goal is readable but dense; tying "50%" to the visible grid takes a beat, and the curve+grid+counter compete for attention.
- Affordance clarity: 4 — One `MEASURE` button, disabled outside a live round. Unambiguous. Minor: nothing signals that *waiting too long* auto-fails until it happens.
- Juice & feedback: 4 — Decay sparks per atom flip, reveal card (PERFECT/MEASURED/TOO LATE), `+pts` pop, and the frozen cursor on the curve showing how close you were. Good, single-painter.
- Fair/readable competition: 3 — Accuracy attack, scores comparable. But it's a passive watch-and-tap; opponents in pass-and-play just wait out the timer with you. No interactive tension between players.
- Skill depth: 2 — The lesson's own readout sabotages the skill: `STILL RADIOACTIVE: $aliveCount / 36` lets you ignore estimation entirely and just tap when the counter hits 18 / 9 / 4–5. The intended "feel the half-life" skill is replaced by reading an integer.
- Pace & climax: 2 — Each round is dead-wait → single tap → 1.6s reveal. Early rounds (`t½` up to 3.4s, waiting 1–3 half-lives) are slow and idle. The structure is inherently low-action; it accelerates across rounds but never within one.
- Polish: 4 — The exponential curve with target ring and sliding cursor is genuinely elegant; clean palette, no jank.
## Top 2–3 UX failures (cite the mechanic)
1. The `aliveCount / 36` counter hands away the answer. The whole game is "estimate when the named fraction remains," but a literal live count makes it a trivial counting task — the skill and the lesson both evaporate.
2. Dead waiting time: with `t½` up to 3.4s and `targetN` up to 3, a round forces ~10s of passive watching before the one meaningful input. No micro-engagement during the wait.
3. Spectator-flat competition: nothing one player does affects another or even changes the screen; pass-and-play is a queue of solo timing tests with no shared tension.
## Redesign brief — what half_life_v2 MUST change
- Remove or hide the exact `aliveCount` (or replace with a deliberately fuzzy/blurred glow mass) so the player must *estimate* fraction — restoring both the skill and the lesson. Reveal the true count only in the post-tap card.
- Fill the wait with agency: e.g. let the player *place a prediction marker* on the curve as it decays, or measure multiple samples racing in parallel, so there's continuous input instead of one tap.
- Add per-player or head-to-head tension (closest-guess wins the round, or a live opponent ghost-cursor) to make competition readable moment-to-moment.
- Tighten the within-round arc — shorter early half-lives or stacked simultaneous samples — so each round climbs instead of idling.
## Keep (education + what works)
- The core truth is beautifully built: per-atom random `_th` thresholds make *which* atom decays random while the *count* tracks `36·2^(−t/t½)` exactly — randomness vs. statistics shown at once. Preserve this model.
- The live `2^−n` curve with ringed target and the cursor that freezes at the tap — this is the teaching surface; keep it central.
- The 50→25→12.5% target ladder and the reveal card's "you read X% · target Y%" comparison.
