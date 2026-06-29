# Tissue Type — GAME.md (the Manual, M in GAMES)

**Scale:** `BioScale.tissue`
**Id:** `tissue_type` · **Duration:** 60s · **Score unit:** points

## Premise
A stained histology "slide" is drawn under a virtual microscope. Read its
**morphology** and classify the sample as one of the four PRIMARY tissue types.
All samples use the same H&E-style stain colours on purpose — you must read
**shape**, not colour.

## The four answers
- **EPITHELIAL** — cells packed edge-to-edge into continuous sheets / linings.
- **CONNECTIVE** — few cells scattered far apart in a big matrix (bone / blood / fat).
- **MUSCLE** — long parallel fibres built to contract.
- **NERVOUS** — star-shaped cell bodies trailing branching processes.

## Rules
- Tap the tissue type that matches the slide.
- **Faster = more points.** A correct answer's value decays from 130 down to a
  25-point floor over a window that shrinks as the round speeds up.
- **Streak multiplier.** Every 3 consecutive correct calls adds +1× (×2 at 3,
  ×3 at 6, …). A wrong answer or a timeout resets the streak.
- **Per-sample deadline.** A bar drains across the top of the slide. Let it
  empty and the sample is marked wrong, the answer is revealed, and play moves on.
- **Fact card.** Every answer reveals the exact subtype + a one-line fact. Tap
  to continue immediately.

## Acceleration
As you answer more samples the tells get **subtler** (fainter membranes, looser
packing, fewer striations) and the **deadline shrinks** from 7s toward 3s.

## How to win
Most points when the 60-second timer runs out wins.

## Scoring reference
- `humanMax`: 4200 · `starThresholds`: [1400, 2800, 4000]
- Base correct: 25–130 (speed) × streak multiplier.

## Session (S in GAMES)
The host owns the clock and the results screen. The widget never calls
`endEarly`; it only reads `session.isRunning` / `session.remaining` and reports
through `addScore` / `noteStreak`. When the round ends the host shows results;
a fresh round re-enters cleanly with a reshuffled deck and reset difficulty.
