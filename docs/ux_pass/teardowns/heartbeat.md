# heartbeat — UX Teardown
scale: organ · duration: 60s · scoreUnit: pumps

## Scores (1–5)  → TOTAL: 27/35
- Instant legibility: 3 — A ring of six labeled nodes, a thumping center heart, a shrinking approach ring on the active node, and a "NEXT → Right Ventricle" strip. The rhythm read is clear, but you're asked to track TWO rules at once on first contact — tap the *correct next* node AND on the beat — which isn't graspable in <3s without the ready hint.
- Affordance clarity: 4 — Tap nodes, generous hit radius (`geo.nodeR * 1.7`). The active node has a white rim + approach ring telling you where and the closing ring tells you when. Clean single-gesture.
- Juice & feedback: 5 — Best in this batch: `FxBurst` scaled by perfect/clean, `FxPop('+$pts')`, `_beatFlash`, `_missFlash` red wash, `_perfectFlash` gold, CYCLE/PERFECT/OXYGENATED banners, a center heart that pulses on `_beatPulse`, live BPM + 🔥streak. One Ticker → one `_HeartPainter`.
- Fair/readable competition: 4 — `12 + min(streak,12)`, +8 perfect, +40 cycle. The streak→BPM→window loop is genuinely well-tuned for fairness: a stall hard-resets to 64 BPM (`_stall`), so no runaway and the lead is always re-earnable. Scores comparable, standing legible, pass-and-play clean (`_resetRun` on the not-running→running edge).
- Skill depth: 3 — The order is a FIXED six-step loop (Body→RA→RV→Lungs→LA→LV) memorized in one play, so the only real skill axis is timing precision under the tightening window. Good timing ceiling, but a single dimension.
- Pace & climax: 4 — The streak→BPM ramp (64→176, window 0.22→0.09) is a real accelerating arc and the BPM readout sells it. The one drag: a stall collapses BPM to resting instantly, so a mistake near the end deflates the climax rather than the clock building it.
- Polish: 4 — Heart path, blood-tinted pipes with direction chevrons, pulmonary/systemic halves, calm idle thump (`_kIdleBpm`). On-brand cardinal red. `shouldRepaint => true` but scene is light.

## Top 2–3 UX failures (concrete, cite the mechanic)
1. Two-axis first-contact load: "right node AND right beat" is two rules before you've scored once; a wrong-node tap and a mistimed tap both just say WRONG WAY/TOO LATE without easing you in.
2. Fixed-order shallowness: once the loop is memorized, the node-selection skill evaporates and it's a one-button rhythm game with extra steps — limited reason to chase mastery across runs.
3. Punitive ramp reset: `_stall` dropping BPM straight to 64 means the accelerating tension you built is erased by one slip, which can feel flat/yo-yo rather than climactic in the final seconds.

## Redesign brief — what heartbeat_v2 MUST change
- Decouple the learning curve: let the order be near-automatic (highlight strongly) early, then make TIMING the escalating skill — or add a second timing axis (e.g. valve open/close sub-beats) so depth grows past "memorize 6 nodes."
- Soften the ramp reset so a late mistake costs a step, not the whole built-up BPM, keeping the climax intact into the buzzer.
- Add a risk/reward layer to deepen replay (e.g. optional double-time pumps for bonus) so mastery has somewhere to go.
- Keep the dual-rule but scaffold it: first cycle could grade order-only, then layer timing.

## Keep (education + what works)
- The win condition IS the circulation path — you literally cannot score out of order — which is the strongest education-in-mechanic of the seven. Preserve it exactly.
- Blue→red at the lungs and red→blue at the body (pulmonary vs systemic halves of the tinted ring) teaches oxygenation viscerally. Keep.
- The self-balancing streak→BPM→window loop is excellent competition design; reuse it, just tune the reset.
