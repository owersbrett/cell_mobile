# AGENT.md — Orbital Insertion

> Context for an AI agent working on THIS game (the **A** in GAMES). Read this and GAME.md first.
> Stay in scope. The game runs the **v2 CONSTELLATION rules** (continuous multi-moon orbiting) —
> GAME.md is the locked spec; if code and spec disagree, the spec wins and the code gets fixed.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/solar_systems/orbital_insertion/`
  - Game code: `orbital_insertion_game.dart` (`OrbitalInsertionGame`)
  - Legend: `orbital_insertion_legend.dart` (intro-carousel visual manual)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`,
  `lib/games/mini_game.dart`, `lib/games/planet_art.dart` — read as needed, **no edits**.
- **Do not touch** other games, other scales, the registry/catalog/host, or `mini_game_page.dart`.
  The orchestrator owns `mini_game_registry.dart` + `game_catalog.dart`. Do not edit those files.

---

## Scene / exit contract

- `OrbitalInsertionGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, 3·2·1 countdown, score-HUD, and the results/exit screen. The game must
  not reimplement or intercept these. No internal game-over — collisions and losses cost points
  and moons, never end the run.
- `widget.session.isRunning` gates gameplay: input is ignored, laps don't score, captures don't
  confirm, and collisions aren't processed when false. The ticker keeps running so the canvas
  breathes (atmosphere + existing moons keep orbiting), but no state that matters changes.
- Report points only via `widget.session.addScore(delta)` (negative deltas for collisions — the
  session floors the score at 0) and streaks via `widget.session.noteStreak(current)`. Never draw
  a score, timer, or game-over.
- If the game throws, the host's error boundary catches it. Do not swallow exceptions.

---

## Architecture (one ticker → painter)

- Single `Ticker` (`_ticker`) drives `_onTick()` with **real elapsed-dt** (never `const 1/60`) →
  `setState` → `_OrbitPainter`. The child tree is just a `CustomPaint` + a tiny HUD `Stack`, so
  the per-frame `setState` is cheap. All continuous motion lives on the painter.
- **Two kinds of moon, both plural (v2):**
  - `_moons: List<_Orbiter>` — captures, pending AND confirmed in one list (`pending` flag).
    Analytic Kepler ellipse, advanced by `dν/dt = h/r²`. Drift-free and stable. `lapFlash`
    drives the per-revolution ring-pulse.
  - `_fliers: List<_Flier>` — crashes/escapes mid-flight, numerically integrated. Transient.
- **Collisions** (`_resolveCollisions`): O(n²) pairwise over every live moon (orbiter, pending,
  flier) past its `_kSpawnGrace`; hit radius = `2 × _kMoonRadius × the cosmetic 1/zoom boost`
  (matches the DRAWN size). One `−_kCollisionPenalty` per pair; both destroyed. Runs only while
  `isRunning`. Fleet is hard-capped at `_kMaxMoons`, so n ≤ 12 — never optimize this
  prematurely.
- **One planet per run** (`_rollPlanet()` in `initState` only). Escalation is **time-phased** on
  `_runT` (seconds of running play): mass swell (`_mu` getter), drift (`_planetMoves`/`_moveAmp`,
  phase measured from onset so there's no positional snap), hazard fade-in (`_hazardAlpha`).
- `_classify()` is the single source of truth for outcome + orbital elements; `_judge()` layers
  the containment verdict on top. Both the aim-time preview label and the live launch go through
  the same pipeline — **never let them diverge**.
- The planet body renders via the shared **`PlanetArt`** (`skin` computed once in `_rollPlanet`,
  stored in `_planetSkin`, painted with the live `t`). Gravity-well glow + pull rings are
  game-side (they're mechanics telegraphs, not planet art).

---

## Tunable constants (current values — all at the top of `orbital_insertion_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kBaseMu` | `2.6e7` | Base gravity (mu = G·M), jittered ±~18% per run. Sets circular/escape speeds vs the launch power band. |
| `_kMaxLaunchSpeed` / `_kMinLaunchSpeed` | `560` / `150` | Drag power range (px/s). The capture window must sit comfortably inside this band — including at max mass swell. |
| `_kDragToSpeedScale` / `_kMaxDragPx` | `2.3` / `200` | Drag-pixels → speed mapping. |
| `_kConfirmSweep` | `3.7` rad | Angle a capture must sweep before it confirms/scores (~> half orbit). |
| `_kCaptureBase` / `_kCircularityBonus` | `40` / `60` | Capture payout (flat + ×(1−e)). Deliberately smaller than v1 — laps are the engine now. |
| `_kStableRingBonus` | `30` | Bonus for a near-circular orbit hugging the target ring. |
| `_kLapBase` / `_kLapCircular` | `25` / `25` | Per-lap points (flat + circularity-scaled). The primary income. |
| `_kLapCrowdBonus` / `_kLapCrowdCap` | `5` / `30` | Per-lap crowd sweetener: ×(other confirmed moons), capped. The bait to over-crowd. |
| `_kCollisionPenalty` | `60` | Deducted once per colliding pair; both moons destroyed. |
| `_kMaxMoons` | `12` | Hard perf/fleet cap (orbiters + fliers). Launcher refuses at cap (SKY FULL). |
| `_kLaunchCooldown` | `0.25` s | Gesture-debounce between launches. Keep tiny — the no-pause flow IS the redesign. |
| `_kSpawnGrace` | `0.45` s | A moon younger than this can't collide (both pair members must be past it). |
| `_kSwellStart` / `_kSwellMax` | `18` s / `+40%` | Mass-swell escalation: mu ramps linearly to base×1.4 at 60s. |
| `_kDriftStart` / `_kDriftAmpMax` / `_kDriftEaseIn` / `_kDriftSpeed` | `28` s / `0.09` w / `6` s / `0.8` rad/s | Drift escalation. Phase starts at 0 at onset (no snap). |
| `_kHazardStart` / `_kHazardFadeIn` | `40` s / `1.5` s | Debris hazard fade-in. Kills incoming fliers only (fully faded-in before it's lethal). |
| `_kMinGravDist` | `16` | Softening floor for the numeric integrator. |
| `_kContainFactor` | `1.4` | Deep-space boundary = this × stable-ring radius. Max survivable apoapsis. |
| `_kViewPadFrac` / `_kMinZoom` / `_kMaxZoom` | `0.08` / `0.22` / `1.0` | Camera fit. Zoom is static for the WHOLE run — the fit always budgets `_kDriftAmpMax`. |
| `_kMaxVisualBoost` | `2.8` | Cap on the `1/zoom` boost for cosmetic sizes — also scales the collision radius. |

**Camera/containment invariants:** all world-space drawing goes through the single
`canvas.save/translate/scale` transform in `_OrbitPainter.paint`; screen-space overlays (bursts,
pops, banner, drag guide) draw after `restore`. Fliers are culled radially at `_containRadius`.
The zoom must never change mid-run (drift budget is pre-baked into `_zoomFor`).

**autoPilot** (`_autoStep`, interval 1300 ms): tangential launches at 0.94–1.06 × v_circ, one
handedness, capped at 5 moons — a live constellation for ATTRACT without instant self-collision.
If you retune `_kContainFactor`, re-check the bot's speed ceiling: tangential apoapsis
`= r·k²/(2−k²)` must stay ≤ `_kContainFactor × r` (at 1.4 that means k ≤ ~1.08).

---

## Known TODOs / ideas (priority order)

1. **[TUNE] Score calibration for v2.** Lap/collision/crowd numbers are first-pass from the spec;
   `humanMax`/`starThresholds` in the registry spec were set for v1 one-at-a-time scoring and
   likely need a raise (a good v2 run has 4–6 moons lapping concurrently). Registry values are
   the orchestrator's to change — report, don't edit.
2. **[MED] Collision fairness at the pad.** All orbits pass through the launch radius, so the pad
   region is the hot zone. `_kSpawnGrace` covers the launch moment; if playtests show unfair
   deletions just after grace, consider extending grace or excluding the pending-confirm window.
3. **[LOW] Mass swell vs frozen conics.** Captured orbits keep their locked ellipse while `mu`
   swells (deliberate abstraction, documented in GAME.md/EDUCATION.md). If it ever reads wrong,
   the honest alternative — re-deriving each orbiter's elements as mu changes — would also make
   old orbits slowly decay, which could be a feature. Spec change first.
4. **[LOW] Hazard vs orbiters.** The debris hazard only collides with incoming `_Flier`s;
   confirmed orbiters ignore it (two-body purity). Fine because the hazard sits on the approach
   lane; if an orbit visibly clips it, nudge `_hazardFrac` in `_rollPlanet()`.
5. **[LOW] Moving-planet frame.** Orbiters are locked to the planet's *current* centre, so drift
   slightly shears the painted ellipse. Amplitude is capped small; don't crank `_kDriftAmpMax`
   or `_kDriftSpeed` without re-checking.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG/JPEG/raster assets.** Planet = shared `PlanetArt`
(+ game-side gravity glow/pull rings), moons = `GameFx.orb`, orbits = analytic `Path` ellipses,
trails = fading line segments (hard-capped: orbiters 30 pts, fliers 48), preview = colored dots
+ label, debris = scattered circles, lap pulse = an expanding stroked circle, callouts =
`GameFx.text` / `FxPop`. Keep it that way.
