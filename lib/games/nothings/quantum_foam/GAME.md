# Quantum Foam — GAME.md (the Manual)

**Scale:** Nothings · **Verb:** REACT / tap-pairs · **Id:** `quantum_foam`

## Premise
"Nothing" is never empty. The quantum vacuum seethes: borrowing energy from the
uncertainty principle, virtual particle–antiparticle **pairs** flicker into
existence, drift apart for a borrowed lifetime, then **annihilate** back to the
void. You are an observer harvesting that borrowed energy before it vanishes.

## How to play
- **Tap a flickering pair while it is alive** to "observe" it and harvest its
  borrowed energy. A pair is two orbs (violet `+` particle, cyan `–`
  antiparticle) joined by a faint filament. Tap anywhere on/between them.
- **Let pairs annihilate untouched — that is free.** A missed pair costs you
  nothing; it simply returns to the void.
- **Do NOT tap a stable, gold REAL particle.** It is steady (not flickering) and
  ringed. Tapping it is a measurement error: **−20** and your streak resets.

## Scoring
- **Score = energy harvested**, in `eV`.
- **Energy–time tradeoff (the catch):** a pair's energy is *inversely
  proportional to its lifetime*. Short-lived pairs are worth **more** but blink
  out faster; long-lived pairs are worth less but are easy. Values run ~5–90.
- **Streak bonus:** 3+ harvests in a row add a small escalating bonus per pair.
  Tapping a real particle (or, by the host, time running out) breaks the streak.

## Win condition
**Most energy harvested when the clock runs out wins.** (`howToWin`)

## Acceleration
As the round runs the foam seethes harder: pairs flicker in **faster**,
lifetimes get **shorter** (so the average pair is worth more but harder to
catch), **more pairs** spawn per flicker, and **more real-particle decoys**
intrude. Late game is pure reflex + judgment.

## Session (the S)
Host-owned. The game renders only the play area and reads `session.isRunning`;
it auto-runs on start, holds a calm ready state before, and stops cleanly when
the host ends the round — so a session closes and a fresh one re-enters with
zeroed score/streak (`hostReset`). No internal timer or results UI.

## Tuning
- `durationSeconds`: 50
- `humanMax`: ~520 eV (skilled run)
- `starThresholds`: `[140, 300, 460]`
