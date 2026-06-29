# skin_layers — UX Teardown
scale: tissue · duration: 60s · scoreUnit: layers

## Scores (1–5)  → TOTAL: 21/35
- Instant legibility: 2 — You can't grasp the goal in <3s. The header reads "STACK THE SKIN — SURFACE ON TOP, DEEP AT THE BOTTOM" and every tray pill shows only an abbreviation (CORN/GRAN/SPIN). To act you must read each tile, recall its anatomical depth, and know the canonical stratum order. It's a knowledge puzzle wearing a drag UI.
- Affordance clarity: 3 — Drag-tile-into-empty-slot is clear (visible bands + tray, `_onPanStart/_onPanEnd`), but tap is overloaded: `_onTapUp` removes a *placed* tile yet on a tray tile only flashes the role card. Two meanings for one gesture is a learnability tax, and the role-card teaching gesture is undiscoverable.
- Juice & feedback: 4 — Solid: `FxBurst.spawn` + `FxPop('+$pts')` on placement, `_wrongFlash` red wash, teal/red boundary lines marking the break (`_drawBoundaries`), and the "SKIN ALIVE" come-alive phase with rising sweat particles and a pulsing stack. One Ticker → one `_SkinPainter`. Within budget.
- Fair/readable competition: 3 — scoreUnit is "layers" but it actually banks points (`15 + streak*2`, completion `40 + level*12 + speedBonus`). The dominant variable is prior anatomy knowledge, so an informed player runs away while a novice stalls — a knowledge-gap runaway, not a skill ladder. Standing is legible via host HUD; pass-and-play works but turns are slow.
- Skill depth: 3 — The depth order is FIXED, so after a couple of plays the puzzle is "solved knowledge" and only placement speed remains. Deeper sections (4→7 bands) add length, not new decisions.
- Pace & climax: 2 — No accelerating arc. Each section is a fresh static sort, and `_completeSection` forces a 1.6s `_aliveDur` celebration pause (`_Phase.alive`) that hard-stops flow between every section. It reads as a worksheet with confetti, not a 45–60s climb.
- Polish: 4 — Clean: SURFACE→DEEP guide ribbon, numbered slot badges, depth-ordered boundaries, warm dermis palette, emoji+label tiles. `shouldRepaint => true` every frame but the scene is light. Tray can get cramped at 7 pills.

## Top 2–3 UX failures (concrete, cite the mechanic)
1. Legibility wall: the whole challenge is recalling stratum depth order from abbreviated pills — there's no in-mechanic *teaching of the order* before you're scored on it (the role card is tap-gated and easy to miss). A first-timer with no histology can't start.
2. Forced dead air: `_aliveDur = 1.6` pause after each `_completeSection` plus the per-section restart kills the accelerating tension a party game needs.
3. Gesture overload: tap = "remove placed tile" OR "read role" depending on tile state (`_onTapUp`), so the educational tap is invisible and accidental removals happen.

## Redesign brief — what skin_layers_v2 MUST change
- Replace the static memory-sort with a *flowing* mechanic: layers scroll/rise and you slot them on a moving cadence so there's a real accelerating arc, no 1.6s freeze between sections.
- Teach the order in the mechanic: surface a live "where does this go?" hint (a glowing target band that fades as you improve), so a novice can play immediately and the ceiling becomes speed/recall, not pre-existing knowledge.
- Split the gestures: drag to place, a dedicated always-visible info affordance to read the role (never overload tap with remove).
- Make scoring read as "layers" honestly, or rename the unit; tie the streak to a visible escalating tempo.

## Keep (education + what works)
- The core lesson is excellent and must survive: skin is a NAMED, depth-ordered stack (Corneum→Granulosum→Spinosum→Basale, papillary/reticular dermis, hypodermis) with each layer's role one tap away. The red-boundary "this is where the order breaks" feedback is a genuinely good teaching signal — keep it.
- The come-alive payoff (sweat beads, pulse) is on-brand delight; keep the reward, drop the forced pause length.
