# AGENT.md — Osmosis

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/cell/osmosis/` — the game widget
  (`osmosis_game.dart` → `OsmosisGame` / `_OsmosisGameState` / `_OsmosisPainter`) and these docs
  (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`, `FxParticle`, `FxBurst`, `FxPop`), `lib/theme/potatuhs.dart`. Read as needed; **no
  edits** without explicit escalation.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or `mini_game_page.dart`.

---

## Dependency rule (from EXTRACTION_RECIPE.md)

This module imports **only** `dart:math`, `package:flutter/material.dart`,
`package:flutter/scheduler.dart`, `../../mini_game.dart`, and `../../fx.dart`. It defines **no**
external symbols and depends on **no other game**. Keep it that way — isolation over DRY.

---

## Scene / exit contract

- `OsmosisGame` takes a `MiniGameSession` and is fully host-driven.
- `widget.session.isRunning` gates the whole simulation (drift, flux, scoring). When false the
  game shows a **calm ready state** and auto-starts when the host flips `isRunning`.
- Scores go through `widget.session.addScore(n)`; the streak high-water mark through
  `widget.session.noteStreak(_healthyStreak)`.
- The host owns the 60 s clock, countdown, score HUD and results. The game renders **only the
  play area** and never builds a results/restart screen. If it throws, the host error boundary
  catches it — never swallow exceptions.

---

## Performance contract

- **One `Ticker` → one `setState({})` → one `CustomPaint`.** No per-frame setState over a widget
  tree; the build tree is a single `GestureDetector` wrapping one `CustomPaint`.
- `dt` is clamped to `0.05 s` so a stutter can't teleport the simulation.
- Keep the painter cheap: it is a handful of paths/circles + the shared `GameFx.atmosphere`.
  Do not add raster assets, extra tickers, or nested `CustomPaint`s.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/cell/osmosis/osmosis_game.dart` → `OsmosisGame` |
| Canonical spec | `lib/games/cell/osmosis/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/cell/osmosis/EDUCATION.md` |
| POTATUHS lens | `lib/games/cell/osmosis/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` (id `osmosis`, `BioScale.cell`) — read-only here |

---

## Tunable constants (current values — all top-of-file in `osmosis_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kBandMin` / `_kBandMax` | 0.38 / 0.62 | Width of the safe isotonic band. Widen = easier. |
| `_kBandCentre` | 0.50 | Healthy turgor target / reset volume. |
| `_kFlux` | 0.20 | Osmosis strength. Higher = volume swings faster for a given tonicity. |
| `_kLyseAt` / `_kCrenateAt` | 0.96 / 0.04 | Burst / shrivel thresholds. |
| `_kHealthyPointsPerSec` | 6.0 | In-band score drip. |
| `_kRecoveryBonus` | 35 | Points for re-entering the band. |
| `_kInjectReturn` | 1.4 | How fast the pump eases to neutral when untouched. |
| `_kDriftRangeBase` / `_kDriftRangeGain` | 0.35 / 0.55 | Drift swing range early → late. |
| `_kRetargetBase` / `_kRetargetGain` | 2.4 / 1.5 | Seconds between drift re-rolls early → late. |
| `_kDriftEaseBase` / `_kDriftEaseGain` | 1.4 / 2.6 | Drift approach speed early → late. |
| `_kIsoTol` | 0.06 | Tonicity magnitude under which we call it isotonic (no flux arrows). |

---

## Known TODOs

1. **[LOW] Drop-and-resume not persisted.** `_volume`/`_drift`/`_inject`/recoveries reset on
   mount. Only matters if the host gains a persist mechanism.
2. **[LOW] Star thresholds are a first estimate** (`[220, 450, 700]`, `humanMax 700`). Re-tune
   from real playtests — a clean run hovering near isotonic should land ~3 stars.
3. **[INFO] `shouldRepaint` returns true.** Correct here — the painter is fed fresh fields every
   ticked frame.

---

## Canvas-only rule

All rendering is `CustomPainter` via `GameFx` + raw `Canvas`. **No PNG/JPEG/raster assets.** The
painter draws: tinted solution field + solute dots, water-flux arrows across the membrane, the
crenating/swelling membrane path with cytoplasm gradient and nucleus, the top tonicity meter, the
right cell-size gauge, the bottom injection slider, the state caption, event callouts, and
`FxBurst`/`FxPop` juice.
