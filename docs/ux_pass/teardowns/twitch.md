# twitch — UX Teardown
scale: tissue · duration: 60s · scoreUnit: force
## Scores (1–5)  → TOTAL: 25/35
- Instant legibility: 4 — A glowing pulse sliding toward a tinted strike zone (`_paintNerve`, y=0.74) plus the "TAP THE SIGNAL ON THE BEAT" calm-state prompt reads as a rhythm-tap game in well under 3s; the sarcomere up top (cy=0.34) is decorative and split-focus but never blocks comprehension.
- Affordance clarity: 4 — Single `onTapDown` on an opaque full-screen `GestureDetector` (line 238–240); tap-anywhere is the only verb, no swipe/drag ambiguity, and the prompt literally says "TAP".
- Juice & feedback: 4 — Strong for a one-Ticker→one-Painter budget: `_fireFlash`/`_missFlash` screen washes, `FxBurst` sparks colored by quality, `FxPop` "PERFECT +N" callouts, tetanus glow on the Z-discs, and a live force bar — but `shouldRepaint => true` every frame and there is **zero audio**, a real gap for a timing game where ears beat eyes.
- Fair/readable competition: 2 — Purely solo; no pass-and-play, no opponent state, no comparative standing in-frame. Worse, the `_kTetanusPointsPerSec` +12/sec drip (line 153) compounds for whoever reaches tetanus first while a struggling player earns nothing — a structural runaway-leader engine with no catch-up.
- Skill depth: 4 — Real ceiling: dead-center timing (`quality = 1 - err/window`), streak multiplier to 2.4× (line 204), and the fire-rate-vs-relax race to hold contraction above `_kTetanusThreshold` reward mastery; easy first tap, hard sustained tetanus.
- Pace & climax: 3 — Acceleration is skill-gated only: `_level` climbs every 6 hits (`_kHitsPerLevel`) to tighten window/period, so a missing player stays at level 0 for a flat, climax-free 60s. There is no time-based ramp or final-seconds crescendo independent of performance.
- Polish: 4 — Anatomically rich sarcomere (actin/myosin/Z-discs, cross-bridge ticks), atmosphere motes, junction orb, clean perf via the single-ticker pattern — but the muscle-red palette and copy carry no actual Potatuhs brand identity (no character, no voice).
## Top 2–3 UX failures (concrete, cite the mechanic)
1. **Built solo in a multiplayer rubric.** No pass-and-play turn handoff, no opponent ghost, no shared/comparative standing — only `session.addScore`. In a party context players just squint at a final number.
2. **Tetanus drip is a runaway-leader engine.** `_tetanusAcc += _kTetanusPointsPerSec * dt` (line 153) pays +12/sec continuously once `_contraction >= 0.80`, so a small early lead compounds into an uncatchable one with no rubber-band.
3. **No climax & no audio.** Acceleration only fires if the player is already winning (`_level` gated on `_hits`), so the arc is flat for anyone struggling; combined with a totally silent timing game, the finish has no crescendo and the moment-of-tap has no audible "hit" confirmation.
## Redesign brief — what twitch_v2 MUST change to clear the bar
- Add a competition mode: pass-and-play rounds or a side-by-side opponent force bar with a visible standing, so the score means something against another human.
- Tame the tetanus runaway: cap drip duration, decay the rate the longer it's held, or add a per-second comeback bonus for the trailing player — keep tetanus aspirational, not snowballing.
- Add a time-driven ramp independent of skill (signals speed up in the final ~15s regardless of level) plus a closing-seconds crescendo so every run, even a flubbed one, accelerates to a finish.
- Add audio: a tap-hit click, a "perfect" chime, a miss thud, and a rising tetanus drone — timing games live and die on sound.
- Brand it: a potato motor-neuron / Potatuhs framing or character voice so it reads as HPG, not a generic biology demo.
## Keep (the education + what already works — do not lose)
- The core physiology is correct and must survive: **twitch summation → tetanus is gated on firing RATE** (rapid on-time taps out-pace `_kRelaxRate` to fuse contraction) — this is the real lesson and the central mechanic; do not flatten it into a generic combo.
- The **sliding-filament** visualization: actin anchored at the Z-discs sliding over fixed-length myosin as the sarcomere shortens, Z-discs moving inward, cross-bridge ticks — keep this; it's the textbook diagram made playable.
- The **nerve signal → neuromuscular junction → contraction** causal chain (action potential travels the axon, fires at the junction, muscle above responds) is the spatial story; keep the connector line cueing cause→effect.
- The clean single-Ticker→single-CustomPainter perf budget and the calm "ready" → running → results session edge that resets state on the running boundary (the S).
