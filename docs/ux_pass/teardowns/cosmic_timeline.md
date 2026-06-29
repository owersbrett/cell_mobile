# cosmic_timeline — UX Teardown
scale: universeAll · duration: 60s · scoreUnit: epochs
## Scores (1–5)  → TOTAL: 23/35
- Instant legibility: 4 — Empty ordered slots + a tray of shuffled cards under "ORDER THE EPOCHS — DRAG CARDS EARLIEST → LATEST" is a universally understood sort-into-order task. The deep-time ribbon up top is a bonus layer you can ignore at first.
- Affordance clarity: 3 — Drag card→slot, tap a placed card to pull it back, tap a tray card to read its fact (`_onPanStart`/`_onPanEnd`/`_onTapUp`). Clear at low levels, but at 11 cards `_slotW` clamps to 30px and cards/text shrink (6.5–9.5px) — small, fiddly grab targets on a phone.
- Juice & feedback: 4 — Outstanding *informational* feedback: correct = teal flow arrow + reveals "when"; wrong order = the arrow into the offending card snaps red (`_drawTimeline` leftOk/rightOk), showing exactly where the sequence breaks. Plus `FxBurst`, "+pts" pops, lock glow, "TIMELINE LOCKED".
- Fair/readable competition: 4 — Deterministic (placements +15+2/streak, locks +50+12/level+speed bonus), comparable, no luck. The score and the broken-arrow state are both readable to a watcher.
- Skill depth: 2 — The knowledge is a *single fixed chronology* of 11 epochs. Once you know Big Bang→…→Now (a few plays), every timeline is the same answer and the game becomes a manual-dexterity drag race against the speed bonus. The ceiling is the speed of dragging, not thinking.
- Pace & climax: 3 — 60s with levels growing 4→11 cards and a tightening par/speed bonus; the LOCK + ribbon-plot is a satisfying per-timeline climax. But the assemble phase is methodical puzzle-dragging — it doesn't accelerate moment-to-moment, and longer timelines feel slower, not faster.
- Polish: 3 — Cards, arrows, log ribbon and fact card are clean and on-brand, but the high-level layout gets cramped (tiny slots, tiny text) and the fact card overlaps the play field; readability suffers exactly when difficulty peaks.
## Top 2–3 UX failures (cite the mechanic)
1. **One fixed answer = thin depth.** `_composeTimeline` always sorts the same 11 ranked epochs into the same order; after learning it, skill collapses to drag speed. There's no variation, hidden info, or decision to master.
2. **Cramped at the hard levels.** As `_nSlots` grows, `_computeSlots` shrinks `_slotW` to ~30px and label sizes to single digits — the most demanding timelines are the hardest to physically read and grab on mobile.
3. **Pace inverts with difficulty.** Bigger timelines take *longer* to assemble; the difficulty curve adds length, not speed, so the round drags rather than accelerating toward a climax.
## Redesign brief — what cosmic_timeline_v2 MUST change
- **Add real decisions beyond recall**: e.g. inject distractor/duplicate epochs, "which came first" duels under a shrinking clock, or relative-spacing judgments on the log ribbon — so depth survives once the linear order is memorized.
- **Fix the small-target problem**: cap simultaneous cards on screen (deal in waves) or use a scroll/snap rail so targets stay thumb-sized at every level instead of shrinking to 30px.
- **Make it accelerate**: drive difficulty with a tightening timer / incoming-card pressure rather than longer rows, so the 60s builds to a frantic finish instead of a slow long sort.
## Keep (education + what works)
- The lesson is the mechanic: cosmic history is a *named, ordered* sequence where order matters (no stars before atoms, no Sun before galaxies), each card teaches its "when" on placement, and the log ribbon shows why the first second spans as much timeline as the later eons (`_logFrac`, Big Bang pinned left). Keep all of it.
- Keep the red-snap / teal-flow arrow feedback — it's a model way to show *where* an ordering is wrong.
- Keep the LOCK→ribbon climax and the per-epoch facts; they're genuinely informative.
