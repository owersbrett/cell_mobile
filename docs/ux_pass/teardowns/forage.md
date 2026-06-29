# forage — UX Teardown
scale: organism · duration: 50s · scoreUnit: energy

## Scores (1–5)  → TOTAL: 28/35
- Instant legibility: 4 — One animal, gold food orbs, a top energy meter, "DRAG TO FORAGE" + a one-line rule on the ready screen (`_paintReadyHint`). The eat-to-grow loop reads fast. The only un-obvious part is *why* moving is bad — the energy drain is invisible until the meter drops.
- Affordance clarity: 4 — Drag anywhere to steer toward the finger (`onPanDown/Update`), with a pulsing steer-target ring for feedback. This is the Farm-Panic risk done right: the hint literally says DRAG and the target ring confirms it. Slightly soft because the animal chases the finger rather than being directly dragged.
- Juice & feedback: 5 — Best in this cohort. Energy-keyed body colour (green→gold→red), squash/stretch on flinch, bite knockback + `-18 ⚡` pop + burst, cold vignette that intensifies late, low-energy danger pulse on the meter, STARVED flash. All under a strict perf guardrail: no per-frame setState, `_RepaintNotifier`, particle/pop/predator caps.
- Fair/readable competition: 3 — `energy` banked is a clean comparable number, but the scoring's clever core — EFFICIENT vs inefficient meals (`v > _spentSinceMeal`) — is computed from invisible state ("cost since last meal"). A pop says `EFFICIENT` / `(cost N)` but the player can't *see* their running cost, so neither they nor a spectator can read why a meal scored well.
- Skill depth: 4 — Real optimisation: eat-nearby vs chase-far, rest-to-reset-cost, predator avoidance, manage the rising basal drain. The efficiency rule gives a genuine mastery lever beyond "grab everything."
- Pace & climax: 4 — Honest squeeze: food count ramps 14→6, respawn 0.8s→2.6s, basal drain 2.6→5.0, predators 0→4 getting faster (60→150) and homing late. The field tightens into a real survival climax.
- Polish: 5 — Cohesive forage-green world, predator eyes/fear-rings for legibility, thrive marker on the meter, considered perf comments referencing the black-frame harvest lesson. Clean.

## Top 2–3 UX failures (cite the mechanic)
1. **Invisible efficiency cost.** The headline lesson (net energy = intake − expenditure) lives in `_spentSinceMeal`, which is never shown live — only revealed post-hoc in the eat pop. Players learn EFFICIENT is good but not how to *aim* for it; the central teach is hidden from the exact moment it matters.
2. **Movement cost is unfelt.** `_kMoveCost` bleeds energy while steering, but there's no live "you are spending energy now" signal (the meter just slowly drops among other drains), so the cost/benefit of a chase isn't legible in the moment.
3. **Spectator-flat competition.** In pass-and-play it looks like "drive blob, eat dots"; the strategic layer (efficiency, resting) is invisible to onlookers, so the social read is just the final number.

## Redesign brief — what forage_v2 MUST change
- **Surface the cost ledger**: draw a live "cost since last meal" trail or a depleting tether from the last-eaten spot, so the player can see when a far orb has gone net-negative *before* committing. Make the EFFICIENT threshold visible (e.g. a shrinking value-halo on food as you travel toward it).
- **Feel the movement drain**: a small energy-burn fleck stream off the animal while moving fast, so "speed costs" is sensory, not just a number ticking down.
- **Read the strategy from outside**: a glanceable EFFICIENT-streak flourish (the streak already exists via `noteStreak`) elevated to a screen-level effect so spectators see skill, not just a score.
- Keep <80s and the perf guardrail; do not regress the no-setState architecture.

## Keep (education + what works)
- The whole game IS the energy budget equation — intake (food) minus three expenditures (movement, basal drain, predators). This is the lesson; preserve all three drains.
- The EFFICIENT/inefficient meal scoring is the right mechanic for the teach — keep it, just make it visible.
- The juice and the perf architecture (RepaintNotifier, caps) are exemplary — this is the reference build for the cohort.
