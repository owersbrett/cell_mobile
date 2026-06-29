# Homeostasis v2 — Agent (A)

Owner agent for the Homeostasis **v2** mini-game (UX Refinement Pass). One
self-contained module:
`lib/games/organism/homeostasis_v2/homeostasis_v2_game.dart`.

## Charter
Keep Homeostasis v2 fun, fair, and faithful to **negative feedback**. The teaching
must live *in the mechanic* (counteract the deviation, don't overshoot), never in
a popup. v2's specific job: tame the v1 cold-start overload and make the standing
spectator-legible — without dropping the multi-variable regulation lesson.

## What v2 fixes (don't regress these)
- **Staged onboarding.** Start with ONE centered gauge; wake the rest on a ramp
  (`_kWakeFrac`). Live gauges spread to fill the width as they come online —
  legibility builds, the cockpit is never dumped at second one.
- **Whole-screen body-state read.** The health vignette + vital-sign pulse (driven
  by `_health` / `_beatPhase`) is the dominant, glanceable winning/losing signal.
  The gauges are the *controls*; the vignette is the *outcome*.
- **Over-correction is punished.** A WHIPLASH (needle slammed through the set point
  and out the far band) docks `_kWhiplashPenalty`, breaks the streak, jolts the
  screen. This enforces "nudge, don't slam."
- **Climax.** The final `_kClimaxWindow` seconds escalate shocks + multiply the
  all-in bonus (`_kClimaxAllInMult`), detected from the host's shared clock.

## Boundaries (do not cross)
- Edit ONLY this folder. Never touch the registry, catalog, host, or another game.
- Imports allowed: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. Nothing else.
- The host owns the clock/countdown/score/results. Render the play area only.
  Gate all drift + scoring on `session.isRunning`; auto-start, calm ready state.

## Performance contract
- ONE `AnimationController` (`days:1`) ticker → ONE `CustomPainter` (`repaint:`
  the controller). No per-frame `setState`, no widget tree per gauge, no per-frame
  allocation storms. Geometry is recomputed flat in `_relayout` and shared by
  paint + hit-test.

## Invariants to preserve when tweaking
- Corrective directions stay physiologically correct (see GAME.md table).
- A fresh session re-initialises cleanly (`_resetRun` on `isRunning` rising edge) —
  the **S** in GAMES.
- Difficulty ramps with `_playElapsed / durationSeconds`; systems wake at
  `_kWakeFrac`; climax derives from `session.remaining`.

## Good first tasks
- Playtest-tune `humanMax` / `starThresholds` in the spec.
- Balance whiplash penalty vs reward so measured play beats mashing but the game
  never feels punishing.
- Tune wake fractions / shock cadence so the ramp stays tense but readable.
