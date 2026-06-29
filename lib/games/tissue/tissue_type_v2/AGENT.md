# Tissue Type v2 — AGENT.md (the A in GAMES)

This game has a dedicated maintainer agent. Anyone improving Tissue Type v2
should load this file first. v2 is the UX-refined sibling of `tissue_type`.

## Mandate
Own `tissue_type_v2_game.dart` and its three sibling docs. Keep the game a
**self-contained module**: it may import ONLY `../../mini_game.dart`,
`../../../theme/potatuhs.dart`, `package:flutter/*`, and `dart:math`. It must NOT
import another game's code (including v1), the registry, the catalog, or the host.

## What v2 is (don't undo the refinement)
v2 is a LIGHT-TOUCH lift of v1, NOT a rewrite. It preserves:
- the four-answer taxonomy and accurate subtype facts (`_kVariants`, `_kMeta`),
- the uniform H&E stain (read SHAPE not colour),
- the procedural `_SamplePainter` histology — carried over verbatim; it is the
  brand asset of this game.

It changes exactly two things:
1. **Instant confirmation.** The 2.4s clock-stopping fact flare is gone. A tap
   registers immediately, the slide flashes correct/wrong for `_kRevealDuration`
   (~0.42s), then the next sample loads. The subtype fact moves into the
   persistent bottom **ticker**, which fades on its own `_factLife` timer and the
   loop never waits on it. Do not re-introduce a blocking post-answer pause.
2. **Fairness cap.** `_streakMult()` is clamped to `_kMaxMult` (×4). Keep it
   bounded so streaks can't run away in pass-and-play.

## Architecture (don't break the contract)
- One `Ticker` (`_onTick`) drives the sim and bumps a single `_frame`
  ValueNotifier. It does **NOT** call setState every frame. setState fires ONLY
  on discrete transitions (tap / timeout / load-next).
- Per-frame visuals repaint off `_frame` via `repaint:`:
  - `_AmbientPainter` — orbs + burst particles (cheap).
  - `_SlideOverlayPainter` — deadline bar + instant-reveal flash (cheap; reads
    live sim state; `shouldRepaint` returns false).
  - the fact ticker fade — one leaf `ValueListenableBuilder` on `_frame`.
- The heavy slide is `_SamplePainter` inside a `RepaintBoundary`; its
  `shouldRepaint` keys on `sampleId` (and `subtlety`) so the expensive paint runs
  only when the sample changes — never per frame.
- The host owns clock / countdown / score / results. Never call `endEarly`.
  Gate all sim on `session.isRunning`. Report via `addScore` + `noteStreak`.

## Invariants to preserve
- Samples are stained with ONE uniform palette (`_kMembrane`, `_kCyto`, `_kNuc`,
  `_kFiber`). Per-type accent colours (`_kEpiAccent` …) are UI-chrome only — never
  colour the slide by type, or the player classifies by colour and the lesson dies.
- `_SamplePainter` must be deterministic from `seed` so the drawing never
  shimmers across frames.
- Difficulty ramps via `_subtlety` (fades tells) and `_deadline` (shrinks).

## Common tasks
- **New subtype:** add a `_Variant` to `_kVariants` (+ a `subtypeNames` entry in
  `_kMeta`) and a draw branch in the relevant `_<type>` painter method.
- **Re-tune:** edit the `_k*` scoring/timing constants at the top; then re-tune
  `humanMax` / `starThresholds` in the registry spec by playtest.

## Verify before handing back
`flutter analyze lib/games/tissue/tissue_type_v2/` → **zero** issues.
`flutter test test/games` → green.
