# AGENT.md — Orbital Insertion

> Context for an AI agent working on THIS game (the **A** in GAMES). Read this and GAME.md first.
> Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/solar_systems/orbital_insertion/`
  - Game code: `orbital_insertion_game.dart` (`OrbitalInsertionGame`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`,
  `lib/games/mini_game.dart` — read as needed, **no edits**.
- **Do not touch** other games, other scales, the registry/catalog/host, or `mini_game_page.dart`.
  The orchestrator wires the spec into `mini_game_registry.dart` + `game_catalog.dart` and handles
  swapping out the old "Orbital Mechanic". Do not edit those files.

---

## Scene / exit contract

- `OrbitalInsertionGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, 3·2·1 countdown, score-HUD, and the results/exit screen. The game must
  not reimplement or intercept these.
- `widget.session.isRunning` gates gameplay: input is ignored and laps don't score when false. The
  ticker keeps running so the canvas breathes (atmosphere + a demo orbiting moon), but no points
  accrue. Respect this.
- Report points only via `widget.session.addScore(delta)` and streaks via
  `widget.session.noteStreak(current)`. Never draw a score, timer, or game-over.
- If the game throws, the host's error boundary catches it. Do not swallow exceptions.

---

## Architecture (one ticker → painter)

- Single `AnimationController` (`_ctrl`) drives `_tick()` at ~60 fps → `setState` → `_OrbitPainter`.
  The child tree is just a `CustomPaint` + a tiny HUD `Stack`, so the per-frame `setState` is cheap.
- **Two kinds of moon:**
  - `_Orbiter` — a CAPTURE. Analytic Kepler ellipse, advanced by `dν/dt = h/r²`. Drift-free and
    stable. `_pending` is the one still confirming; `_orbiters` are confirmed and scoring.
  - `_Flier` — a CRASH or ESCAPE. Numerically integrated so you watch it fall in / fly off.
    Transient; removed when it resolves.
- `_classify()` is the single source of truth for outcome + orbital elements (used by both the
  aim-time preview label and the live launch).

---

## Tunable constants (current values — all at the top of `orbital_insertion_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kBaseMu` | `2.6e7` | Gravity strength (mu = G·M). Sets the circular/escape speeds vs the launch power band. Raise → tighter, faster orbits. |
| `_kMaxLaunchSpeed` / `_kMinLaunchSpeed` | `560` / `150` | Drag power range (px/s). The capture window must sit comfortably inside this band. |
| `_kDragToSpeedScale` / `_kMaxDragPx` | `2.3` / `200` | Drag-pixels → speed mapping. |
| `_kConfirmSweep` | `3.7` rad | Angle a capture must sweep before it confirms/scores (~> half orbit). Lower = snappier, less "earned". |
| `_kCaptureBase` | `90` | Flat points per capture. |
| `_kCircularityBonus` | `170` | × (1 − e) at capture — the circular-orbit reward. Raise to push players toward clean circles. |
| `_kStableRingBonus` | `70` | Bonus for a near-circular orbit hugging the target ring. |
| `_kLapBase` / `_kLapCircular` | `10` / `26` | Passive per-lap points (flat + circularity-scaled). |
| `_kSystemBonus` | `16` | × systemIndex per capture — rewards pushing into harder worlds. |
| `_kCapturesPerPlanet` | `3` | Captures before a new (harder) planet. |
| `_kMaxOrbiters` | `6` | Perf cap on simultaneous orbiters. |
| `_kMinGravDist` | `16` | Softening floor for the numeric integrator (never hit by a valid orbit). |

Difficulty ramp lives in `_rollPlanet()`: planet radius shrink, mu jitter, drift onset (round 4),
hazard onset (round 6). Adjust thresholds there.

---

## Known TODOs / ideas (priority order)

1. **[MED] Capture confirm vs near-escape.** A barely-bound, highly eccentric capture sweeps to a
   distant apoapsis slowly, so `_kConfirmSweep` can take a while. Acceptable, but consider confirming
   on "passed first periapsis" as an alternative gate if it ever feels laggy.
2. **[LOW] Hazard vs orbiters.** The debris hazard only collides with the incoming `_Flier`;
   confirmed orbiters ignore it (two-body purity). Fine because the hazard sits on the approach lane,
   but if an orbit visibly clips it, nudge `_hazardFrac` further from typical orbit radii in
   `_rollPlanet()`.
3. **[LOW] Moving-planet frame.** Orbiters are locked to the planet's *current* centre, so a fast
   drift slightly shears the painted ellipse. Movement is kept gentle (`_moveSpeed`/`_moveAmp`
   capped) so it reads fine. Don't crank movement without re-checking.
4. **[INFO] Score calibration.** `humanMax`/`starThresholds` in the registry spec are first-pass —
   retune by playtest once Sessions data exists.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG/JPEG/raster assets.** Planet/moon = `GameFx.orb`,
gravity wells = concentric rings + radial glow, orbits = analytic `Path` ellipses, trails = fading
line segments, preview = colored dots + label, debris = scattered circles, callouts =
`GameFx.text` / `FxPop`. Keep it that way.
