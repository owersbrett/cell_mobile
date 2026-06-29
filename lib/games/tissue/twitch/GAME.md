# Twitch — GAME.md (Manual · the **M** in GAMES)

**Scale:** Tissue · **Id:** `twitch` · **Duration:** 60s · **Score unit:** force

## Premise
A nerve signal travels down the axon toward your muscle. Tap the instant it reaches
the neuromuscular junction to fire a contraction — the sarcomere's actin filaments
slide over the myosin and the muscle shortens. Time it well and twitches **summate**
into a sustained **tetanus** for bonus force.

## Rules
- A glowing signal pulse travels left→right along the nerve. Tap when it enters the
  **strike zone** at the junction.
- **On-time tap** fires a contraction: the muscle shortens, you score, and your
  streak grows (streak multiplier up to 2.4×). The closer to dead-center, the more
  points — a near-perfect hit reads `PERFECT`.
- **Mistimed tap** (too early/late) or **letting a signal pass untapped** wastes the
  signal: the muscle relaxes and your streak resets.
- Fire fast enough that contractions stack before they relax and you cross the
  **TETANUS** line — sustained contraction drips bonus force every second you hold it.

## Acceleration
Every 6 successful contractions raises the level (max 10). Each level shortens the
signal period (faster cadence) and tightens the strike window. Late game is a
tight, fast rhythm.

## How to win
Most force when the 60 seconds run out. Sustained tetanus is the fastest way to
climb — chain perfect taps to keep the muscle fused at high force.

## Scoring
- Hit base 10 + up to 15 for timing quality, times the streak multiplier (1.0 → 2.4×).
- Tetanus drip: +12/sec while contraction is held above the threshold.
- `humanMax` 3200 · stars `[1100, 2100, 3000]`.

## Session (the **S**)
Host-owned clock: auto-starts on `isRunning`, calm "ready" state before, results on
finish. Closing and re-entering starts a fresh run (state resets on the running edge).
