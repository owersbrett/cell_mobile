# AGENT.md — Ricochet

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/planets/orbit_ricochet/`
  - Game code: `orbit_ricochet_game.dart` (`OrbitRicochetGame`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`.
  Read as needed; **no edits**.
- **Do NOT touch:** any other game (including the base `planets/orbit_catch/`), the registry
  (`mini_game_registry.dart`), the catalog (`game_catalog.dart`), the host, `mini_game_page.dart`, or
  anything outside this folder. Wiring this game into the registry is the orchestrator's job, not yours.
- **Do NOT import another game's code.** This is a self-contained variant — the gravity-aim core is
  re-implemented here on purpose (the EXTRACTION_RECIPE dependency rule). If you need a shared helper,
  inline a private copy.

---

## Scene / exit contract

- `OrbitRicochetGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the 3·2·1 countdown, the timer, the score HUD, the results screen, and the exit/replay
  affordance. The game must NOT reimplement or intercept any of these. It draws only its own in-play
  HUD (shot pips, level label, hint banner).
- Gameplay is gated on `widget.session.isRunning`. When false, the ticker still runs but only animates
  atmosphere (no sim advance, no input). Auto-start: play begins the moment `isRunning` flips true —
  the calm "ready" state is just the rendered field with no live shot.
- Report points via `widget.session.addScore(delta)` and combos via `widget.session.noteStreak(streak)`.
- If the game throws, the host's error boundary shows a fallback. Never swallow exceptions silently.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/planets/orbit_ricochet/orbit_ricochet_game.dart` → `OrbitRicochetGame` |
| Canonical spec | `lib/games/planets/orbit_ricochet/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/planets/orbit_ricochet/EDUCATION.md` |
| POTATUHS lens | `lib/games/planets/orbit_ricochet/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` (orchestrator-owned; id `orbit_ricochet`) |

---

## Architecture (how the loop runs — match this if you extend it)

- **One `AnimationController`** (`_ctrl`, vsync, infinite duration) drives `_tick` at ~60fps. All
  simulation (gravity integration, reflection, catch/fizzle detection) and all FX live on this single
  ticker. There is exactly ONE `setState` per tick.
- **One `CustomPainter`** (`_RicochetPainter`, `shouldRepaint => true`) draws everything: atmosphere,
  walls, bodies, catcher, cannon, aim, preview, projectile, FX. No per-frame setState over a big tree.
- **Physics:** `_advanceProjectile` runs 10 sub-steps/frame. Per sub-step: apply gravity from all
  bodies → integrate position → reflect off bodies (mirror about normal × restitution, then push the
  projectile clear of the surface) → reflect off the four walls → check catch → check fizzle.
- **Preview:** `_buildPreview` mirrors that physics with its own dt and returns `(pts, firstBounce)`.
  The painter draws it bright up to `firstBounce`, faint after, and rings the first-bounce point.
- **Layouts:** data-driven `_kLevelLadder` of `_LevelBlueprint`s. Each `generate(rng, diff, hint)`
  emits a seeded `_Layout`. The seed is `(level, attempt, loop)` so preview and live shot agree and
  variations rotate. **To add/retune a level, edit the ladder — no other code changes.**

PERFORMANCE is a real bug-class here (black screen / jitter from build overload). Keep the
single-ticker + single-painter discipline. Do NOT add per-particle widgets or nested setState.

---

## Tunable constants (current values — all in `orbit_ricochet_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kGravityConstant` | 205000 | Curve strength. Raise for more dramatic bends; lower for straighter banks. |
| `_kBodyRestitution` | 0.90 | Bounce energy off planets/asteroids. Lower = banks die faster. |
| `_kWallRestitution` | 0.94 | Bounce energy off walls. |
| `_kMaxBounces` | 16 | Hard cap so a shot can't pinball forever. Lower to end shots sooner. |
| `_kBaseFlightTime` | 7.2 | Easy-difficulty flight budget (shrinks via `_flightTime`). |
| `_kMinFlightSpeed` | 70 | Crawl-speed fizzle threshold. |
| `_kBankBonus` | 55 | Bonus per bounce on the catch. Raise to make banking dominate scoring. |
| `_kPointsPerHit` | 100 | Base catch score. |
| `_kBonusPerExtraShot` | 25 | Bonus per spare shot at clear. |
| `_kShotsPerLevel` | 4 | Shots before a level rerolls (no demotion). |
| `_kMaxLaunchSpeed` / `_kMinLaunchSpeed` | 720 / 240 | Power range from drag length. |
| `_kLoopMassGain` / `_kLoopShrink` | 0.16 / 0.10 | Loop escalation (mass up, catcher down). |

`_flightTime` derives from difficulty: `(7.2 − difficulty·0.7).clamp(3.6, 7.2)` — the "faster decay".

---

## Known bugs / TODOs (priority order)

1. **[MED] Preview drift on long multi-bank shots.** Preview uses its own dt; after several bounces it
   diverges slightly from the live sub-stepped shot. The first bounce (rendered bright + ringed) is
   accurate. If you want full-path fidelity, share one integrator between preview and live sim.
2. **[LOW] No SFX.** Bounce/catch feedback is visual only. Add audio if the framework grows a sound kit.
3. **[LOW] No in-session restart.** Host owns replay — do not add one here.
4. **[INFO] Asteroids carry tiny mass (0.05), not zero.** Negligible pull, intentional, so they read as
   reflectors but still belong to the same body list/physics path. Don't special-case them to zero.

---

## Canvas-only rule

All rendering is `CustomPainter` + `GameFx`. **No PNG/JPEG/raster assets.** Bodies, asteroids, walls,
catcher, cannon, aim arrow, preview dots, projectile trail, and bursts are all drawn procedurally.
Keep it that way.
