# GAME.md — Reflex Gate (reflex_v2)

> Canonical spec for the refined Organ-System-scale reaction game. Rules live here; update this
> first, then code. v2 is the **UX-refinement sibling** of `reflex` — same flawless legibility and
> single-tap affordance, plus a real go/no-go DECISION layer and a push-your-luck CHARGE multiplier
> so the score ceiling is judgement, not pure twitch.

- **Scale (cell):** organSystem
- **Game id:** `reflex_v2`
- **Verb:** DISCRIMINATE & REACT (go/no-go reaction time)
- **One-line concept:** A stimulus fires at the receptor. **ORANGE = REACT** (a noxious cue — tap
  fast, the impulse races receptor → cord → muscle). **TEAL = HOLD** (a benign touch — inhibit the
  reflex; do NOT tap). Read the cue, decide, then react. A brain decoy still punishes anyone who
  reacts to the bypassed pathway.
- **Role:** solo high-score (pass-and-play comparable)
- **Duration:** 50 s (host-owned clock)

## The mechanic (one trial)
1. **WAIT** — the arc sits calm; a randomised pre-stimulus delay counts down. Tapping now is a
   **false start** (−18, charge reset, the wait re-rolls). A **brain decoy** may flash — tapping it
   is also a false start (teaches: only the receptor stimulus is the real cue).
2. **CUE** — the receptor flashes one of two colours:
   - **GO (orange):** a red damage arc grows. **Tap fast.** Score = speed × charge.
   - **NO-GO (teal):** a teal "inhibit" ring depletes. **Do nothing.** Survive the window → bank an
     inhibition reward (× charge). Tapping a NO-GO = misfire (−24, charge reset).
3. **RESPONSE** — only a GO hit runs the impulse receptor → cord → muscle and contracts the muscle.
   A correct HOLD leaves the muscle calm — the reflex was correctly *not* fired.
4. Miss a GO before the damage arc fills → **DAMAGE** (0 points, charge reset).

## The CHARGE multiplier (the risk/skill layer)
- Starts at **×1.0**. Every correct decision (a clean GO reaction OR a correct NO-GO hold) raises it
  by **+0.3**, capped at **×3.5**.
- **Any** mistake — false start, misfired NO-GO, or damage — drops it back to **×1.0**.
- All points are multiplied by the live charge. A clean run compounds; one greedy misread collapses
  it. This is the push-your-luck tension the original lacked: speed still pays, but reckless tapping
  on a NO-GO is now the dominant way to lose a lead.

## Scoring
- GO hit: `speed = ((600 − reactionMs) / 5)` clamped `0..110`, then `× charge`.
- NO-GO hold: `38 × charge`.
- Penalties: false start −18, misfired NO-GO −24, damage 0 (charge reset only).
- Score unit: **reflex points**. Best streak surfaces on the results screen.
- Tiers (label only): `<185 ms LIGHTNING · <265 FAST · <360 GOOD · else SLOW`.

## Competition framing
- A **BEST ⚡ {ms}** readout tracks your fastest GO reaction this round — the ghost to beat in
  pass-and-play.
- The CHARGE meter is always visible, so a holder watching can see the stakes climb.

## Acceleration (difficulty ramp + climax)
Driven by `_difficulty = (trial / 11).clamp(0,1)`:
- Pre-stimulus wait window shrinks: `1.05–2.1 s` → `0.55–1.05 s`.
- GO reaction window shrinks: `1.1 s` → `0.68 s`. NO-GO hold window shrinks: `0.95 s` → `0.70 s`.
- NO-GO frequency climbs `0.16` → `0.42`; decoy chance rises to ~`0.34`.
- **Climax:** the final 12 s (`_climax`, read from `session.remaining`) shave the waits further and
  ramp screen-shake/glow so the end *feels* faster, not just measures faster.

## Education (in the mechanic)
The play surface IS the reflex arc: **stimulus → sensory (afferent) → spinal cord (CNS) → motor
(efferent) → muscle**, brain faded + dotted "bypassed". v2 adds the lesson that the reflex is
**graded and discriminating** — a noxious cue fires withdrawal; a benign touch is inhibited. See
`EDUCATION.md`.

## Controls
Single tap anywhere (full-field). The only decision is *whether* to tap. Canvas-drawn; no raster assets.

## Session / resume
Built to **MiniGameSession**: host owns clock/countdown/score/results. Gameplay gates on
`session.isRunning`; the run (re)starts on the rising edge of `isRunning`, so closing a session and
re-entering a fresh one starts cleanly from trial 1, charge ×1.0. Reports via `addScore` / `noteStreak`.

## Spec (registry)
- accent `Color(0xFFC6FF00)` (electric nerve-impulse lime), icon `Icons.flash_on`
- `durationSeconds: 50`, `scoreUnit: 'reflex points'`
- `humanMax: 2600`, `starThresholds: [800, 1600, 2400]` (first-pass; retune by playtest)
