# Tissue Type — AGENT.md (the A in GAMES)

This game has a dedicated maintainer agent. Anyone improving Tissue Type should
load this file first.

## Mandate
Own `tissue_type_game.dart` and its three sibling docs. Keep the game a
**self-contained module**: it may import ONLY `../../mini_game.dart`,
`../../../theme/potatuhs.dart`, `package:flutter/*`, and `dart:math`. It must NOT
import another game's code, the registry, the catalog, or the host.

## Architecture (don't break the contract)
- One `Ticker` drives the whole game (`_onTick` → `_simulate` → `setState`).
- The heavy slide drawing lives in `_SamplePainter`, wrapped in a
  `RepaintBoundary`; its `shouldRepaint` keys on `sampleId` (and `subtlety`) so
  the expensive paint only re-runs when the sample changes — NOT every frame.
- The cheap `_AmbientPainter` (orbs + burst particles) animates every frame.
- The host owns clock / countdown / score / results. Never call `endEarly`.
  Gate all sim on `session.isRunning`. Report via `addScore` + `noteStreak`.

## Invariants to preserve
- Samples are stained with ONE uniform palette (`_kMembrane`, `_kCyto`, `_kNuc`,
  `_kFiber`). Per-type accent colours (`_kEpiAccent` …) are UI-chrome only — do
  not colour the slide by type or the player classifies by colour, defeating the
  education. The tell must be morphology.
- `_SamplePainter` must be deterministic from `seed` (use the seeded `math.Random`
  passed in) so the drawing never shimmers across `setState` frames.
- Difficulty ramps via `_subtlety` (fades tells) and `_deadline` (shrinks).

## Common tasks
- **New subtype:** add a `_Variant` to `_kVariants` (+ a `subtypeNames` entry in
  `_kMeta`) and a draw branch in the relevant `_<type>` painter method.
- **Re-tune:** edit the `_k*` scoring/timing constants at the top; then re-tune
  `humanMax` / `starThresholds` in the registry spec by playtest.

## Verify before handing back
`flutter analyze lib/games/tissue/tissue_type/` → **zero** issues.
`flutter test test/games` → green.
