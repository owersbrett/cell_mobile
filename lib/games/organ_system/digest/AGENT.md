# AGENT.md — Digest

> The dedicated agent for the **Digest** game. Owns this folder only
> (`lib/games/organ_system/digest/`). Does NOT touch the registry, catalog, host, or other games —
> the lead wires those.

## Mandate
Keep Digest a complete, fun, correct **GAMES**-rubric game: the digestive-sequence router. The
educational payload — the five-stage tract and *where absorption happens* — lives **inside the
mechanic**, not in a popup. Protect that.

## Scope & boundaries
- Edit only files under `lib/games/organ_system/digest/`.
- Dependency rule (hard): import only `flutter`, `dart:math`, `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`. Never import another game or a `mini_games_batch*` megafile.
- Architecture rule (hard): **one Ticker → one CustomPainter.** No per-frame `setState` over big widget
  trees; all motion is painted. One `setState(() {})` per tick is the only rebuild.
- The host owns clock / countdown / score HUD / results. This widget renders ONLY the play area, gates
  all play on `session.isRunning`, and reports through `session.addScore` / `session.noteStreak`.
- Keep the ready (pre-`isRunning`) state calm and non-scoring (the `_idle` drift).

## Invariants to preserve
- The **five-stage order** MOUTH → ESOPHAGUS → STOMACH → SMALL INTESTINE → LARGE INTESTINE and each
  stage's action are the lesson. Don't reorder or rename away the biology.
- **Absorption stages pay most** (nutrients at small intestine, water at large intestine) — that is the
  teaching weight. Keep `_kStagePoints` skewed that way.
- **One bolus per stage** + "clear the front first" is the pipeline mechanic. Don't remove the
  occupancy/`FULL` rule.
- **Mis-actions stall** (too-soon / wrong stage) and reset streak. Keep the cost legible, not punishing.

## Tuning knobs (all top-of-file consts)
`_kIntakeStart/_kIntakePeak`, `_kRipenStart/_kRipenPeak`, `_kMoveTime`, `_kStagePoints`,
`_kCompleteBonus`. Re-tune `humanMax` / `starThresholds` in the spec by playtest if scoring shifts.

## Definition of done (per change)
`flutter analyze lib/games/organ_system/digest/` → **zero issues**. Sanity-run: a session starts on
`isRunning`, food flows, absorption scores, streak tracks, a fresh session re-enters clean.
