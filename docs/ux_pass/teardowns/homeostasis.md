# homeostasis — UX Teardown
scale: organism · duration: 50s · scoreUnit: balance

## Scores (1–5)  → TOTAL: 26/35
- Instant legibility: 3 — Four vertical gauge columns, each with a needle, a green safe band, a set-point line, a drift arrow, and two labelled buttons (`_paintColumn`). That is a lot to parse against a 3s bar — a new player must learn "green band good, push the needle back" while four needles already drift. The early hint-glow on the corrective button (`hint`) helps but the cockpit is dense.
- Affordance clarity: 4 — Tap ▼/▲ buttons under each gauge (`_handleTapDown` hit-tests `lowerBtn`/`raiseBtn`). The arrows + word labels (SWEAT/SHIVER, INSULIN/GLUCAGON) make direction clear, and the hint glow points at the right button early. Minor risk: buttons are canvas-drawn rects, not widgets, and the labels are tiny (`size 8–9`).
- Juice & feedback: 4 — Push-flash bloom on the track, green recover-flash, `+25` pops + bursts on recovery, amber shock banner with a flash, and a live "n/n IN BAND" status. Good coverage within one Ticker/painter.
- Fair/readable competition: 3 — `balance` accrues passively (in-band drip + all-in bonus + recoveries), giving a comparable number, but the live state is a busy four-gauge instrument panel — an onlooker in pass-and-play can't read who is winning at a glance, only the final score.
- Skill depth: 4 — Genuine depth: divided attention across 4 drifting systems, shock triage, and a 4th system (O₂) coming online mid-round while bands narrow. Prioritising which gauge to save under pressure is a real, repeatable skill. Strong dimension.
- Pace & climax: 4 — Honest acceleration: bands narrow (`_kHalfBandStart 0.16` → `0.085`), drift magnitude scales with difficulty, shock interval shrinks (7.5s → 3.5s), and O₂ activates at 42%. The instrument panel genuinely gets harder to hold.
- Polish: 4 — Cohesive teal "balance" theme, clear per-system colours, the locked "SOON" plate for dormant O₂ is a nice touch. Tight, perf-clean painter.

## Top 2–3 UX failures (cite the mechanic)
1. **Cold-start overload.** Four full gauges with bands, set points, needles and drift arrows all live from second one is too much to onboard in 3s; the lesson (negative feedback) is buried under instrument-reading. The hint glow only fires when a gauge is already `> halfBand * 0.55` deviated and `difficulty < 0.6`.
2. **Spectator-opaque competition.** In party mode the screen reads as a dashboard, not a contest; there's no single dominant "you're doing well / badly" signal beyond the small header pill.
3. **Tap-spam viability.** Because a tap is a fixed `_correctStep` nudge and in-band simply drips points, a player can mash the obviously-needed button without internalising the feedback loop; the mechanic doesn't strongly punish over-correction past the band.

## Redesign brief — what homeostasis_v2 MUST change
- **Stagger the onboarding**: start with ONE gauge and a big "push it back into green" beat, then introduce the others on a ramp (the O₂ wake pattern, applied from the start). Let legibility build instead of dumping the cockpit.
- **One dominant body-state signal**: drive a single whole-screen "health" indicator (vignette, body silhouette colour, heartbeat) off the all-in state so both the player and a spectator instantly read winning/losing — keep the gauges as the *controls*, add a glanceable *outcome*.
- **Punish over-correction**: make overshooting past the far band a visible cost (whiplash penalty), so the negative-feedback lesson — *nudge toward the set point, don't slam* — is enforced by the mechanic.
- Sharpen the climax: when bands get tight in the last 10s, escalate shock spectacle and the all-in bonus so holding balance feels heroic.

## Keep (education + what works)
- The core is the lesson made playable: each gauge IS a negative-feedback loop (too high → SWEAT/INSULIN, too low → SHIVER/GLUCAGON), and the shocks (EXERCISE, COLD SNAP, BIG MEAL…) are real perturbations. Preserve the system set and the band/set-point model.
- The recovery `+25` ("negative feedback paid off") and the all-systems-in-band bonus correctly reward the right behaviour.
- The acceleration curve and the O₂-comes-online reveal are good — carry them into v2.
