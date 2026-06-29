# Quantum Foam v2 — GAME.md (the Manual)

**Scale:** Nothings · **Verb:** REACT+TIME / tap-at-peak · **Id:** `quantum_foam_v2`

## Premise
"Nothing" is never empty. The quantum vacuum seethes: borrowing energy from the
uncertainty principle, virtual particle–antiparticle **pairs** flicker into
existence, drift apart for a borrowed lifetime, then **annihilate** back to the
void. You are an observer harvesting that borrowed energy — but only the instant
it is most manifest, at **peak separation**.

## What v2 fixes (vs v1)
In v1 the energy–time tradeoff — the whole point — was invisible before you
tapped, so play collapsed to "tap everything fast, avoid gold." v2 makes the
tradeoff **legible** and turns it into a **timing decision**:
- Every living pair shows a **live "+N eV" number** that climbs to a maximum as
  the two halves spread apart, then falls as they snap back together.
- A **reticle ring contracts** toward each pair as it nears its apex and snaps
  bright at the peak — an unmistakable "tap NOW" cue.
- **Tapping at the apex = a PEAK harvest** (full energy + a streak bonus). Tap
  early or late and you get only a fraction. Spamming taps wastes pairs for ~0.

## How to play
- **Watch a pair spread apart. Tap it when the number is highest** (the apex).
  Tap = "observe" it and harvest the borrowed energy on display.
- **Peak harvest** (separation ≥ 94%, shown by the bright snapped reticle and a
  `★`): full energy **+ an escalating bonus**, and your precision streak grows.
- **Off-peak harvest:** you still bank the fraction shown, but the streak breaks.
  A missed/annihilated pair is **free** — it costs nothing.
- **Do NOT tap a stable, gold REAL particle.** It is steady (not flickering) and
  ringed. Tapping it is a measurement error: **−20** and your streak resets.

## Scoring
- **Score = energy harvested**, in `eV`.
- **Energy–time tradeoff (now playable):** a pair's full energy is *inversely
  proportional to its lifetime* (~10–60 eV). **Short-lived pairs are worth more
  but their apex is narrow and fast** (hard to time); long-lived pairs are cheap
  but their apex is wide and lazy (easy). Choosing which to chase is the skill.
- **Live value = full energy × sin(t·π)** — what the number shows, peaking at the
  apex.
- **Peak streak:** consecutive peak harvests add a small escalating, **capped**
  bonus. Any off-peak harvest or a gold mistap breaks it.

## Win condition
**Most energy harvested when the clock runs out wins.** (`howToWin`)

## Acceleration & climax
The foam seethes harder as the round runs: pairs flicker in faster, lifetimes
shrink (apexes get narrower), and reals intrude more. In the final ~7 seconds a
one-shot **VACUUM SURGE** erupts — a ring of high-energy pairs flashes at once
and the spawn rate spikes, resolving the ramp into a crescendo of simultaneous
peak decisions.

## Spectacle (pass-and-play)
A public **"ENERGY HARVESTED"** bar fills toward milestones; each 500 eV flashes
on the field — a shared "ooh" for spectators.

## Session (the S)
Host-owned. The game renders only the play area and reads `session.isRunning`;
it auto-runs on start, holds a calm ready state before, and stops cleanly when
the host ends the round — so a session closes and a fresh one re-enters with
zeroed score/streak/bar (`hostReset`). No internal timer or results UI.

## Tuning
- `durationSeconds`: 52
- `humanMax`: ~2000 eV (skilled run)
- `starThresholds`: `[600, 1200, 1750]`
- Levers: spawn `interval`/`perSpawn` and lifetime range (ticker accelerate
  block), energy formula `(26 / lifetime)` and peak bonus (`_harvest`), peak
  band `_kPeakQ`, surge window `_kSurgeWindow`, bar `_kBarFull` / `_kMilestone`.
