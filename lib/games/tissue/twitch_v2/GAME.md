# Twitch v2 — GAME.md (Manual · the **M** in GAMES)

**Scale:** Tissue · **Id:** `twitch_v2` · **Duration:** 50s · **Score unit:** force

## Premise
A nerve signal travels down the axon toward your muscle. Tap the instant it
reaches the neuromuscular junction to fire a contraction — the sarcomere's actin
filaments slide over the myosin and the muscle shortens. Fire fast enough and
twitches **summate** into a sustained **tetanus** for bonus force. But hold a
tetanus too long and the muscle **fatigues** — the bonus dwindles and you must
relax to recover.

## Rules
- A glowing signal pulse travels left→right along the nerve. Tap when it enters
  the **strike zone** at the junction. Dead-center = `PERFECT`, more points.
- A **mistimed tap** or **letting a signal pass** wastes it: the muscle relaxes
  and your streak resets (streak multiplier up to 1.8×).
- Cross the **TETANUS** line by stacking fast on-time taps for bonus force — but
  the **fatigue** strip fills as you hold it; the bonus decays to nothing.
- When **FATIGUED**, let the muscle drop and rest to recover, then rebuild.

## Acceleration & climax
Signals speed up on a **time ramp** — everyone accelerates regardless of skill —
plus a **skill ramp** every 5 hits. The last 10 seconds trigger **FINAL BURST**:
fastest cadence, screen pulse, and a 1.5× payout on every hit and on tetanus, so
even a trailing player gets a real comeback window and a distinct finish beat.

## How to win
Most force when the 50 seconds run out. Master the build → hold → release →
recover rhythm to keep tetanus productive instead of fatigued.

## Scoring
- Hit: 9 + up to 13 for timing quality, times the streak multiplier (1.0→1.8×).
- Tetanus drip: up to 20/sec at zero fatigue, decaying to 0 as fatigue fills.
- FINAL BURST: 1.5× on hits and drip in the closing 10 seconds.
- `humanMax` 2000 · stars `[700, 1300, 1800]`.

## Fairness (fixes the v1 runaway)
v1's tetanus paid +12/sec forever, compounding into an uncatchable lead. v2 caps
that with **fatigue** (self-limiting) and a **shared FINAL BURST** comeback —
tetanus stays aspirational, not snowballing.

## Session (the **S**)
Host-owned clock: auto-starts on `isRunning`, calm "ready" state before, results
on finish. Closing and re-entering starts a fresh run (state resets on the
running edge via `_resetRun`).
