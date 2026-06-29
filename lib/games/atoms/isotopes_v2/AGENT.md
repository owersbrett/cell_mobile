# Isotopes v2 — Agent (A)

The owning agent for `isotopes_v2`. Improve THIS game only; do not touch the
registry, catalog, host, or sibling games.

## Charter
Keep the lesson (protons set the element/Z; protons+neutrons set mass A; same
element + different neutrons = an isotope) while holding the Fun-Multiplayer UX
bar. This module is the UX-pass alternative to `isotopes` — the original stays
playable alongside it.

## What the teardown said to fix (do not regress)
- **Kill the stepper grind.** The original's only input was single ±1 taps, so
  "harder" prompts demanded MORE taps (Fe-58 from scratch ≈ 57 taps). v2 gives
  every axis **coarse + fine** controls (`_AxisControl`, protons ±5 / neutrons
  ±10). Reaching a value must stay a few taps. Do not reintroduce a single-step-
  only dial.
- **Skill ≠ knowledge recall only.** The build is **not reset between prompts**
  (`_lockIn` keeps z/n and only calls `_nextTarget`), so dialing the cheapest
  path from your current nuclide is a real, repeatable skill (overshoot costs
  taps under the clock). Keep this carry-over.
- **Pace must accelerate.** Each prompt runs its own `_promptTimer` from
  `_promptDuration()`, which **shrinks with `_solves`** and tightens in the
  surge. Empty = skip (no score lost). Do not flatten the pace.
- **Shared, fair climax.** `_kSurgeMs` (last 10s) doubles points and tightens
  timers — derived from `session.remaining`, identical for all players. Never
  call `session.addTime` (no clock runaway).
- **Every lock is a visible beat.** `_setStamp` slams a big `NAME-A  +pts` stamp
  centre-screen so pass-and-play opponents read momentum. Keep it big + brief.

## Invariants
- **Real isotope `_kPool`, the `_kElements` table, and the prompt-kind ladder**
  (counts → massName → neutrons → symbol) are the education — do not touch the
  data or the unlock thresholds in `_chooseKind` / `_allowedPool` without reason.
- **Live `Z/N/A` readout + ELEMENT/ISOTOPE pills** are the in-mechanic lesson —
  protons change the element live, neutrons change A while the element holds.
  Keep them visible while dialing.
- **No streak score multiplier.** Streak feeds `noteStreak` (mastery) only; the
  only multiplier is the fixed-window surge. Keep scoring comparable.
- **One Ticker → one CustomPainter.** No second controller; no per-frame
  setState. setState fires only on tap (`_bumpProtons`/`_bumpNeutrons`/`_lockIn`)
  and on `_onRunStart`. The painter repaints from `_model.clock`.

## Tuning knobs (top of file)
`_kBase`, `_kMaxSpeed`, `_kSurgeMs`, `_kPromptMax`, `_kPromptMin`, the coarse
steps passed to each `_AxisControl` (5 / 10), and the level ramps in
`_promptDuration` / `_allowedPool` / `_chooseKind`. `humanMax` / `starThresholds`
live in the registry spec — playtest to tune.

## Test
`flutter analyze lib/games/atoms/isotopes_v2/` → zero. Session re-entry: the host
owns the clock; `_onRunStart` re-arms from `isRunning`, resetting solves, streak,
build (z=1,n=0) and serving a fresh prompt — close and re-enter must start clean.
