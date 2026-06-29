# standard_model — UX Teardown
scale: particles · duration: 50s · scoreUnit: particles
## Scores (1–5)  → TOTAL: 26/35
- Instant legibility: 3 — The structure reads instantly: particles fall, three labeled bins at the bottom (QUARKS / LEPTONS / BOSONS with subtitles "6 · color-charged" etc., `_drawBins`), "Drag each particle to its family." But the actual decision — WHICH family a symbol belongs to — requires real knowledge; a novice can't classify "μ" or "ντ" in <3s. The tells (charge badge, color-charge rim, mass→size) help but must be taught.
- Affordance clarity: 4 — Drag (pan): `_onPanStart` grabs the nearest particle within 46px, bins glow on hover (`hoverBin`), release to drop. Clear grab-and-drag with good hover feedback.
- Juice & feedback: 4 — Within the single Ticker→`_SMPainter` budget: 14-particle burst on a correct drop, a `classify` pop ("Up · gen 1 quark · +⅔"), a `+pts` pop, bin glow, right/wrong full-screen flash tint, and a "—" miss pop when one sinks past `_dangerLine`. Strong.
- Fair/readable competition: 3 — `scoreUnit: particles`, humanMax 800; points scale with streak + difficulty + speed bonus (`_resolveCorrect`). Comparable and readable. But dragging is slow — in 50s with only 3–7 concurrent you sort a modest count, so the score spread between players is compressed versus a tap game.
- Skill depth: 4 — Excellent knowledge ceiling: 17 real particles across generations, and the family color FADES with difficulty (`famStrength = 1 - difficulty/4`) while charge badge and color rim drop out (`showCharge`/`showColorRim`), so late game tests real classification (force-carrier vs matter, which generation), not color-matching. The tricky set (`_kTricky`: neutrinos, photon, gluon, Z, Higgs) is weighted up. Real depth.
- Pace & climax: 4 — Genuinely accelerates: `_difficulty = sorted/4 + elapsed/14`, fall speed 42→130, spawn interval 1.55→0.62, `_maxConcurrent` 3→7, plus the tell-fade ramp. Pressure rises convincingly. No single climax beat but a strong build.
- Polish: 4 — Polished and on-brand: glowing orbs, animated 3-dot color-charge rim, charge badges, difficulty pips, atmospheric motes. The drag physics are clean.
## Top 2–3 UX failures (cite the mechanic)
1. Drag is the throughput bottleneck — one-at-a-time pan-to-bin (`_onPanStart`/`_onPanEnd`) caps how fast a skilled player can act, compressing score spread and capping the climax intensity even as particles fall faster.
2. High knowledge floor with thin onboarding: classifying a bare symbol like "ντ" or "g" needs the tells, but the tells fade fast and there's no quick reference, so a novice stalls early (lots of "—" misses) before learning.
3. No spectator climax: rising fall-speed creates pressure but there's no crescendo moment that reads to onlookers in pass-and-play.
## Redesign brief — what standard_model_v2 MUST change
- Speed up the verb: allow a flick/throw toward a bin or a tap-particle-then-tap-bin option, so a confident player can clear particles fast — drag-only throttles skill expression. Keep drag as a fallback.
- Smooth the learning curve: a brief "first miss" tell highlight or a persistent mini-legend early in the run, so novices learn the three families before the color tell fades (`famStrength`).
- Add a climax: a late-game "beam burst" where particles stream fastest and a clean-sort streak triggers an escalating multiplier + screen-wide flash, turning the difficulty ramp into a finish.
- Make the standing spectator-legible (a sorted-count milestone flash) for pass-and-play.
## Keep (education + what works)
- The lesson is the strongest part and must be preserved: the full 17-particle Standard Model roster, the three families, and especially the tell-fade ramp that forces real family knowledge late. The `classify` flash ("Charm · gen 2 quark · +⅔") teaches on every correct drop. Keep the roster, the tricky-set weighting, and the fading tells.
- The hover-glow bins, charge/color-charge/mass tells, and burst feedback all work — keep them.
