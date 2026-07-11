# Twitch — GAME.md (Manual · the **M** in GAMES)

**Scale:** Tissue · **Id:** `twitch` · **Duration:** 60s · **Score unit:** force

## Premise
A motor neuron fires an impulse. It races down the axon from the **SOURCE** (the
neuron soma) to the **TARGET** (the neuromuscular junction on a muscle). Tap the
target the instant the impulse lands to fire a contraction — the muscle twitches.
Real reflexes never fire from the same place twice, so the game doesn't either:
every clean reflex the source and target **jump** and the arc gets faster and
tighter. After ten clean reflexes the muscle is out of fuel — **NOW EAT PROTEIN!**

## The reflex arc (main loop)
- An impulse launches from the SOURCE and travels the axon toward the TARGET. A
  **strike ring** around the target contracts as the impulse approaches.
- **Tap the target** the instant the impulse lands (inside the timing window —
  the ring is green then). Dead-center timing scores most; a near-perfect tap
  reads `PERFECT`.
- **Miss:** tapping too early/late, tapping the wrong spot, or letting the
  impulse sail past unanswered — the reflex is wasted and your streak resets.
- On a clean hit the muscle visibly twitches, you score, and the **next impulse
  launches from a new source to a new target**.

## Escalation (harder EVERY click — Brett #31)
Difficulty is recomputed on every successful reflex, not on fixed levels:
- **Faster** — the impulse's travel time shrinks (× per hit) toward a hard floor.
- **Tighter** — the timing window narrows.
- **Smaller** — the tappable target shrinks.
- **Less warning** — the pause before each impulse gets shorter.
- **It moves** — source and target teleport unpredictably (kept apart), so you
  can never settle into one rhythm or one spot (Brett #19).

## The PROTEIN phase (Brett #31)
Every **10** clean reflexes the muscle demands fuel: the banner reads
**NOW EAT PROTEIN!** and a spread of dishes appears. **Rapid-tap the dishes**
for ~4.5s to gather protein (+14 each, dishes respawn so there's always one to
hit). When the timer runs out you return to the reflex arc — one cycle harder
than before (each completed protein cycle bumps the escalation floor).

## How to win
Most force when the 60 seconds run out. Chain clean reflexes for the streak
multiplier and clear the protein spreads fast — both feed the same score.

## Scoring
- Clean reflex: base 12 + up to 18 for timing quality, × streak multiplier
  (1.0 → 2.2×).
- Protein dish: +14 each while the spread is up.
- `humanMax` 3200 · stars `[1100, 2100, 3000]`.

## Session (the **S**)
Host-owned clock: auto-starts on `isRunning`, calm "ready" state before, results
on finish. Closing and re-entering starts a fresh run — all reflex/protein state
resets on the not-running → running edge (`_resetRun`).
