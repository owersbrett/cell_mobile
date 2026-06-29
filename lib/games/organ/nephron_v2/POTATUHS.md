# Nephron v2 — POTATUHS.md

**Vertical:** hotpotatogames · **Artifact:** cell_mobile (Explore The Cell).
**Rubric:** GAMES — this module satisfies all five.

| Letter | Criterion | Where |
|--------|-----------|-------|
| **G** | Game — playable widget | `nephron_v2_game.dart` → `NephronV2Game` |
| **A** | Agent assigned | `AGENT.md` |
| **M** | Manual / rules | `GAME.md` |
| **E** | Education | `EDUCATION.md` |
| **S** | Session re-entry | host-owned clock; gates on `session.isRunning`, no `endEarly()` — closes and re-enters cleanly |

## Why this exists
Part of the **UX Refinement Pass** (`docs/UX_REFINEMENT_PASS.md`, Sprint 2). It
is the UX-passed **alternative** to `organ/nephron`, built to its teardown brief
(`docs/ux_pass/teardowns/nephron.md`). Both ship side by side; the judge picks
the keeper, the loser is set `enabled: false` (kept, not deleted).

## Brand fit
On-brand renal palette (blood crimson / urine amber) on the Potatuhs dark theme,
all rendering through `GameFx` (orbs, atmosphere, bursts, pops) so it matches the
rest of the catalog. Perf guardrail honoured: one Ticker → one CustomPainter.

## Two fixes that earned the pass
1. **Affordance** — a genuine drag/flick replaces v1's "flick"-labelled static
   tap. Left/right gestures now actually sort.
2. **Fairness** — the zero-purity `endEarly()` is removed; every player gets the
   full 60 s, so party standings are comparable.
