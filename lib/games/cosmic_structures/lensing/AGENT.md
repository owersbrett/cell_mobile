# AGENT.md — Lensing

> Context for an AI agent working on THIS game. Read this and GAME.md first.
> Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/cosmic_structures/lensing/`
  - Game code: `lensing_game.dart` (`LensingGame` / `_LensingGameState` /
    `_LensingPainter` / `_MassBar` / `_Source` / `_Round` / `_Ray`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only framework deps** (do NOT modify, do NOT add new ones):
  - `lib/games/mini_game.dart` — `MiniGameSession`
  - `lib/games/fx.dart` — `GameFx`, `FxParticle`, `FxBurst`, `FxPop`
  - `lib/theme/potatuhs.dart` — palette/fonts
- **Do NOT touch** other games, `mini_game_registry.dart`, `game_catalog.dart`,
  the host/router, or `planets/orbit_catch` / `galactic/black_hole`.
  Registry/catalog wiring is the orchestrator's job — surface the `MiniGameSpec`
  for them, don't edit it yourself.

---

## Dependency rule (the whole point of the module layout)

This game is a **self-contained module**. It must NOT import another game's code.
The light-deflection sim is implemented here on purpose so this game can be changed
without touching any other. If you need a shared helper, inline a private copy —
isolation beats DRY.

---

## Scene / exit contract

- The host owns intro / 3·2·1 countdown / score-HUD / timer / results. This widget
  renders ONLY the play area and runs its scoring loop only while
  `widget.session.isRunning`.
- Report points via `widget.session.addScore(delta)` (one delta per reading in
  `_onLock`). Report the current streak via `widget.session.noteStreak(_streak)`
  on each fast solve.
- No game-over / restart inside the widget. Each reading loads a fresh geometry; a
  fresh session re-generates and the first drag re-enters (the GAMES "S").
- When not running, keep ticking the atmosphere AND tracing rays (`_t`, `_trace`)
  so the canvas previews live behind the host's countdown/results — but accept no
  input, run no lock/scoring, and don't advance the round.

---

## Performance contract (black-screen / jitter bug-class)

- ONE `AnimationController` (the ticker) drives the trace + lock + fx; everything
  paints through a single `CustomPainter`. Dispose the ticker in `dispose()`.
- `shouldRepaint` is `true` (we animate every frame). Keep the widget subtree under
  the `CustomPaint` tiny (a focus pill, a label, a hint, the mass bar) — do NOT
  grow it.
- Rays are re-traced every frame: `≤2 sources × {7|5} rays × _kRaySteps (150)`,
  one halo, one distance calc per step. That is the cost ceiling — if you raise
  `_kRaySteps`, source count, or ray count, watch per-frame cost. Trace results go
  into flat lists (`_rays`) consumed by the painter; no per-ray widgets.

---

## Tunable constants (current values — top of `lensing_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kG` | 22.0 | Bend strength (× mass). Higher = rays curve harder |
| `_kRayStep` / `_kRaySteps` | 7 px / 150 | Trace resolution + reach |
| `_kSoftening` | 26 px | Min halo distance (avoids singularity blow-up) |
| `_kMinMass` / `_kMaxMass` | 0.35 / 3.4 | Mass-bar range (under-/over-bend window) |
| `_kDetectorBase` / `_kDetectorMin` | 30 / 16 px | Detector size, easy → hard |
| `_kDetectorDrift` | 46 px/s | Lateral drift on moving rounds |
| `_kLockThreshold` / `_kLockTime` | 0.6 / 0.42 s | Focus fraction + hold to read |
| `_kBasePoints` | 100 | Per reading |
| `_kMaxSpeedBonus` / `_kRoundPar` | 130 / 6.5 s | Speed bonus + its window/streak gate |
| `_kMaxPrecisionBonus` | 90 | Dead-centre focus bonus |
| `_kRoundStepBonus` | 10 | × round index (+50 × loop) |
| `_kEinsteinBonus` | 70 | Tight multi-source convergence |
| `_kLadderLength` / `_kLoopShrink` | 9 / 0.1 | Rounds per loop + per-loop shrink |

---

## Design intent / non-goals

- **DO** keep it a *bend-the-light* puzzle: continuous rays, two analog controls
  (position + mass), live preview, focus-and-hold lock. The challenge is reading
  geometry **fast**, not flicking.
- **DO** keep generation **solvable**: detector offset from the straight beam must
  be coverable by some (mass, position) inside the allowed ranges. Two-source
  rounds are placed **symmetrically** about the detector line so one halo focuses
  both — keep that invariant if you touch `_generate`.
- **DON'T** turn this into a projectile launcher (orbit_catch) or a lethal central
  engine (black_hole). No flick-aim, no single launched object, no win/lose on a
  collision — the differentiator is **bending a continuous light beam with an
  invisible mass**.
- **DON'T** add raster assets. Canvas/`GameFx` only.

---

## Known TODOs (priority order)

1. **[MED — balance]** `humanMax`/`starThresholds` are first-pass; retune after
   playtest, and re-check `_kG`/mass-range so a clean solve is reliably reachable
   on every generated geometry (no impossible offsets).
2. **[LOW — variety]** The optional **"spot the lensed image"** quick variant
   (identify which of several smears is the true lensed arc) is documented but
   unbuilt — add as an occasional round type without bloating the core trace loop.
3. **[LOW — feel]** Beams are purely horizontal for readability; angled beams would
   add variety but must stay solvable. Optional.

---

## Assets

Procedural ONLY. `GameFx.atmosphere/orb/text`, `FxBurst`, `FxPop`, and raw `Canvas`
primitives (the warp rings, dashed halo boundary, spiral galaxies, telescope
detector, lock ring are all hand-drawn). No PNG/JPEG.
