# tissue_type — UX Teardown
scale: tissue · duration: 60s · scoreUnit: points

## Scores (1–5)  → TOTAL: 27/35
- Instant legibility: 4 — The format reads instantly: one slide, the prompt "WHICH TISSUE?", a 2×2 of labeled+iconed buttons. You know what to DO in <3s. (Reading the slide itself needs histology, but the loop is obvious.)
- Affordance clarity: 5 — Four big tap targets (`_buildTypeButton`), each with icon + label, `AnimatedContainer` press feedback, green/red reveal states. Unambiguous tap game.
- Juice & feedback: 4 — Particle `_burst` on correct, extra gold burst at each streak step, slide frame turns green/red with a glow shadow, the fact flare slides up. The procedural histology redraw is keyed to `sampleId` behind a `RepaintBoundary`; the cheap ambient/particle layer animates per frame. One small ding: `_onTick` calls `setState` every frame over the widget tree.
- Fair/readable competition: 4 — Speed scoring (`_speedBonus` 130→25 floor) × streak multiplier (`1 + streak~/3`) is comparable across players and self-limiting; no runaway. Quiz cards read perfectly in pass-and-play. Only divergence is the histology knowledge gap.
- Skill depth: 3 — Genuinely only 4 answer classes; once you learn the four morphologies (sheet/scatter/fibre/star) it collapses to recognition speed. The procedural subtype variety (`_kVariants`, subtlety ramp) keeps it fresher than a static quiz, but the decision space is thin.
- Pace & climax: 3 — It does accelerate (`_deadline` 7s→3s, `_subtlety` 0→0.82 over `_kRampSamples=14`). But the mandatory fact flare (`_kFactFlareDuration=2.4`, tap-to-skip) interrupts EVERY answer, so the rhythm is stop-start rather than a smooth climb to a buzzer.
- Polish: 4 — The standout: real procedurally-drawn H&E slides per tissue/subtype (`_SamplePainter`), uniform stain palette forcing shape-reading, perf-conscious RepaintBoundary isolation. Very on-brand and credible.

## Top 2–3 UX failures (concrete, cite the mechanic)
1. Flow interruption: the fact flare gates progress after every sample (`_flareTimer = _kFactFlareDuration`); in a 60s party game that's ~15 forced micro-pauses. Education shouldn't cost the climax.
2. Shallow ceiling: only four buttons and a fixed taxonomy means mastery = reaction time. There's no compounding decision or risk to chase across runs.
3. Pure-recall barrier for newcomers: a player who's never seen histology has no in-game ramp from "shown the tell" to "must recall it" — `_subtlety` only makes it harder, never scaffolds the first correct reads.

## Redesign brief — what tissue_type_v2 MUST change
- Don't stop the clock to teach: turn the fact into a non-blocking ticker/peel that the next sample doesn't wait on, so the 7→3s ramp actually delivers a buzzer-beating finish.
- Deepen the decision: add a sub-type call or a "tag the tell" tap (e.g. point at the striations/lacunae) for bonus, so reading morphology — not just naming the family — is rewarded and the ceiling rises.
- Scaffold newcomers: first few samples can label one diagnostic feature, fading as `_subtlety` climbs, so a novice ramps instead of guessing.
- Add an accelerating combo stake (the streak multiplier should visibly raise tempo/tension, not just points).

## Keep (education + what works)
- The shape-not-colour constraint (uniform H&E palette) is the lesson and it's beautifully literal — keep it.
- The four primary-tissue taxonomy with real subtype facts (squamous/cuboidal/columnar/stratified; adipose/bone/blood/areolar; skeletal/cardiac/smooth; neuron/glia) is solid, accurate content. Preserve it.
- The procedural `_SamplePainter` is the brand asset of this game; keep and reuse.
