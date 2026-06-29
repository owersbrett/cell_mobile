# electron_shells — UX Teardown
scale: atoms · duration: 50s · scoreUnit: atoms
## Scores (1–5)  → TOTAL: 22/35
- Instant legibility: 3 — The target panel (Z tile, name, "Seat N electrons", live `K 2/2` chips) and the ghost-slot rings communicate the goal, but you must *read* the config string to know what to build; the concentric-ring nucleus reads as decoration until you parse it. Not graspable in <3s without the lore.
- Affordance clarity: 2 — `_onTapDown` overloads one tap: it first grabs the nearest electron within `_kHitR=30`, and *only if none is found* treats the tap as a ring-selection within `_kRingTol=28`. The two actions look identical and the ring-select affordance is invisible. Auto-advance (`_activeShell++`) papers over it, but manual ring selection is undiscoverable — this is the Farm-Panic "looked tappable, was a swipe" trap.
- Juice & feedback: 4 — Strong: `_Flying` electrons arc into slots, `FxBurst` on seat, OCTET!/DUET! pops, a 1.4s celebration banner with NOBLE callout, atmosphere motes, pulsing next-shell ring. Within the one-Ticker→one-`_ShellsPainter` budget.
- Fair/readable competition: 3 — Pure score attack via host; comparable across players. But `addTime(3s)` per stabilized atom lets a strong player extend the clock indefinitely, compounding a lead — a soft runaway in party mode. No head-to-head signal beyond the number.
- Skill depth: 3 — Real levers (fill order, drift speed `1→1.9×`, growing element pool) but the core act is "tap the right floating electron"; slot order is mechanically forced, so mastery is mostly target acquisition speed, not decision-making.
- Pace & climax: 3 — Accelerates via `_speedMul` and `_unlocked`, but the +3s extensions and steady atom-after-atom loop give it a flat plateau, not a tightening climax toward 50s.
- Polish: 4 — Clean Potatuhs palette, coherent orb/glow language, no obvious jank; single painter.
## Top 2–3 UX failures (cite the mechanic)
1. Overloaded single tap (`_onTapDown`): electron-grab vs ring-select share one gesture distinguished only by hit-test priority. Players who want to back-fill an inner shell or re-select a ring have no visible affordance and will accidentally seat electrons.
2. The drifting `_field` electrons add motion but no decision — any electron is interchangeable, so the "grab" is a target-acquisition chore, not a choice. Skill collapses to tapping fast.
3. `addTime(3s)`/atom (`_kAtom` path) creates a runaway clock: the better you are, the longer your round, widening score gaps unfairly in party play.
## Redesign brief — what electron_shells_v2 MUST change
- Split the gesture: make shell-selection an explicit, visible control (tap a chip in the panel, or drag an electron *onto* a ring) so seating vs selecting can never be confused.
- Make the electron choice meaningful — e.g. electrons carry a value/charge, or only certain electrons fit the next slot — so grabbing is a decision, not just aim.
- Replace per-atom `addTime` with a fixed clock + escalating per-atom score, or cap the bonus, to kill the clock-runaway and keep standings legible.
- Surface the octet *gap as a number* on the active shell (already a known TODO) for instant legibility of "how many more".
## Keep (education + what works)
- The chemically-accurate first-20 `_elements` table and 2-8-8-8 `_shellMax` model — do not touch.
- Ghost-slot rings that draw the octet *gap* visibly, inside-out fill enforcement, and the NEUTRAL/OCTET/NOBLE callouts — this is the lesson made mechanical and it lands.
- The flying-electron + celebration juice and the live config chip row.
