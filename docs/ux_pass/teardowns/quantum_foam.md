# quantum_foam — UX Teardown
scale: nothings · duration: 50s · scoreUnit: eV
## Scores (1–5)  → TOTAL: 25/35
- Instant legibility: 3 — "Tap a flickering pair before it annihilates · shorter-lived = more energy · don't tap the gold" (`_buildReady`). The basic read (tap glowing things, avoid gold) lands fast, and reals have a distinct steady glow + stability ring (`_paintReal`). But the energy–time tradeoff — the whole strategic point — is invisible before you tap: a pair's `energy`/`lifetime` aren't shown, only inferred from brightness/size (`hot = energy/90`). You can't read value at a glance.
- Affordance clarity: 4 — Tap, with a forgiving hit test (`reach = pr.sep + 38`, nearest of real/pair wins). Gold reals carry an explicit "don't tap" stability ring. Clear.
- Juice & feedback: 4 — Within the single Ticker→`_FoamPainter` budget: dual FxBurst on particle + antiparticle (`_harvest`), a colored `+energy` pop (gold on streak bonus), and on a wrong gold tap a `−20 real!` pop, red screen tint, and a `Transform.translate` shake. Lands well.
- Fair/readable competition: 3 — `scoreUnit: eV`, humanMax 520, with a small streak bonus (`_streak >= 3`). Comparable and readable, and the −20 gold penalty creates swing. But the standing reads as a bare number; no spectacle for spectators.
- Skill depth: 3 — The intended depth (prioritize shorter-lived high-energy pairs before they vanish vs. let some annihilate free) is real risk/reward, but it's NOT legible — since energy isn't shown pre-tap, optimal play collapses to "tap everything fast, avoid gold." The deeper read the design wants isn't surfaced, so the ceiling is lower than intended.
- Pace & climax: 4 — Honestly accelerates: spawn interval lerps 0.78→0.26s, `perSpawn` 1→2→3 across progress, lifetimes shrink (more energy, faster blink), and reals intrude more often late (`realCap` 1→4). The foam visibly seethes harder. No single climax beat, but the ramp is good.
- Polish: 4 — Atmospheric vacuum (`GameFx.atmosphere`, 40 motes), the +/– matter/antimatter glyphs, the borrowed-energy filament between pair halves, and pop-in/fade envelopes are tasteful and on-brand.
## Top 2–3 UX failures (cite the mechanic)
1. The energy–time tradeoff is invisible: `_Pair.energy` (inversely ∝ lifetime) is never shown, so the strategic core is unreadable and play degenerates to fast tapping.
2. Skill expression is flattened — with no pre-tap value cue, there's no reason to choose one pair over another beyond "still alive," undercutting the intended risk/reward.
3. Standing is a bare eV number with no spectacle; pass-and-play lacks a shared "ooh" moment despite the rich per-tap juice.
## Redesign brief — what quantum_foam_v2 MUST change
- Surface the tradeoff: make a pair's energy legible before the tap — a tightening countdown ring, a numeric "+N eV" preview, or size/heat that unmistakably maps to value AND urgency — so choosing the high-value short-lived pair is a readable skill.
- Add a decision layer beyond reflex: e.g. a "borrow too much and it costs you" overload meter, or pairs that must be tapped at peak separation (`sep = maxSep·sin(t·π)`) for max eV, turning timing into the skill.
- Give the climax a beat: a late-game "vacuum surge" where many high-energy pairs flash at once, so the accelerating spawn ramp resolves into a crescendo.
- Add a spectator-legible standing (a filling energy meter / milestone flashes) for pass-and-play.
## Keep (education + what works)
- The lesson is excellent and intact: virtual particle–antiparticle pairs borrow energy from the uncertainty principle, live a borrowed lifetime, then annihilate; shorter borrow = more energy (energy–time uncertainty). The +/– glyphs, the rise-and-fall separation, and "real particles are steady, don't tap" all teach correctly — preserve them.
- The forgiving hit test and the penalty shake/tint feedback are good; keep the feel.
