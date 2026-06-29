# AGENT.md — Slingshot

> Context for an AI agent working on THIS game. Read this and GAME.md first.
> Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/planets/orbit_slingshot/`
  - Game code: `orbit_slingshot_game.dart` (`OrbitSlingshotGame` /
    `_OrbitSlingshotGameState` / `_SlingshotPainter`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only framework deps** (do NOT modify, do NOT add new ones):
  - `lib/games/mini_game.dart` — `MiniGameSession`
  - `lib/games/fx.dart` — `GameFx`, `FxParticle`, `FxBurst`, `FxPop`
  - `lib/theme/potatuhs.dart` — palette/fonts
- **Do NOT touch** other games, `mini_game_registry.dart`, `game_catalog.dart`,
  the host/router, or `orbit_catch/`. Registry/catalog wiring is the
  orchestrator's job — surface the `MiniGameSpec` for them, don't edit it yourself.

---

## Dependency rule (the whole point of the module layout)

This game is a **self-contained module**. It must NOT import another game's code
(especially not `orbit_catch_game.dart`). The gravity-aim core is reimplemented
here on purpose so this game can be changed without touching any other. If you
need a shared helper, inline a private copy — isolation beats DRY.

---

## Scene / exit contract

- The host owns intro / 3·2·1 countdown / score-HUD / timer / results. This
  widget renders ONLY the play area and runs its loop only while
  `widget.session.isRunning`.
- Report points via `widget.session.addScore(delta)`; report the current streak
  via `widget.session.noteStreak(_streak)` on each clear.
- No game-over / restart inside the widget. A miss only costs a shot; the system
  rerolls so a fresh attempt always re-enters (the GAMES "S").
- When not running, keep ticking the atmosphere (`_t`) so the canvas isn't frozen
  behind the host's countdown/results, but accept no input and launch nothing.

---

## Performance contract (black-screen / jitter bug-class)

- ONE `AnimationController` (the ticker) drives sim + fx + preview; everything
  paints through a single `CustomPainter`. Dispose the ticker in `dispose()`.
- `shouldRepaint` is `true` (we animate every frame); keep the widget subtree
  under the `CustomPaint` tiny (pips, level text, two pills) — do NOT grow it.
- Gravity integrates in 10 sub-steps; the preview runs the SAME math for up to
  `_kPreviewSteps` steps. If you raise well count or preview length, watch the
  per-frame cost (preview is O(steps × wells)). Trail capped at 120 points.

---

## Tunable constants (current values — top of `orbit_slingshot_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kGravityConstant` | 205000 | Overall pull strength / curve drama |
| `_kAssistBandBase` | 40 px | How close counts as an assist (+ mass term) |
| `_kPreviewSteps` | 300 | Preview length (cost = steps × wells) |
| `_kBaseHit` | 50 | Floor points per clear |
| `_kChainUnit` | 26 | Chain payout: `× assists²` |
| `_kShotsPerLevel` | 4 | Shots before a system rerolls |
| `_kMaxLaunchSpeed` | 720 | Full-power launch speed |
| `_kTargetBaseRadius` / `_kTargetMinRadius` | 25 / 14 | Beacon hit zone |
| `_kLoopMassGain` / `_kLoopShrink` | 0.16 / 0.09 | Per-loop escalation |

Level shape lives in `_kLevelLadder` (name, hints, `wellCount`, `drift`). The
scatter generator (`_generateSystem`) places wells by rejection sampling, avoiding
the cannon, the beacon, and well overlaps.

---

## Design intent / non-goals

- **DO** keep the chain the dominant scoring lever — players should feel that the
  longer slingshot is worth the risk. If you tune, preserve the super-linear payout.
- **DO** keep the predicted-CHAIN + LOCK readout honest: the preview uses the exact
  flight math, so what it shows must equal what happens. Don't fork the two sims.
- **DON'T** make a clean direct shot to a far beacon easy — that erases the variant.
  Beacons should be far/occluded enough that chaining is the path.
- **DON'T** add raster assets. Canvas/`GameFx` only.

---

## Known TODOs (priority order)

1. **[MED — balance]** `humanMax`/`starThresholds` in the spec are first-pass;
   retune after playtest so 3 stars ≈ a strong real round.
2. **[LOW — feel]** Drifting wells use a single sine; consider per-well speed
   variance for richer "wandering field" levels.
3. **[LOW — edu]** Could name specific giants ("JUPITER") on a tutorial level to
   sharpen the Voyager tie. Optional; don't bloat the core.

---

## Assets

Procedural ONLY. `GameFx.atmosphere/orb/glowLine`, `FxBurst`, `FxPop`,
`TextPainter` via `GameFx.text`, and raw `Canvas` primitives. No PNG/JPEG.
