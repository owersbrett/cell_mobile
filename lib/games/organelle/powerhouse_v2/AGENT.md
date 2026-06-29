# AGENT.md — Powerhouse v2

The assigned agent (the **A** in GAMES) for the `powerhouse_v2` module.

## Scope
- Owns **only** `lib/games/organelle/powerhouse_v2/`:
  `powerhouse_v2_game.dart`, `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`.
- Does **not** edit the registry, catalog, host, or any other game. Wiring the
  `MiniGameSpec` into `mini_game_registry.dart` and a `CatalogGame` into
  `game_catalog.dart` is the orchestrator's job.

## Contract
- Widget: `class PowerhouseV2Game extends StatefulWidget` taking
  `{ required MiniGameSession session }`.
- Reads `session.isRunning` to gate the loop and `session.remaining` to detect
  the overdrive window; reports via `session.addScore` and `session.noteStreak`.
  Never owns the clock, opponents, or standings — the host does.
- Self-contained: imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`,
  and Flutter. Must not import another game's code.

## Invariants (do not regress)
- **One Ticker → one CustomPainter.** No second `AnimationController`, no
  per-frame `setState` (HUD throttled to ~15fps). Particles ≤60, pops ≤5. Guard
  every paint path against non-finite metrics.
- **The lesson stays in the mechanic.** Yield must remain linear in O₂ used,
  with two distinct failure modes (no glucose = misfire/0, no O₂ = anaerobic).
  Do not flatten the aerobic vs anaerobic teaching even when retuning numbers.
- **Honest input.** No invisible/whole-screen tap surface. Input is the two feed
  buttons; the canvas is `IgnorePointer`.
- **Fair scoring.** Keep the aerobic:anaerobic spread modest (currently 3:1) and
  keep the streak as a *display/award* only — it must not multiply score.
  Overdrive ×2 must apply uniformly (it scales all yields equally).
- **Climax preserved.** The final-`_overdriveWindow` seconds must accelerate and
  raise stakes; don't remove the crescendo.
- **Session re-entry (the S).** `_resetRun` on `isRunning` rising edge; a fresh
  run leaves no residue.

## Verify
- `flutter analyze lib/games/organelle/powerhouse_v2/` → **zero** issues.
- `flutter test test/games` stays green after the orchestrator wires the spec.

## Tuning notes
- `humanMax` / `starThresholds` in the spec are playtest-tuned, not gates.
- If the late game feels unfair, prefer easing `_periodEnd`/`_o2Drain` over
  widening the ATP spread (which would reintroduce runaway).
