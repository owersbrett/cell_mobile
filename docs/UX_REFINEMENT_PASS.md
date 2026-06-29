# Goal — UX Refinement Pass (the 41 Four-Per-Scale games)

> **The standard:** the four-per-scale pass proved we can make 41 educational
> games *fast*. This pass makes them **fun** — to the bar of a great multiplayer
> party game. Every one of the 41 gets a **design teardown** and a **UX-passed
> alternative**, organized into **2-week sprints**, worst-first. Some already hit
> hard; even those earn an alternative that's had the pass.

The first pass was graded by a machine (≥4/scale, <80s, education-in-mechanic).
This pass is graded by **feel** — and held honest by a gate that proves every
game got the work.

---

## Why a second pass

Pass 1 ran dozens of agents in parallel against the GAMES rubric. It nailed
*education-in-the-mechanic* and shipped breadth. But "first-draft, built fast"
shows: uneven juice, unclear affordances, runaway scoring, thin skill ceilings,
flat pacing. Pass 2 fixes **feel** without dropping the lesson.

---

## The bar — the Fun-Multiplayer UX rubric (score each 1–5)

1. **Instant legibility** — you grasp what to do in <3s, no reading.
2. **Affordance clarity** — tap vs swipe vs drag is obvious (the Farm Panic
   water-channel lesson: looked tappable, was a swipe).
3. **Juice & feedback** — every action lands with satisfying audio-visual
   feedback, *within* the one-Ticker→CustomPainter perf budget.
4. **Fair & readable competition** — scores are comparable, no runaway leader,
   the standing is legible; it reads in **pass-and-play / party** mode, not just
   solo.
5. **Skill depth** — a real ceiling; easy to learn, hard to master; rewards
   repeat play (the "reflect on prior runs" bar).
6. **Pace & climax** — a tight 45–60s arc that **accelerates** to a satisfying
   finish.
7. **On-brand polish** — Potatuhs look, no jank, perf clean.

> Education is **preserved** — this pass sharpens fun *around* the lesson, never
> at its expense. A teardown that proposes dropping the teaching is wrong.

---

## Per-game deliverable (the unit of work)

For each of the 41 games (ids in `test/games/ux_pass_test.dart` → `kUxPassGames`):

- **A. TEARDOWN** → `docs/ux_pass/teardowns/<id>.md`: the 7-dimension score, the
  **top 2–3 UX failures** named concretely, and a **redesign brief** — what the
  alternative must change to clear the bar.
- **B. ALTERNATIVE** → a refined build wired as **`<id>_v2`**: same education,
  dialed-up fun, self-contained module + GAMES docs, the perf guardrail, <80s.

**Coexist, then judge (default).** The alternative ships **alongside** the
original as a sibling spec, so both are playable and **A/B-comparable** in-app.
After each sprint, a judge (adversarial agent or Brett) picks the keeper per
game; the loser is set `enabled: false` (kept, not deleted). This literally gives
all 41 "an alternative that's had the pass," and never destroys a v1.
*(If we instead choose replace-in-place, the v2 supersedes the original module
and the original is archived — flip this before the redesign sprints.)*

---

## Sprints (2 weeks each, worst-first)

- **Sprint 0 — Teardown & Triage.** Score + critique **all 41**, rank
  **worst-first**, and lock the sprint order. Output: 41 teardown files + a
  ranked `docs/ux_pass/TRIAGE.md`. This is the "break down the design attempts"
  step — done before any rebuild.
- **Sprints 1..N — Redesign.** ~8 games per sprint, in triage order. Per game:
  build the `<id>_v2` alternative to its teardown brief; verify analyze-clean +
  gates. (~5 sprints for 41 games.)

A human checkpoint sits **after Sprint 0**: eyeball the ranking, confirm
coexist-vs-replace, greenlight the redesign sprints.

---

## Completion gate (machine-checkable)

`test/games/ux_pass_test.dart`:
- every `kUxPassGames` id has a **teardown file**, AND
- every id has an **enabled `<id>_v2`** registry spec.
- the four-per-scale gates stay green (≥4/scale, <80s, every registry game in the
  catalog).

When the gate is green → run `/deploy` → end the loop.

---

## The loop

Self-paced. Sprint 0 (grouped teardown agents → ranked plan) → checkpoint →
redesign sprints worst-first (one agent per game builds its `<id>_v2`; orchestrator
wires registry+catalog) → re-run the gate each sprint → on green, deploy, end.
`humanMax`/star thresholds and the judge-pick are post-pass tuning, not gates.
