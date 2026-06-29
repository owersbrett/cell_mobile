# decay_chain — UX Teardown
scale: particles · duration: 50s · scoreUnit: particles
## Scores (1–5)  → TOTAL: 26/35
- Instant legibility: 3 — The frame reads well: a central unstable particle with a shrinking fuse arc, the live equation at top ("n⁰ → p⁺ + e⁻ + ν̄", `_hud`), products bursting outward, "catch the real products · refuse the impostor." But under time pressure a novice must read charged symbols (e⁻, ν̄, μ⁻) and cross-check them against the equation to spot the impostor — that's a fast, knowledge-loaded read, not an instant one.
- Affordance clarity: 3 — Tap flying particles (`_handleTap`, 34px reach). The tap affordance is clear. What to AVOID is less so: the impostor is defined as "not in the current decay," signaled only by a faint flickering warning ring (`p.impostor` in `_product`) — readable by a sharp eye, easy to miss while everything is in motion.
- Juice & feedback: 4 — Rich within the single Ticker→`_DecayPainter` budget: a decay puff, charge-colored "+10" pops, a "CHAIN!" pop when an unstable product is caught, "CLEAN +bonus" on a clean batch, screen flash (`_flash`/`_flashColor`), motion trails, and the rotating detector ring. Lands well.
- Fair/readable competition: 4 — `scoreUnit: particles`, humanMax 950; +10/catch, +25-and-up clean bonus, −12 impostor, −5 escape (`_resolveCatch`/`_updatePlay`). Comparable, readable, and the clean-batch + chain mechanics create meaningful swing for pass-and-play.
- Skill depth: 4 — Real depth: read the equation to know the real products, refuse impostors (conservation of charge), and deliberately catch the unstable product (μ⁻, π⁻) to trigger a re-decay chain (`_decay(p.kind) != null` → new `_Pending`) for more catches. The clean-batch bonus rewards completeness. Strong mastery hooks.
- Pace & climax: 4 — Accelerates cleanly: fuse 1.5→0.8s, product speed 72→150, impostor chance 0.25→0.7 (and a second impostor past 50%), respawn 1.6→0.7. The detector gets busier and trickier. Good build; no single crescendo beat.
- Polish: 4 — Strong, physics-flavored, on-brand: detector ring with rotating ticks, charge-colored orbs, fuse arcs lerping lime→red, motion trails, primer state ("REACTOR PRIMED"). Cohesive.
## Top 2–3 UX failures (cite the mechanic)
1. Impostor read is too subtle under load — a faint flicker ring (`_product`) is the only tell, and identifying "which symbol isn't in n⁰ → p⁺ + e⁻ + ν̄" while products fly outward is a hard, knowledge-gated split-second decision; easy to mis-tap and eat −12.
2. Instant legibility leans on symbol-reading: the equation is the source of truth, but mapping equation→flying-orbs in real time is demanding for anyone who doesn't already know the decays.
3. No spectator-legible climax — the ramp raises pressure but there's no read-from-across-the-room finish moment.
## Redesign brief — what decay_chain_v2 MUST change
- Make the impostor unmistakable on a fast read without dumbing down the lesson: e.g. briefly highlight the equation's real-product symbols as products spawn, or give the impostor a clearer "violates charge" cue (a red ✗ charge badge) so refusing it is a skill, not a guess.
- Reduce symbol-matching load for novices early: in the opening seconds, label each flying product's charge prominently and tie it to the equation, then fade that aid as difficulty climbs (mirror standard_model's tell-fade) — preserves the late-game knowledge test.
- Add a climax: a final "reactor meltdown" window with the fastest fuses and a chain-combo multiplier, so the accelerating impostor/speed ramp resolves into a finish.
- Surface a spectator-legible standing (clean-streak flash / milestone) for pass-and-play.
## Keep (education + what works)
- The lesson is excellent and must be preserved: real decays with conserved charge (β⁻: n⁰ → p⁺ + e⁻ + ν̄; μ⁻ and π⁻ chains), the impostor-violates-conservation idea, and the multi-step chain where catching an unstable product re-decays it. Keep the equation HUD, the charge-colored symbols, and the chain mechanic.
- The fuse arcs, clean-batch bonus, and detector-ring presentation are great — keep the feel.
