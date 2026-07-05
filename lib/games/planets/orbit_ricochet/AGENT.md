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
- **Do NOT import another game's code.** This is a self-contained variant — the direct-aim core is
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

- **One `Ticker`** (elapsed-dt, clamped ≤0.04s) drives `_onTick` at ~60fps. All simulation
  (straight-line flight, reflection, catch/fizzle detection, scoring) and all FX live on this single
  ticker. There is exactly ONE `setState` per tick.
- **One `CustomPainter`** (`_RicochetPainter`, `shouldRepaint => true`) draws everything: atmosphere,
  walls, bodies, catcher, cannon, aim, cue preview, projectile, FX. No per-frame setState over a big tree.
- **Physics is PURE BILLIARDS — no mid-flight gravity.** The well-ring visuals are dressing; `mass`
  only sizes them. `_advanceProjectile` runs 10 sub-steps/frame (anti-tunneling only). Per sub-step:
  integrate straight-line position → reflect off bodies (mirror about normal × restitution, push clear
  of the surface, score +30 via `_registerBodyBounce`) → reflect off the four walls (ONE contact even
  in a corner, −15 clamped via `_registerWallBounce`) → check catch → check fizzle. Do NOT reintroduce
  gravity: the straight flight is what makes the cue preview exactly truthful, and it is the deliberate
  differentiation from Orbit Catch (the gravity sibling).
- **Scoring by surface:** bodies pay (+30 live, `bodyBounces` counts toward the +55/bank at the catch);
  walls cost (−15 live, clamped against `session.score` so the total never drops below 0; never credit
  a bank). A catch scores `100 + bodyBounces×55 + spares×25 + level/loop step`.
- **Cue preview:** `_buildCue` ray-casts the aim ray (`_castRay`: exact line-vs-circle / line-vs-wall)
  and returns `(impact, stubEnd, body, catcher)`. The painter draws a straight line cannon→impact, a
  pulsing ring at the contact, and a reflected-direction stub. Gold = pot/body; warning orange = wall.
  Because flight is straight, this preview is exact — keep it that way.
- **Autopilot:** `_autoStep` → `_autoAimDir`: direct pot if the line is clear, else sweep ±60° for a
  one-carom BODY-bank route via the same ray-cast, else fire at the blocker.
- **Layouts:** data-driven `_kLevelLadder` of `_LevelBlueprint`s. Each `generate(rng, diff, hint)`
  emits a seeded `_Layout`. The seed is `(level, attempt, loop)` so variations rotate deterministically.
  Intended solutions route off BODIES (a blocker sits on the direct line; the graze is the paying
  solve); walls stay reflective but costed. **To add/retune a level, edit the ladder — no other code
  changes.**

PERFORMANCE is a real bug-class here (black screen / jitter from build overload). Keep the
single-ticker + single-painter discipline. Do NOT add per-particle widgets or nested setState.

---

## Tunable constants (current values — all in `orbit_ricochet_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kBodyRestitution` | 0.90 | Bounce energy off planets/asteroids. Lower = banks die faster. |
| `_kWallRestitution` | 0.94 | Bounce energy off walls. |
| `_kMaxBounces` | 16 | Hard cap so a shot can't pinball forever. Lower to end shots sooner. |
| `_kBaseFlightTime` | 7.2 | Easy-difficulty flight budget (shrinks via `_flightTime`). |
| `_kMinFlightSpeed` | 70 | Crawl-speed fizzle threshold. |
| `_kBodyBounceScore` | 30 | Live points per body carom. Raise to make caroms themselves the game. |
| `_kWallPenalty` | 15 | Live deduction per wall carom (clamped so score floors at 0). |
| `_kBankBonus` | 55 | Bonus per BODY carom on the catch. Raise to make banking dominate scoring. |
| `_kPointsPerHit` | 100 | Base catch score. |
| `_kBonusPerExtraShot` | 25 | Bonus per spare shot at clear. |
| `_kShotsPerLevel` | 4 | Shots before a level rerolls (no demotion). |
| `_kCueStubLen` | 64 | px length of the reflected-direction preview stub. |
| `_kMaxLaunchSpeed` / `_kMinLaunchSpeed` | 720 / 240 | Power range from drag length. |
| `_kLoopMassGain` / `_kLoopShrink` | 0.16 / 0.10 | Loop escalation (body heft up, catcher down). |

`_flightTime` derives from difficulty: `(7.2 − difficulty·0.7).clamp(3.6, 7.2)` — the "faster decay".

---

## Known bugs / TODOs (priority order)

1. **[MED] A shot that misses everything bleeds.** It caroms the walls until its flight budget dies,
   −15 per hit. Intentional (walls cost), but playtest the worst case; tune `_kWallPenalty` /
   `_kBaseFlightTime` if misses feel too punishing.
2. **[LOW] No SFX.** Bounce/catch feedback is visual only. Add audio if the framework grows a sound kit.
3. **[LOW] No in-session restart.** Host owns replay — do not add one here.
4. **[INFO] Body `mass` is visual heft only.** It sizes the well-ring dressing and labels; it never
   pulls the shot. Asteroids carry tiny mass (0.05) so they draw ringless. Don't reintroduce physics
   through it.

---

## Canvas-only rule

All rendering is `CustomPainter` + `GameFx`. **No PNG/JPEG/raster assets.** Bodies, asteroids, walls,
catcher, cannon, aim arrow, preview dots, projectile trail, and bursts are all drawn procedurally.
Keep it that way.
