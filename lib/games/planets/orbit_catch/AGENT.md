# AGENT.md — Orbit Catch

> Context for an AI agent working on THIS game. Read this and GAME.md first.
> Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/planets/orbit_catch/`
  - Game code: `orbit_catch_game.dart` (`PlanetCatchGame` /
    `_PlanetCatchGameState` / `_GravityPuzzlePainter` + the legend frames)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`
- **Read-only framework deps** (do NOT modify, do NOT add new ones):
  - `lib/games/mini_game.dart` — `MiniGameSession`, `LegendFrame`
  - `lib/games/fx.dart` — `GameFx`, `FxParticle`, `FxBurst`, `FxPop`
  - `lib/games/planet_art.dart` — `PlanetArt` (shared with Orbital Insertion;
    crater/topology fidelity is owned by the orchestrator, not this game)
  - `lib/games/potato.dart` — `PotatoArt`, the CANONICAL potato renderer
  - `lib/theme/potatuhs.dart` — palette/fonts
- **Do NOT touch** other games, `mini_game_registry.dart`, `game_catalog.dart`,
  the host/router, or `orbit_slingshot/`. Registry/catalog wiring is the
  orchestrator's job — surface spec changes for them, don't edit it yourself.

---

## Dependency rule (the whole point of the module layout)

This game is a **self-contained module**. It must NOT import another game's
code. `orbit_slingshot` reimplements this core on purpose — isolation beats
DRY. The only cross-game surfaces are the shared-kit files above, and those
are consumed, never edited from here.

---

## Scene / exit contract

- The host owns intro / 3·2·1 countdown / score-HUD / timer / results. This
  widget renders ONLY the play area and runs its loop only while
  `widget.session.isRunning`.
- Report points via `widget.session.addScore(delta)`; report the streak via
  `widget.session.noteStreak(_streak)` on each catch.
- No game-over / restart inside the widget. A miss only costs a shot; out of
  shots rerolls the same level, so a fresh attempt always re-enters (the S).
- When not running, keep ticking the atmosphere (`_t`) so the canvas isn't
  frozen behind the host's countdown/results, but accept no input and launch
  nothing.
- ATTRACT: `session.autoPilot = _autoStep` is registered in `initState` and
  cleared in `dispose`. Keep it deterministic and using the game's OWN sim.

---

## Performance contract (black-screen / jitter bug-class)

- ONE `Ticker` drives sim + fx; everything paints through a single
  `CustomPainter` (`shouldRepaint => true` — we animate every frame). Keep the
  widget subtree under the `CustomPaint` tiny (shot pips, level text, hint
  pill) — do NOT grow it.
- `_onTick` uses REAL elapsed dt (clamped 0..0.04). A hardcoded 1/60 here
  turned dropped frames into slow motion once — never reintroduce it. The
  potato's spin also advances on this dt.
- Gravity integrates in 10 sub-steps; the preview runs the SAME math for up to
  `_kPreviewSteps` (170) steps. Preview cost is O(steps × wells). Trail capped
  at 64 points, drawn as 3 polyline bands with ONE blurred stroke each — never
  a blur per segment (that was the biggest cost here historically).
- Earth/potato blurs are few and radius-clamped; cloud wisps are 3 small
  blurred ovals inside a clip. Don't multiply blur passes.

---

## Locked visual laws (from the 7/12 playtest pass)

1. **The target is EARTH, drawn locally** (`_drawEarth`): PlanetArt has no
   Earth archetype and the destination must read UNLIKE the wells. Fixed
   continent layout (same face every time) so it's recognizable at the 13px
   floor. Do not replace it with a `PlanetArt` body or a flat gold orb.
2. **The beacon converges.** Destination = gold anchor ring + rings pulsing
   INWARD onto the globe. Never a crosshair/plus sticker.
3. **The projectile is the potato, visually only.** `_drawPotato` wraps
   `PotatoArt.paint`; spin (`_kPotatoSpinRate`) is paint-time. ALL
   collision/catch math stays on the circular `_kProjectileRadius` body. If
   you change the potato look, change rx/ry to keep hugging that circle.
4. **Warm vs cool.** The potato and its trail are gold/warm; wells and their
   fields are the cool board. Keep that separation — it's how the player
   tracks the shot through a busy field.
5. **Legend cards mirror the live painter.** `_legendCatcher` / `_legendCannon`
   / `_legendTrail` draw the SAME components (Earth, loaded launcher, potato
   trail) frozen. If you change a live visual, update its legend twin in the
   same commit.

---

## Tunable constants (current values — top of `orbit_catch_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kGravityConstant` | 100000 | Overall pull strength / curve drama |
| `_kMinGravDist` | 22 px | Softening radius (singularity guard) |
| `_kMaxLaunchSpeed` / `_kMinLaunchSpeed` | 760 / 230 | Power curve ends |
| `_kDragToSpeedScale` / `_kMaxDragPx` | 2.4 / 220 | Drag→power mapping |
| `_kProjectileRadius` | 7 px | THE physics body (visual potato hugs it) |
| `_kPotatoSpinRate` / `_kPotatoSeed` | 5.2 rad/s / 4.2 | Tumble feel / lump pattern |
| `_kTargetBaseRadius` / `_kTargetMinRadius` | 26 / 13 px | Earth hit zone |
| `_kTargetMoveSpeed` | 58 px/s | Drift levels |
| `_kPointsPerHit` / `_kBonusPerExtraShot` / `_kLevelStepBonus` | 100 / 30 / 12 | Scoring |
| `_kShotsPerLevel` | 4 | Shots before a level rerolls |
| `_kLoopMassGain` / `_kLoopShrink` | 0.18 / 0.10 | Per-loop escalation |
| `_kPreviewSteps` / `_kPreviewDt` | 170 / 0.020 | Preview length/step |

Level shape lives in `_kLevelLadder` (10 blueprints, name + hints +
generator). Generators compose `_giant/_mid/_small` helpers; seeding is
`(level, attempt, loop)` so a layout is stable within an attempt.

---

## Design intent / non-goals

- **DO** keep the preview truthful: it runs the exact flight integrator. If
  you touch the physics, touch `_advanceProjectile` AND `_simulatePath`
  together — forked sims make aiming a lie.
- **DO** preserve the r^1.5 falloff rationale (see the `_kGravityConstant`
  comment): true 1/r² reads as "barely curves at all" at these pixel scales.
- **DON'T** let a level be clearable by a straight shot — coordinates in the
  ladder are chosen so the target needs a curve.
- **DON'T** add raster assets. Canvas / `GameFx` / `PlanetArt` / `PotatoArt`
  only.

---

## Known bugs / TODOs (priority order)

1. **[ORCHESTRATOR — not this agent]** Planet-surface blotch fidelity
   (TODO-7-12-2026 "orbit-catch-3") lives in shared `planet_art.dart`.
2. **[MED — balance]** `humanMax`/star thresholds (2600 / 900·1700·2600)
   predate the Earth/potato pass; retune after the next playtest.
3. **[LOW — feel]** Loaded-potato rock and beacon pulse rates are first-pass;
   candidates for juice tuning at the 13px floor.

---

## Assets

Procedural ONLY. `GameFx.atmosphere/orb/glowLine/text`, `FxBurst`, `FxPop`,
`PlanetArt` (wells), `PotatoArt` (projectile), and raw `Canvas` primitives
(Earth). No PNG/JPEG.
