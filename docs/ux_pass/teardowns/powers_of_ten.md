# powers_of_ten — UX Teardown
scale: universeAll · duration: 50s · scoreUnit: precision
## Scores (1–5)  → TOTAL: 23/35
- Instant legibility: 3 — A vertical 10ⁿ ladder, a named thing with a glyph, and "drag onto the ladder · release to drop" is followable, but the task requires understanding *logarithmic orders of magnitude* — inherently abstract. The faint anchors (atom/human/Earth/galaxy) scaffold it, yet the first read still demands reasoning, not reflex.
- Affordance clarity: 3 — Drag vertical, release to drop (`onPanUpdate:_move` / `onPanEnd:_release`), with tap-to-place fallback. Forgiving (any vertical position sets the marker), but it's not obvious *what* you grab — the marker rides at w*0.42 while the ladder is at w*0.30, so the relationship between finger, marker and spine takes a beat to learn.
- Juice & feedback: 4 — Excellent didactic feedback: the ✓ truth marker *slides* from your drop to the real magnitude (`yTrue` lerp), the gap is drawn as an error band, and the real value + a one-line fact reveal. `FxBurst`/`FxPop` on good drops. The slide-to-truth is the standout.
- Fair/readable competition: 4 — Deterministic precision scoring (`accuracy = 1 − error/band`), no luck, fully comparable. Knowledge-gated (you guess if you don't know a muon's lifetime) but fair, and the score reads cleanly.
- Skill depth: 3 — Real estimation/interpolation skill against tightening tolerances (`_perfectTol` 0.5→0.22). But the item pools are finite and fixed (≈18 size / 13 mass / 12 time), so repeat play shades from estimation toward memorization — the ceiling is capped by the catalog.
- Pace & climax: 2 — Stop-start cadence: drag → drop → watch a 0.6–1.05s reveal → next. Difficulty tightens but the *rhythm* never accelerates moment-to-moment, and there's no finish spike. It plays like a steady quiz, not a 45–60s building arc.
- Polish: 4 — Clean ladder, decade gridlines, superscript 10ⁿ labels, anchor scaffolding that hides near the answer, elegant slide-to-truth. Single painter, `repaint:_ctrl`. Looks scientific and intentional.
## Top 2–3 UX failures (cite the mechanic)
1. **Stop-start pacing, no climax.** The `_Local.placing → revealing` loop inserts a reveal hold after every item; the round is a sequence of discrete quiz beats with no acceleration toward a peak, missing the rubric's tight building arc.
2. **Memorization ceiling.** Fixed `_sizeItems`/`_massItems`/`_timeItems` pools mean a returning player recalls answers rather than estimating; skill depth plateaus once the catalog is learned.
3. **Grab ambiguity.** The marker (w*0.42) is detached from the ladder spine (w*0.30) and any vertical drag moves it; first-timers aren't sure what they're manipulating until the guide line connects them.
## Redesign brief — what powers_of_ten_v2 MUST change
- **Add a continuous, accelerating spine**: a per-item timer that shrinks, or a ladder that scrolls/zooms so placements come faster and the last 10s force snap estimates — turn the quiz cadence into a building arc with a climax.
- **Beat memorization with procedural variety**: generate items or randomize values within a category (e.g. "this star is N× the Sun") so the *reasoning* (interpolate between anchors) is always required, not recall of a fixed list.
- **Tighten the grab**: anchor the dragged marker to the ladder so finger→marker→truth is one visual line from the first frame, improving instant legibility.
## Keep (education + what works)
- The lesson is the mechanic: you interpolate between known anchors on a log scale, then the reveal shows the true magnitude, the real value, and a fact — every drop teaches *where a thing sits* from quark to cosmos. Preserve the reveal-with-fact.
- Keep the slide-to-truth error band — it's the clearest "here's how wrong you were and why" feedback in the set.
- Keep size→mass→time rotation and tier escalation; the breadth across quantities is genuinely educational. Keep the deterministic, luck-free precision scoring.
