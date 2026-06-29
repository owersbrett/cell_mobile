# phase_change — UX Teardown
scale: molecular · duration: 52s · scoreUnit: states
## Scores (1–5)  → TOTAL: 23/35
- Instant legibility: 3 — "MAKE IT SOLID/LIQUID/GAS" + dwell bar reads fast, and the molecules locking/flowing/flying is a great at-a-glance state cue. But the screen carries four surfaces at once (molecule box, thermometer, heating curve, header), and the crucial energy-vs-temperature distinction is subtle and not obvious early.
- Affordance clarity: 4 — Two hold-buttons, HEAT/COOL, with press-scale and glow. Clear that they're press-and-hold. Minor: nothing signals that heat *bleeds away* until you watch the state slip.
- Juice & feedback: 4 — Molecules visibly lock/jiggle/fly apart, lattice bonds snap as agitation rises, thermometer column, live curve dot, green success bloom, miss flash, `+pts` pops and bursts. Rich, single-painter.
- Fair/readable competition: 2 — Scoring snowballs: `pts = (60 + level*12) * (1 + 0.12*min(streak,12))`, and `_level` increments on *every* success and never resets within a run. A player on a streak compounds level AND multiplier, so an early lead runs away and the final standing is decided by who got rolling first — not legible or fair in party play.
- Skill depth: 3 — Managing energy against `_lossRate`, threading the latent-heat plateaus, and avoiding overshoot is a real model, but with only three target states and a forgiving dwell, mastery arrives quickly; it's mostly hold-timing after that.
- Pace & climax: 3 — Accelerates (faster bleed, shorter hold per level) and the substance swaps each success keep it fresh, but each target is still "drive to state, then hold the dwell bar" — a steady cadence rather than a tightening climax.
- Polish: 4 — Coherent state-color language, the snapping lattice is a standout, clean and jank-free.
## Top 2–3 UX failures (cite the mechanic)
1. Runaway scoring: `_level` only ever increments (`_succeed` → `_level++`, no decay) and feeds both the base points and, via streak, the multiplier. Scores compound super-linearly, so the leaderboard is decided early and reads as unfair/illegible in pass-and-play.
2. Energy ≠ temperature is under-taught at the moment of action: the player drives `_energy` but the *thermometer* shows `_temp` (flat on plateaus). When the column stops moving while you're still heating, it reads as a stuck control, not as latent heat — the lesson is on the bottom curve, away from where the eyes are (the molecules/thermometer).
3. Hold-then-wait dwell: after hitting the state, `_holdTime` is dead air where the optimal move is to feather the buttons against bleed — low-tension and easy to fumble by overshooting off a plateau.
## Redesign brief — what phase_change_v2 MUST change
- Flatten the score curve for fair competition: cap or reset `_level`'s scoring influence per target, or score by accuracy/speed-of-landing rather than an ever-climbing level×streak product, so standings stay legible and comebacks are possible.
- Put the latent-heat lesson where the action is: when energy is going in but temperature is flat (a plateau), say it loudly at the molecule box ("BREAKING BONDS — keep heating"), so the stalled thermometer reads as physics, not a broken button.
- Make the dwell active: require holding *against* the bleed/overshoot near a plateau edge so the climax of each target is precise feathering, not passive waiting.
## Keep (education + what works)
- The latent-heat model is excellent and accurate: the flat `_temp` plateaus at melt/boil, the live heating curve drawing both plateaus, and molecules that lock/flow/fly with `_agitation` make "added energy breaks bonds, not raises temp" tangible. Preserve the curve, plateaus, and molecule behavior.
- Per-substance boundaries (water/wax/mercury/glass/iron each with distinct melt/boil points) as education-in-the-mechanic — keep the substance set.
- The snapping lattice bonds and state-colored thermometer.
