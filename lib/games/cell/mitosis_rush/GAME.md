# GAME.md — Mitosis Rush

> The canonical spec. This outranks the code: if we re-implement, this survives.
> **REDESIGN (2026-06-17):** gesture-based, interphase-heavy. The OLD tap/drag version (6 equal
> WarioWare phases) is superseded by everything below. Rules-are-the-asset — build from this.

- **Scale (cell):** cell
- **Game id:** mitosis_rush
- **One-line concept:** Run one continuous cell through the real cell cycle — spend ~90% of your
  time in **Interphase** (the long part), then rip through the 5 mitosis steps in quick single
  gestures. The pacing *is* the lesson: **interphase takes the longest.**
- **Role:** solo high-score
- **Six-in-one?** yes — but deliberately lopsided. Interphase is three sub-stages (G1 · S · G2) and
  ~90% of playtime; the 5 mitosis steps are one quick gesture each.

---

## The core idea (why it's built this way)
The real cell cycle is ~90% interphase. So this game **spends ~90% of its playtime in interphase**
and blasts through mitosis in fast single gestures. The player *feels* the proportion — they learn
"interphase takes the longest" because they lived it. Everything acts on **one continuous cell**
(stretch it, condense it, split it), which also keeps the visuals continuous (no phase-to-phase
teleporting).

**Gesture vocabulary:** reverse-pinch (stretch) · pinch (condense) · draw · lock/key match · scrub ·
slice. All `CustomPainter`, no raster assets.

---

## PART 1 — INTERPHASE (~90% of the game)

### G1 — Grow (reverse-pinch QTE)
- The cell needs to **stretch and grow**. The player does this with a **reverse pinch** (two fingers
  moving apart / inverse pinch).
- It's a **quick-time event**: a prompt shows a **direction axis**, and the player must reverse-pinch
  along it. The four axes cycle:
  1. up ↕ down
  2. left ↔ right
  3. up-right ↗ / bottom-left ↙
  4. up-left ↖ / bottom-right ↘
- **Do as many correct reverse-pinches as you can within the time limit.** Each correct one grows the
  cell a little and scores; wrong-axis or weak pinches don't count.

### S — Synthesis (base-pair matching) — REDESIGNED (drawing removed)
- DNA replication = copying base pairs. A **queue of bases scrolls into view**; for the **next base**,
  **tap its correct complement** from **4 options (A, T, G, C)** — **A↔T, G↔C**.
- Go **as fast as you can**: speed + accuracy scored, streak multiplier; a wrong tap breaks the streak.
- This **replaces** the old "draw two helices" mechanic — drawing was unreliable in testing and is removed.

### G2 — Grow again (reverse-pinch QTE)
- A second **reverse-pinch QTE**, same as G1 (final growth/prep before division). Reinforces that
  interphase is a long, repeated grind.

> Net: G1 → S → G2 is the bulk of the run. This is where most of the score lives.

---

## PART 2 — MITOSIS (the 5 quick steps — one fast gesture each)
Deliberately brief. Each is a single decisive gesture; the speed contrast with interphase is the point.

1. **Prophase — pinch.** A quick-time **pinch** (opposite of the reverse-pinch) to **condense** the
   chromatin into chromosomes.
2. **Metaphase — lock/key.** Match **two distinct sides together like a lock and key** to signal
   **perfect alignment** at the metaphase plate. *(Interpretation to confirm — see open question.)*
3. **Anaphase — reverse-pinch, left→right.** Back to a reverse-pinch, but it **always pulls the two
   halves apart from left to right**, separating the chromatids to opposite poles.
4. **Telophase — scrub.** **Scrub** across the cell (rapid back-and-forth) to show the **spindle
   fibers dissipating** and the nuclei reforming.
5. **Cytokinesis — slice.** A final **up-down or down-up slice** to split the cell into two.

---

## Open question (confirm before build)
The "lock/key perfect alignment" gesture: I've placed it as **Metaphase** (alignment at the plate),
making the 5 steps = Prophase(pinch) · Metaphase(lock/key) · Anaphase(reverse-pinch L→R) ·
Telophase(scrub) · Cytokinesis(slice). If you meant lock/key to be part of Prophase, the count/order
shifts — confirm.

---

## Scoring (framework — tune on build)
- **Interphase carries the score** (it's 90% of play):
  - G1/G2: points per correct reverse-pinch; reward volume within the time limit.
  - S phase: `curves × base` + **match-quality multiplier** for the two helices.
- **Mitosis steps:** small, fast points each (they're quick) — a clean gesture scores, a sloppy one
  scores less. The 5 together should be a minority of the total, reinforcing the proportion.
- Optional combo/multiplier carrying from a strong interphase into the mitosis sprint.

## Win / end condition
Solo score attack — ends after Cytokinesis (the slice) → Results screen → restart.

## Difficulty curve
Within interphase: G1→S→G2 escalate (faster QTE prompts, tighter helix match tolerance). The mitosis
sprint is intentionally not a difficulty ramp — it's a fast, satisfying payoff.

## Educational blocks engaged
- **The pacing teaches the headline fact: interphase (G1/S/G2) is ~90% of the cell cycle.**
- G1/G2 → cell growth; S → DNA replication (the two helices); the 5 steps → the real mitosis order.
- Mechanic = concept throughout (you *perform* replication, condensation, separation, division).

## Potato angle
Every cell in a potato tuber got there by mitosis — a growing stolon tip is running this loop
millions of times. A brief potato-context card per stage ("S PHASE — copying the DNA in every
growing cell of your potato") closes the loop, same flare pattern as Atom Builder.

## Session / resume
Self-contained today. If hosted: persist current stage (G1/S/G2 or mitosis step), stage timer,
score, and per-stage progress. Effects are ephemeral.

## Implementation status
The current `MitosisRushGame` (`lib/views/screens/mini_game_page/games/mitosis_rush_game.dart`) is
the OLD tap/drag version with four disconnected genetic-material types
(`_ChromatinBlob`/`_Chromosome`/`_ChromatidPair`/`_Nucleus`) — the root of the visual-continuity
problem. This redesign replaces that: **one continuous cell object** transformed by gestures across
all stages. Build from this spec; reuse the phase-timer/results scaffold only.
