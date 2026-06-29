# body_map — UX Teardown
scale: organ · duration: 60s · scoreUnit: points

## Scores (1–5)  → TOTAL: 26/35
- Instant legibility: 4 — A human silhouette, one organ token bobbing up from the staging slot with its name, and "Drag each organ to where it lives." Drag-to-place is graspable in <3s, and rounds 1–2 show a pulsing ghost target ring (`_showGhost`) so the very first action is guided.
- Affordance clarity: 4 — Grab-and-drag the active token (`_onPanStart` within `_organR + 34`, `_onPanUpdate`, `_onPanEnd`), one organ at a time so there's no ambiguity about what you're moving. Wrong drop bounces back visibly (`_bounce`).
- Juice & feedback: 4 — `FxBurst` + `FxPop('+$pts')` on a correct snap, `_wrongFlash` red wash + "Not there" pop on a miss, easeOutBack pop-in scale for placed organs, and a PERFECT BODY / BODY MAPPED round banner. Drawn by one `_BodyMapPainter`. Note: `_tick` does a per-frame `setState` over the tree (the painter is the only heavy child, so acceptable).
- Fair/readable competition: 4 — `30 + speedBonus(≤30) + accBonus(≤20) + streakBonus` plus round bonuses; comparable and bounded, with a small −5 miss. Spatial recall is more universally intuitive than the histology/renal knowledge games, narrowing the knowledge gap. Reads well in pass-and-play.
- Skill depth: 3 — Fixed set of 12 organs at fixed positions (`_kOrgans`); once you've learned where they live it becomes drag speed + drop accuracy. The tier knobs (more organs, faster fly-in, tighter `_tolFrac`, ghost removed at tier 2) add pressure but not new decisions.
- Pace & climax: 3 — It accelerates well via `_tier` (4→12 organs, fly-in 1.1→0.45s, zones 0.15→0.075). But pace is throttled by the one-at-a-time gating (you wait for each `_spawnNext` fly-in) and a 1.4s between-round celebration pause (`_roundClearT`), so it's a series of bursts rather than a continuous build.
- Polish: 4 — Procedural silhouette with arms/legs for orientation, radial-gradient organ tokens, ghost rings, on-brand anatomical red. `shouldRepaint => true`, light scene.

## Top 2–3 UX failures (concrete, cite the mechanic)
1. Throttled tempo: serial single-organ placement plus the 1.4s `_roundClearT` pause caps how frantic/climactic it can get; even at tier 8 the 0.45s fly-in sets a ceiling on actions/second.
2. Knowledge-then-rote ceiling: 12 fixed positions means after a few runs the challenge is memorized and only motor speed remains — thin reason to chase a high score repeatedly.
3. Left/right paired organs (lungL/lungR, kidneyL/kidneyR) at tight late `_tolFrac` become a fiddly accuracy test more than an anatomy test, which can read as fussy rather than fun.

## Redesign brief — what body_map_v2 MUST change
- Lift the tempo ceiling: allow a short queue / multiple organs in flight, or let a confident player place faster without waiting on the fly-in, and shorten the between-round freeze so it builds to a buzzer.
- Add a decision axis beyond position recall: e.g. a "which organ does this job?" twist, mismatched decoys, or a function tag to place, so depth grows past pure spatial memory.
- Rethink paired-organ accuracy so tight zones test anatomy, not pixel-precision (snap to side, reward correct side over exact center).
- Keep the ghost-ring → recall fade as the learn-to-master spine.

## Keep (education + what works)
- The core lesson — WHERE the major organs sit in the body — is taught purely by doing, and the ghost-ring (learn) → no-ring (recall) progression is a clean scaffolding pattern. Preserve it.
- Landmark-first organ order (`_kOrgans` big organs first) is good pedagogy; keep.
- The silhouette + gradient tokens are tidy and on-brand; reuse the rendering.
