# nephron — UX Teardown
scale: organ · duration: 60s · scoreUnit: molecules

## Scores (1–5)  → TOTAL: 22/35
- Instant legibility: 3 — Central tubule with labeled BLOOD (left) and URINE (right) gutters, molecules falling, ready overlay explaining the sort. The binary left/right decision is graspable, but WHICH way each molecule goes depends on reading its label and knowing renal physiology, so the scored decision isn't legible in <3s.
- Affordance clarity: 2 — The big trap: the rules and ready text say "FLICK LEFT / FLICK RIGHT," but the code is a positional TAP — `_onTapDown` routes by `p.dx < best.pos.dx ? -1 : 1`. There is no swipe/flick detection at all. This is exactly the Farm-Panic "looked like a swipe, was a tap" failure, inverted: it's told as a flick but is a side-tap. Players will swipe and get confused.
- Juice & feedback: 4 — `FxBurst` + `FxPop` per call, distinct pops ('+gain', 'WASTE IN BLOOD', 'NUTRIENT LOST', 'LOST'), zip-to-gutter animation, red/green screen flashes, a BLOOD PURITY bar that lerps colour with health. One Ticker → one `_NephronPainter` with `shouldRepaint => false` (repaints via `_RepaintNotifier`) — perf-clean.
- Fair/readable competition: 3 — `10 × streak mult` (cap ×3), asymmetric penalties (keep-waste −15/−0.22 purity is harshest). But health hitting zero calls `session.endEarly()` — a fail-out that ends the run before 60s, so a struggling player gets *less time on the clock* than a strong one, widening the gap unfairly in a party setting. Standing otherwise legible.
- Skill depth: 3 — Real escalation: more molecule types by level and the subtle Na⁺ vs "Sodium · EXCESS" identical-glyph call (`_subtleL3`) that forces label-reading, mirroring how the kidney discriminates surplus from need. Good idea, but the core verb stays a binary sort.
- Pace & climax: 3 — Flow speed (`_kFallEarly→_kFallPeak`), spawn rate, and subtlety all ramp with elapsed time → it accelerates. But the early-end fail (`_health <= 0`) can truncate the climax instead of building to the buzzer.
- Polish: 4 — Coiled glomerulus, flowing plasma stripes, gutter flow streaks, urgency rings near the exit. On-brand renal palette (blood crimson / urine amber).

## Top 2–3 UX failures (concrete, cite the mechanic)
1. Affordance mismatch: "flick" copy over a position-tap implementation (`_onTapDown`, no gesture velocity) — players will attempt swipes and misfire. Either make it a real flick or stop calling it one.
2. Fail-out asymmetry: `endEarly()` on zero purity gives weaker players a shorter run, which is a fairness inversion in a comparable-score party game.
3. Knowledge-gated scoring: the good/waste call is pure biology recall (which is the lesson) but there's no in-mechanic scaffolding for a first-timer — early molecules aren't visibly tagged friend/foe before the penalty lands.

## Redesign brief — what nephron_v2 MUST change
- Resolve the gesture: implement a genuine flick (drag with direction/velocity) OR rewrite copy + ready overlay to "TAP LEFT side / TAP RIGHT side" and add a clear left/right tap hint on the molecule itself.
- Remove or soften the early-end: keep blood purity as a score/streak modifier and a tension gauge, but let every player ride the full 60s so standings are comparable.
- Scaffold the call: early-game, gently colour-code or icon nutrients vs waste so a newcomer learns the categories, then strip the tell as the level climbs (the EXCESS twist is the right end state).
- Make the accelerate climb to a buzzer, not a clog-out.

## Keep (education + what works)
- The core lesson is sharp and must survive: the tubule default is "everything exits in urine," and *reabsorption is the active, selective step* — doing nothing sends a molecule to urine (correct for waste, wrong for a nutrient). That asymmetry is the whole kidney in one rule.
- The Na⁺ vs Na⁺·EXCESS identical-appearance call is a clever, accurate depth mechanic — keep it as the top of the ramp.
- Glomerulus + tubule + dual-gutter staging reads as a real nephron; keep the anatomy framing.
