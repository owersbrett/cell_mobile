# circulate — UX Teardown
scale: organSystem · duration: 50s · scoreUnit: deliveries

## Scores (1–5)  → TOTAL: 23/35
- Instant legibility: 3 — A central pumping heart, a lungs node, and organs with O₂ ring gauges, plus "Route red blood to low organs — recharge blue at the lungs." The triage idea (feed the flashing organs) reads, but the *coupling* — that every delivery spends a shared reserve you must refill at the lungs — isn't visible until you run dry and get "Out of O₂." First-contact understanding is partial.
- Affordance clarity: 3 — Tap an organ to deliver, tap the lungs to recharge (`_onTap` with distance thresholds). Clear tap targets, but two tap-meanings on the same field with no persistent legend; the reserve gauge beside the heart is small and easy to miss as the governing resource.
- Juice & feedback: 4 — `FxBurst` + `FxPop('+points')`, banners ('Recharged', 'X starved — O₂ gone!'), a heart that pumps on `_heartBeat` and lerps red↔blue with the reserve, alarm halos + LOW O₂/STARVED labels on dying organs, blood pulses travelling the vessels. One Ticker → one `_CirculatePainter`.
- Fair/readable competition: 3 — `6 + up to 18` for rescuing a near-empty organ (rewards triage), streak resets on a starve. Comparable and bounded; importantly it does NOT end early when an organ starves (the run rides the full 50s), so standings stay fair — better than nephron on this axis. Reads OK in pass-and-play.
- Skill depth: 3 — There's real resource management here: balance delivery vs recharge, prioritise the lowest organs (worth more), and time recharges before demand spikes as organs scale 3→6 and demand ramps ~1.9×. The deepest of the organ-system pair, but still a fairly simple triage loop.
- Pace & climax: 3 — Accelerates via added organs (`_nextOrgan` every 12s) and climbing `demand`, so the late game forces faster cycles. 50s is tight. The build is steady rather than sharply climactic.
- Polish: 4 — Clean arteries + pulmonary vessel, travelling blood pulses, per-organ ring gauges, reserve bar, on-brand crimson. `shouldRepaint => true`, light scene.

## Top 2–3 UX failures (concrete, cite the mechanic)
1. Hidden core coupling: the delivery↔reserve↔recharge economy is the whole game but is invisible until failure (`_routeDelivery` only flags "recharge at the lungs" when `_reserve < _deliverCost`). New players spam deliveries, hit empty, and only then learn the rule.
2. Two-meaning tap with weak signposting: organ-tap vs lung-tap share the field and the reserve gauge that explains *why* you'd ever tap the lungs is a tiny bar — the strategic loop is under-communicated.
3. Steady, not climactic: demand ramps smoothly but there's no escalating stake or buzzer-beat crescendo; it can plateau into rote triage.

## Redesign brief — what circulate_v2 MUST change
- Make the economy visible from second one: foreground the reserve as the hero gauge, show the cost of each delivery and the "you must recharge" loop *before* the player fails — teach the systemic↔pulmonary dependency through anticipation, not punishment.
- Sharpen the two actions: stronger, persistent affordance for "deliver" vs "recharge" (distinct visual language / prompts) so the lungs are obviously the refuel, not just another node.
- Add a climax: a late demand surge or a multi-organ crisis that forces a tense delivery/recharge sequence into the final seconds.
- Deepen triage stakes (e.g. chained rescues, organs that crash faster) so mastery compounds.

## Keep (education + what works)
- The two-loop lesson is the point and it's literal: systemic (heart→arteries→organs, red, O₂ out) vs pulmonary (organs→veins→heart→lungs, blue, recharge), and you *cannot deliver without returning blood to the lungs* — exactly the body's constraint. Preserve it.
- Reserve colour lerping red↔blue with oxygen state (`Color.lerp(_deoxy, _oxy, _reserve)`) teaches oxygenation viscerally; keep.
- Rescue-scaled scoring (lower organ = more points) correctly trains triage; keep. And keep the no-early-end fairness.
