# GAME.md — Reflex

> Canonical spec for the Organ-System-scale reaction game. Rules live here; update this first, then code.

- **Scale (cell):** organSystem
- **Game id:** `reflex`
- **Verb:** REACT (pure reaction time)
- **One-line concept:** A stimulus fires at a receptor; tap the instant it hits to fire the response
  before damage. The impulse visibly races receptor → spinal cord → muscle. Faster = more points.
- **Role:** solo high-score
- **Duration:** 50 s (host-owned clock)

## The mechanic (one trial)
1. **WAIT** — the arc sits calm; a randomised pre-stimulus delay counts down. Tapping now is a
   **false start** (−15, streak reset, the wait re-rolls). A **decoy** cue may flash at the brain —
   tapping on it is also a false start (teaches: only the receptor stimulus is the real cue).
2. **REACT** — the receptor flashes orange (the stimulus). A damage ring grows around it. Tap.
3. **RESPONSE** — on a hit the impulse runs receptor → spinal cord → muscle; the muscle contracts.
   Reaction time is measured at the tap; the travel is reward animation, not part of the timing.
4. If the damage ring fills before you tap → **DAMAGE** (0 points, streak reset).

## Scoring
- `speed = ((620 − reactionMs) / 5)` clamped `0..110`. A 150 ms reaction ≈ 94; 350 ms ≈ 54; 600 ms ≈ 4.
- `streakBonus = streak ≥ 3 ? streak × 2 : 0`. Streak = consecutive successful reactions; any
  false-start or damage resets it.
- Score unit: **reaction points**. Best streak surfaces on the results screen.
- Reaction tiers (label only): `<180 ms LIGHTNING · <260 FAST · <360 GOOD · else SLOW`.

## Acceleration (difficulty ramp)
Driven by `_difficulty = (trial / 12).clamp(0,1)`:
- Pre-stimulus wait window shrinks: `1.3–2.8 s` → `0.6–1.4 s` (shorter, less predictable).
- Damage window shrinks: `1.15 s` → `0.72 s` (less time to react).
- Decoy chance rises from 0 (first ~2 trials) up to ~0.55 per wait.

## Education (in the mechanic)
The play surface IS the reflex arc: **stimulus → sensory (afferent) → spinal cord (CNS) → motor
(efferent) → muscle**. The brain is drawn faded above the cord with a dotted "bypassed" link — the
reflex loops at the spinal cord, which is *why* it's fast. See `EDUCATION.md`.

## Controls
Single tap anywhere (full-field). Canvas-drawn; no raster assets.

## Feel — the nodes move (motion budget by role)
Every node drifts on an eased Lissajous path (sine components, never a teleport), with a
**motion budget by role** so the field feels alive and stressful without becoming unfair:
- **Brain** — stays up top, slow small drift (a little lower/right/left/higher). amp ≈ 3.2% w / 2.2% h, slow (f ≈ 0.4–0.55).
- **Spinal cord** — the smallest shift of all. amp ≈ 1% w/h.
- **Receptor & muscle** — large, lively excursions, out of phase with each other. amp ≈ 7.5% w / 6% h, quicker (f ≈ 1.5–2.3).

Amplitude scales with difficulty (`gain = 0.55 + 0.45 × difficulty`) so motion is always on and
the field gets busier as the run ramps — stress escalates per GAME_DESIGN.md §1. Motion is a **feel**
change only; rules/loop/scoring are unchanged. Because moving targets never sit still, a stationary
node can no longer be misread as a "tap now" prompt during the brain-bypass wait.

Positions are computed by `_Arc.animated(size, idlePhase, difficulty)` — deterministic in the ticker
clock + difficulty, so the painter and the tap handler read the **same** node positions (single source
of truth). The tap is full-field so motion never makes a required tap unfair; centers are clamped fully
on-screen. Motion lives on the ticker-driven `CustomPainter` with real elapsed dt — no per-frame widget
rebuilds. autoPilot fires on the live-stimulus phase (position-independent), so it still hits moving nodes.

## Session / resume
Built to **MiniGameSession**: host owns clock/countdown/score/results. Gameplay gates on
`session.isRunning`; the run (re)starts on the rising edge of `isRunning`, so closing a session and
re-entering a fresh one starts cleanly from trial 1. Reports via `addScore` / `noteStreak`.

## Spec (registry)
- accent `Color(0xFFC6FF00)` (electric nerve-impulse lime), icon `Icons.bolt`
- `durationSeconds: 50`, `scoreUnit: 'reaction points'`
- `humanMax: 1700`, `starThresholds: [500, 1000, 1500]`
