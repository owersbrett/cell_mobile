# AGENT.md — Pursuit

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/planets/orbit_pursuit/`
  - Game code: `orbit_pursuit_game.dart` (`OrbitPursuitGame`)
  - Game docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`,
  `lib/games/mini_game.dart` — read as needed, **no edits**.
- **Do NOT touch** other games (including `planets/orbit_catch/`), other scales, the host/router,
  the registry (`mini_game_registry.dart`), the catalog (`game_catalog.dart`), or
  `mini_game_page.dart`. Registry/catalog wiring is the orchestrator's job, not this agent's.
- **Do NOT import another game's code.** This is a self-contained variant — it reimplements the
  gravity-aim core; it must never `import '../orbit_catch/...'`.

---

## Scene / exit contract

- `OrbitPursuitGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, the 3·2·1 countdown, the score HUD, the results screen, and the exit
  affordance. The game must NOT reimplement or intercept these — it draws only its own in-play HUD
  (shot pips + level label + hint banner).
- The game auto-starts when `widget.session.isRunning` flips true; before that it renders a calm
  ready state (atmosphere + orbits drift; input is ignored). It reports points via
  `session.addScore(...)` and streaks via `session.noteStreak(...)`.
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/planets/orbit_pursuit/orbit_pursuit_game.dart` → `OrbitPursuitGame` |
| Canonical spec | `lib/games/planets/orbit_pursuit/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/planets/orbit_pursuit/EDUCATION.md` |
| POTATUHS lens | `lib/games/planets/orbit_pursuit/POTATUHS.md` |

---

## Architecture (how it works)

- **One ticker.** A single `AnimationController` (`_ctrl`, 1h dummy duration) drives `_tick` at
  ~60fps. `_tick` advances the clock `_t`, integrates the live projectile, ages FX, and `setState`s.
  The whole subtree is a `CustomPaint` + a tiny HUD `Stack`, so per-frame `setState` is cheap. **Keep
  it that way** — do not add big rebuilding widget trees; push new visuals into `_PursuitPainter`.
- **Targets are pure functions of time.** `_MovingTarget.posAt(size, t)` returns a position from a
  closed ellipse. There is no per-frame target state to integrate (only the `caught` flag). The
  painter draws orbit path + ghosts by sampling `posAt` at `t + k·_kGhostStep`.
- **Intercept = live collision.** `_advanceProjectile` checks the projectile against each uncaught
  target's `posAt(size, _t)` every sub-step. Because the target keeps moving in real time, leading is
  an emergent requirement, not scripted.
- **Levels are data.** `_kLevelLadder` is a list of `_LevelBlueprint`s; each `generate(rng, diff,
  hint)` emits a seeded `_Layout`. To add/retune a level, edit a blueprint — nothing else changes.

---

## Tunable constants (current values — all at top of `orbit_pursuit_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kMaxLaunchSpeed` / `_kMinLaunchSpeed` | 760 / 230 | Shot speed range. Faster = shorter travel time = easier lead. |
| `_kDragToSpeedScale` / `_kMaxDragPx` | 2.4 / 220 | Drag → power mapping. |
| `_kGravityConstant` | 240000 | Pull strength. Matches Orbit Catch — keep the curve feel consistent. |
| `_kMinGravDist` | 22 | Softening radius (avoids singularity). |
| `_kPreviewSteps` / `_kPreviewDt` | 170 / 0.020 | Trajectory preview length/resolution. |
| `_kTargetBaseRadius` / `_kTargetMinRadius` | 24 / 12 | Catcher hit radius, easy → hard. |
| `_kGhostStep` | 0.42 | Seconds between future-ghost dots. Smaller = denser, finer lead guide. |
| `_kPointsPerHit` | 100 | Base intercept score. |
| `_kBonusPerExtraShot` | 30 | Spare-shot bonus on level clear. |
| `_kLevelStepBonus` | 12 | Extra base points × level index. |
| `_kLeadBonusMax` | 60 | Cap on the speed-scaled lead bonus per intercept. |
| `_kShotsBase` | 4 | Shots per single-target level (+2 per extra moon). |
| `_kLoopMassGain` / `_kLoopShrink` | 0.18 / 0.10 | Per-loop escalation (heavier wells / smaller catcher). |

Ghost-dot count is derived, not a constant: `_ghostDots = (5 − level·0.45 − loop).clamp(1,5)`.

---

## Known TODOs / tuning ideas (in priority order)

1. **[TUNING] Lead-bonus calibration.** `leadBonus` uses `tangential = angSpeed·(rx+ry)/2·shortSide`
   normalized by `140`. Playtest whether fast retrograde moons over-reward vs. slow circular ones;
   adjust the `/140` divisor or `_kLeadBonusMax`.
2. **[TUNING] Ghost density vs. difficulty.** At loop ≥ 1 the dot count can hit the floor of 1 very
   early. If late loops feel unfair (near-blind leads), raise the floor or soften the `−loop` term.
3. **[POLISH] Multi-moon shot economy.** Multi-moon levels give `+2` shots per extra moon. If players
   stall on `Triple Drift`, consider scaling shots with target speed too.
4. **[POLISH] Off-path comet readability.** Very eccentric, tilted ellipses can clip a screen edge on
   extreme aspect ratios. Generators keep `center`/`rad` conservative, but verify on tall/narrow web
   viewports.
5. **[INFO] One projectile at a time.** A new drag is blocked while a shot is live — intentional
   (keeps the lead read clean). Do not add multi-shot without revisiting the intercept loop.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG/JPEG/raster assets.** Wells, catchers, orbit paths, ghost
dots, the planetlet trail, sparks (`FxBurst`), and score pops (`FxPop`) are all procedural. Keep it
that way. Use `GameFx.orb` / `GameFx.atmosphere` / `GameFx.glowLine` and Potatuhs palette tokens for
visual consistency with the rest of the catalog.
