# AGENT.md — Black-Hole Heart

> Context for an AI agent working on THIS game. Read this and GAME.md first.
> Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/galactic/black_hole/`
  - Game code: `black_hole_game.dart` (`BlackHoleGame` /
    `_BlackHoleGameState` / `_BlackHolePainter` / `_Star`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only framework deps** (do NOT modify, do NOT add new ones):
  - `lib/games/mini_game.dart` — `MiniGameSession`
  - `lib/games/fx.dart` — `GameFx`, `FxParticle`, `FxBurst`, `FxPop`
  - `lib/theme/potatuhs.dart` — palette/fonts
- **Do NOT touch** other games, `mini_game_registry.dart`, `game_catalog.dart`,
  the host/router, or `planets/orbit_catch` / `solar_systems/orbital_mechanic`.
  Registry/catalog wiring is the orchestrator's job — surface the `MiniGameSpec`
  for them, don't edit it yourself.

---

## Dependency rule (the whole point of the module layout)

This game is a **self-contained module**. It must NOT import another game's code.
The central-mass gravity core is implemented here on purpose so this game can be
changed without touching any other. If you need a shared helper, inline a private
copy — isolation beats DRY.

---

## Scene / exit contract

- The host owns intro / 3·2·1 countdown / score-HUD / timer / results. This widget
  renders ONLY the play area and runs its loop only while
  `widget.session.isRunning`.
- Report points via `widget.session.addScore(delta)` (continuous income is banked
  as integer deltas via `_pointBank`; revolution bonuses are added directly).
  Report the current streak via `widget.session.noteStreak(_streak)` each revolution.
- No game-over / restart inside the widget. Losing a star only frees a slot; the
  next fling re-enters (the GAMES "S").
- When not running, keep ticking the atmosphere (`_t`) so the canvas isn't frozen
  behind the host's countdown/results, but accept no input, spawn nothing, and
  run no physics/scoring.

---

## Performance contract (black-screen / jitter bug-class)

- ONE `AnimationController` (the ticker) drives sim + fx + preview; everything
  paints through a single `CustomPainter`. Dispose the ticker in `dispose()`.
- `shouldRepaint` is `true` (we animate every frame); keep the widget subtree
  under the `CustomPaint` tiny (star pips, one count, one hint pill) — do NOT grow it.
- Gravity integrates in 6 sub-steps per star; the preview runs the SAME math for
  up to `_kPreviewSteps` steps (single body). Star count is capped at `_kMaxCap`
  (7) and trails at 46 points. If you raise any of these, watch per-frame cost.

---

## Tunable constants (current values — top of `black_hole_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kGM` | 1.4e7 | Overall pull / orbital-speed scale (`v=√(GM/r)`) |
| `_kRelK` | 1.0 | Relativistic whip strength near the horizon |
| `_kHorizonBase` / `_kHorizonGrow` | 32 / 12 px | Lethal radius + its growth |
| `_kIscoFactor` | 2.1 | ISCO ring radius = horizon × this |
| `_kDragBase` / `_kDragInner` | 0.045 / 3.2 | Orbit decay rate (outer / inside ISCO) |
| `_kPtsPerSec` | 44 | Continuous income, scaled by closeness |
| `_kRevBonus` | 60 | Per-revolution bonus, scaled by closeness |
| `_kStartCap` / `_kMaxCap` | 4 / 7 | Concurrent-star population |
| `_kKickFirst` / `_kKickEvery` / `_kKickStrength` | 15 / 10 / 78 | Kick pacing + force |
| `_kDragToSpeed` / `_kMin/MaxSpeed` | 3.2 / 50 / 540 | Fling power curve |

---

## Design intent / non-goals

- **DO** keep the tension "closer = more points = more dangerous". Tighter orbits
  must out-earn lazy wide ones AND decay faster. If you retune, preserve both.
- **DO** keep the preview honest: it runs the exact flight math, so its
  ORBIT/SWALLOWED/ESCAPES verdict must equal what happens. Don't fork the two sims.
- **DON'T** turn this into orbit_catch (a single target to hit) or into a calm
  planet sim. The differentiator is the lethal central engine: one dominant mass,
  a lethal horizon, accretion, relativistic whip, decay, and kicks.
- **DON'T** add raster assets. Canvas/`GameFx` only.

---

## Known TODOs (priority order)

1. **[MED — balance]** `humanMax`/`starThresholds` in the spec are first-pass;
   retune after playtest so 3 stars ≈ a strong real round.
2. **[LOW — feel]** Kicks are uniform-random impulses; consider directional kicks
   (e.g. always tangential) for a more "tidal" read.
3. **[LOW — edu]** Could surface a live "v vs v_circular" readout while aiming to
   sharpen the orbital-velocity lesson. Optional; don't bloat the core.

---

## Assets

Procedural ONLY. `GameFx.atmosphere/orb/text`, `FxBurst`, `FxPop`, and raw
`Canvas` primitives (the accretion disk, photon ring, dashed ISCO are all
hand-drawn). No PNG/JPEG.
