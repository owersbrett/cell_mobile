# AGENT.md — Circulate v2

The assigned agent (the **A** in GAMES) for the `circulate_v2` module.

## Scope
- Owns **only** `lib/games/organ_system/circulate_v2/`:
  `circulate_v2_game.dart`, `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`.
- Does **not** edit the registry, catalog, host, or any other game. Wiring the
  `MiniGameSpec` into `mini_game_registry.dart` and a `CatalogGame` into
  `game_catalog.dart` is the orchestrator's job.

## Contract
- Widget: `class CirculateV2Game extends StatefulWidget` taking
  `{ required MiniGameSession session }`.
- Reads `session.isRunning` to gate the loop and `session.remaining` to detect
  the CODE RED surge window; reports via `session.addScore` and
  `session.noteStreak`. Never owns the clock, opponents, or standings — the
  host does.
- Self-contained: imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`,
  and Flutter. Must not import another game's code.

## Invariants (do not regress)
- **One Ticker → one CustomPainter.** No second `AnimationController`, no
  per-frame `setState`. Particles ≤60, pops ≤6. Guard every paint path against
  non-finite metrics.
- **The coupling stays VISIBLE.** The countable charge magazine is the hero
  read — the whole point of v2 over v1. Do not revert it to a tiny continuous
  bar. Each delivery must spend a visible charge; the lungs must light up
  *before* the reserve hits zero (anticipation, not punishment).
- **Two distinct, signposted actions.** DELIVER (tap organ) vs RECHARGE (tap
  the big lungs node) must stay visually and behaviourally distinct: red out,
  blue back. Do not merge them or add a hidden whole-screen tap meaning.
- **The two-loop lesson stays in the mechanic.** Systemic deliver vs pulmonary
  recharge, red↔blue oxygenation on the heart. Don't flatten it when retuning.
- **Fair scoring + no early end.** Keep the rescue bonus spread modest
  (`5 + (1−o2)·15`); keep streak as a *display/award* only (never a multiplier).
  A starved organ must NOT end the run — the run always rides the full clock.
- **Climax preserved.** The final `_surgeWindow` seconds must spike demand and
  apply the uniform ×2 (shared host clock) — don't remove the crescendo.
- **Session re-entry (the S).** `_resetRun` on the `isRunning` rising edge; a
  fresh run leaves no residue.

## Verify
- `flutter analyze lib/games/organ_system/circulate_v2/` → **zero** issues.
- `flutter test test/games` stays green after the orchestrator wires the spec.

## Tuning notes
- `humanMax` / `starThresholds` in the spec are playtest-tuned, not gates.
- If the late game feels unfair, prefer easing `_surgeDrainMult` /
  `_surgeDemandKick` over widening the rescue bonus (which would reintroduce
  runaway). To make the coupling tighter, lower `_chargeCap`; to relax it,
  raise it.
