# AGENT.md — Stellar Evolution

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)
- **Work only within:** `lib/games/solar_systems/stellar_evolution/`
  (`stellar_evolution_game.dart`, GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`),
  `lib/theme/potatuhs.dart`, `package:flutter/*`, `dart:math`, `dart:ui`.
- **Do not touch** other games, other scales, the registry, the catalog, the host/router, or
  `mini_game_page.dart`. This module imports no other game.

---

## Scene / session contract
- `StellarEvolutionGame({required MiniGameSession session})` — self-contained.
- The **host owns** the 60s clock, countdown, score total and results screen. This widget:
  - renders the **play area only** (no duplicate timer/score chrome),
  - gates ALL simulation on `session.isRunning` (no points or sim when not running),
  - auto-starts its first star on the first running frame; shows a calm idle star otherwise,
  - reports points via `session.addScore`, streaks via `session.noteStreak`.
- It does **not** call `endEarly` — the run is open-ended (many star lives) and ends when the host
  clock hits 0.

## Performance contract
- ONE `AnimationController` (`_ticker`, duration days:1) drives both the sim (`_onTick`) and the
  painter (`super(repaint: s._ticker)`). **No per-frame `setState`** — input handlers mutate model
  fields and the ticker repaints. Keep it that way.

---

## Architecture
- `_Phase` enum is the state machine: `ready → nebula → protostar → mainSequence → giant →
  {shed | supernova} → endpoint → (new star)`. The fork at `giant` is decided by `_isHighMass`
  (`_mass >= _kHighMassThreshold`).
- `_beginPhase` initialises per-phase action state; `_updatePhase` runs continuous sim;
  `_onTapDown` is the single input. `_complete` flags a phase cleared (combo++, score) then
  `_advance` routes to the next phase. `_awardEndpoint` pays the destiny bonus.
- Action mechanics: MASH (nebula/giant/shed), TIMED-TAP (protostar/supernova via `_timedTap`),
  BALANCE (main sequence — `_needle` drifts down under gravity, taps push it up).

## Tunables (top of file)
Time budgets `_k*Time`, mash targets `_k*TapsBase`, timed windows `_k*WindowBase`/sweep rates,
balance `_kGravityBase`/`_kFusionImpulse`/`_kBalanceBand`/`_kStableTarget`, mass thresholds, and
all `_k*Pts` scoring. Difficulty scales these via `_difficulty` (= stars completed). Tune by
playtest; keep GAME.md in sync first.

## Calibration (registry, do NOT edit from here)
`humanMax: 900`, `starThresholds: [300, 600, 900]`. Re-tune from real plays.

## TODO / ideas
- Potato-context flare per endpoint (the "every atom in a potato was forged in a star" beat) — see
  EDUCATION.md. Non-blocking text line, fades like the banner.
- Optional: let very fast nebula accretion visibly drag the destiny label as mass crosses 8 M☉,
  to dramatise player agency over fate.
