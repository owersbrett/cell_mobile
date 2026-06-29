# AGENT.md — Life Cycle v2

> The **A** in GAMES. The agent that owns this game module. Scope is this folder only.

## Identity
- **Game:** Life Cycle v2 (`life_cycle_v2`), organism scale.
- **Widget:** `LifeCycleV2Game` → `lib/games/organism/life_cycle_v2/life_cycle_v2_game.dart`.
- **Lineage:** UX-pass alternative to `life_cycle`. Born from `docs/ux_pass/teardowns/life_cycle.md`.

## Mandate
Keep this game satisfying the GAMES rubric and the 7-dim UX rubric. The three teardown failures it was
built to fix are load-bearing — do not regress them:
1. **The wheel is the mechanic.** Input = tapping nodes ON the ring. Never reintroduce a separate
   4-card answer grid; the signature visual and the input must stay the same object.
2. **No blocking post-answer flare.** Correct taps advance instantly. The ONLY pause is the ~0.8s
   miss-reveal dwell. Do not add a per-answer fact gate.
3. **Accelerating climax.** Keep the shrinking step window + the final-10s climax driven off
   `session.remaining`.

## Hard constraints (don't break these)
- **Self-contained.** Import ONLY `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`, Flutter. Never import another game.
- **Perf budget.** Exactly ONE `Ticker` → ONE `CustomPainter`. The painter repaints off the `_Frame`
  notifier; there is NO per-frame `setState`. If you add visuals, add them to the painter, not to the
  widget tree.
- **Host owns the meta-loop.** Never call `endEarly`; never draw the master clock/score/results. Read
  `session.isRunning` / `session.remaining`; report via `session.addScore` / `session.noteStreak`.
- **Score is bounded.** Multiplier is capped at ×4 and the speed bonus is 100→25 — keep competition
  readable (no runaway leader). Don't uncap.

## Architecture map
- **Data:** `_Meta`, `_Stage`, `_Organism`, `_kOrganisms` (14 organisms across the 4 metamorphosis
  types). Inline `const`. Education lives here — keep the taxonomy intact.
- **State (`_LifeCycleV2GameState`):** the Ticker, the round model (`_org`, `_stageAngle`, `_curStage`,
  `_nextStage`, `_visited`), the step timer (`_stepTime` vs the `_stepLimit` getter), the miss dwell
  (`_dwell`, `_wrongTapped`), difficulty getters (`_maxTier`, `_ramp`, `_closing`), scoring, and the
  geometry mirror (`_nodePos`, `_nodeR`) shared with the hit-test.
- **Painter (`_WheelPainter`):** atmosphere, ring + chevrons, nodes (current / visited / revealed /
  wrong / candidate), the timer arc, the hub, the teaching ribbon, the streak chip, and FX.

## Tuning knobs (where to reach first)
- **Pace:** `_stepLimit` getter (base window + climax shrink).
- **Difficulty curve:** `_maxTier` thresholds and `_ramp` divisor.
- **Climax intensity:** the `_closing` window (currently last 10s) and the rotation-speed term in
  `_onTick`.
- **Scoring feel:** `_kMaxPoints` / `_kFloorPoints` / `_kStreakStep` / `_kMaxMult`.
- **Calibration:** `humanMax` and `starThresholds` in the registry spec — tune by playtest.

## Definition of done for a change
`flutter analyze lib/games/organism/life_cycle_v2/` is clean, the perf budget holds (one ticker, one
painter, no per-frame widget rebuilds), and a session can close and a fresh one re-enter cleanly (the
**S**). Do not edit `mini_game_registry.dart` or `game_catalog.dart` — the orchestrator wires those.
