# Body Map v2 — POTATUHS.md

**Vertical:** hotpotatogames · **Artifact:** cell_mobile (Explore The Cell).
**Rubric:** GAMES — this module satisfies all five.

| Letter | Criterion | Where |
|--------|-----------|-------|
| **G** | Game — playable widget | `body_map_v2_game.dart` → `BodyMapV2Game` |
| **A** | Agent assigned | `AGENT.md` |
| **M** | Manual / rules | `GAME.md` |
| **E** | Education | `EDUCATION.md` |
| **S** | Session re-entry | host-owned clock; gates on `session.isRunning`, no `endEarly()` — closes and re-enters cleanly |

## Why this exists
Part of the **UX Refinement Pass** (`docs/ux_pass/teardowns/body_map.md`). It is
the UX-passed **alternative** to `organ/body_map`, built to its teardown brief.
Both ship side by side; the judge picks the keeper, the loser is set
`enabled: false` (kept, not deleted).

## Brand fit
On-brand anatomical palette (silhouette in warm white, anatomical red accent,
gold for the high-value JOB tokens and streak) on the Potatuhs dark theme, all
rendering through `GameFx` (atmosphere, orbs, bursts, pops). Perf guardrail
honoured: one Ticker → one CustomPainter (repaint notifier, painter reads state
by reference).

## The fixes that earned the pass
1. **Tempo** — the one-at-a-time fly-in and 1.4 s round freeze are replaced by a
   continuous tray of up to 4–5 organs, so a confident player chains placements
   and the run builds to a buzzer instead of stop-start bursts.
2. **Skill past recall** — JOB tokens (function → organ → location, ×1.5) and
   tray triage under decay add a genuine decision/risk axis over pure position
   memory.
3. **Fair paired organs** — generous side/region zones reward the correct side,
   not pixel precision; no negatives, bounded ×4 multiplier, no early-out, so
   party standings stay comparable.
