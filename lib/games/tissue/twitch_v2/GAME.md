# Twitch v2 — GAME.md (Manual · the **M** in GAMES)

**Scale:** Tissue · **Id:** `twitch_v2` · **Duration:** 50s · **Score unit:** force

> v2 is the **tighter** cut of Twitch: the same reflex-arc + protein spine, tuned
> faster and less forgiving, with haptics. Same rules as `twitch/GAME.md` — the
> numbers below are what differs.

## Premise
A motor neuron fires an impulse down the axon from the **SOURCE** (neuron soma)
to the **TARGET** (neuromuscular junction). Tap the target the instant the
impulse lands to fire a contraction. Every clean reflex the source and target
**jump** and the arc gets faster and tighter. After eight clean reflexes:
**NOW EAT PROTEIN!**

## The reflex arc (main loop)
Identical to base Twitch: an impulse travels SOURCE → TARGET; a contracting
strike ring shows the timing window; tap the target on landing for a clean
reflex. Miss (off-time / wrong spot / let it pass) resets the streak. Each clean
hit twitches the muscle and re-launches from a new source to a new target.

## Escalation (v2 — steeper)
Recomputed on every hit: faster travel (floor 0.38s vs 0.42s in base), tighter
window (floor 0.075 vs 0.085), smaller target, and shorter warning. Each
completed protein cycle adds **4** escalation steps (base adds 3) — v2 ramps
harder between fuel stops.

## The PROTEIN phase
Every **8** clean reflexes → **NOW EAT PROTEIN!** A spread of dishes appears;
rapid-tap them for ~4s (+16 each, dishes respawn). On timeout, back to the arc,
one cycle harder.

## How to win
Most force when the 50 seconds run out. Chain clean reflexes for the streak
multiplier; clear the protein spreads fast.

## Scoring
- Clean reflex: base 12 + up to 18 for timing quality, × streak multiplier
  (1.0 → 2.2×).
- Protein dish: +16 each.
- `humanMax` 2000 · stars `[700, 1300, 1800]`.

## Session (the **S**)
Host-owned clock: auto-starts on `isRunning`, calm "ready" state before, results
on finish. Fresh run resets all state on the not-running → running edge.
