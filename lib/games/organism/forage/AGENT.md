# AGENT.md — Forage

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/organism/forage/` — the widget + these docs.
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`/`FxParticle`/`FxBurst`/`FxPop`). Do NOT modify them without explicit escalation.
- **Do NOT touch** other games, the registry (`mini_game_registry.dart`), the catalog
  (`game_catalog.dart`), the host (`mini_game_host.dart`), or the router. Registry/catalog wiring is
  done by the orchestrator, not by this agent.

## Scene / exit contract
- The MiniGameHost owns the clock, 3-2-1 countdown, score HUD, results and re-entry. This widget
  renders ONLY the play area and reports points via `session.addScore` / `session.noteStreak`.
- Gate all simulation on `session.isRunning`. While the host counts down (not yet running) render the
  calm "DRAG TO FORAGE" ready state — food drifts, the animal idles, no predators chase.
- The widget resets a fresh run via a `session` phase listener (`_onSession` → `_resetRun`) when the
  host returns to `intro`. Keep that re-entry path intact — it is the **S** (Session) grade.
- If it throws, the host's error boundary must still let the player exit. Don't swallow errors or block exit.

## Files
- Widget: `forage_game.dart` → `class ForageGame extends StatefulWidget`
- Spec: `GAME.md` (canonical rules — obey it; change rules THERE first)
- Education: `EDUCATION.md`
- POTATUHS lens: `POTATUHS.md`

## Architecture (don't regress this)
- **One `Ticker` → one `CustomPainter`.** The painter repaints off a `_RepaintNotifier`; the game does
  NOT call `setState` during play. Per-point `setState` over the tree caused black frames in other games
  (the "harvest lesson").
- Caps: particles ≤120, pops ≤10, predators ≤4, food list = 14 fixed slots (surplus is hidden via
  `respawn`, never grown). Don't lift these without re-checking frame cost.
- All text via `GameFx.text` / `FxPop` (cached `TextPainter`). Don't shape new text every frame.
- The painter reads game state through the `state` reference (read-only). Never mutate from `paint()`.

## The design invariant (do not break)
The whole point is `net energy = intake − expenditure`. Two levers guarantee the lesson and must stay:
1. **Movement costs energy** (`_kMoveCost` × speed), and that cost is **accounted per meal**
   (`_spentSinceMeal`) to grade EFFICIENT vs inefficient. If movement becomes free, the cost-benefit
   lesson dies.
2. **Resting must be viable** — standing still spends only the basal drain, so a player who waits for
   nearby food recovers efficiency. If basal drain ever dominates movement cost so heavily that resting
   is pointless, the budget tension is gone. Keep basal < a full sprint's cost.

## Tunable constants (top of file)
- Animal: `_kAnimalRadius`, `_kMaxSpeed`, `_kSteerLerp`, `_kMoveCost`.
- Energy: `_kMaxEnergy`, `_kStartEnergy`, `_kReviveEnergy`, `_kThriveThreshold`, `_kBasalStart/End`,
  `_kStarvePenalty`, `_kCollapseTime`.
- Food: `_kFoodCountEarly/Peak`, `_kFoodValueMin/Max`, `_kFoodRespawnEarly/Late`.
- Predators: `_kPredCountPeak`, `_kPredStartProgress`, `_kPredSpeed*`, `_kPredFearRadius`,
  `_kPredFearDrain`, `_kPredBite`, `_kPredInvuln`, `_kPredHomingPeak`.
- Calibration `humanMax 600` / stars `[200,400,600]` live in the registry MiniGameSpec, not here — retune by playtest.

## Known TODOs / candidate "accelerate" mechanics
- No drop/resume persistence yet (energy + field state would need serializing).
- No audio (project is Canvas/visual-first — fine, note for parity).
- Candidate extras: cold *zones* (localized high-drain patches you must skirt), seasonal scarcity waves,
  a "cache" mechanic (bank surplus food for later). Keep the rest-vs-chase legibility if added.

## Assets
Canvas-drawn / procedural only — orbs, particles, a couple of emoji glyphs in pop text (⚡). No PNG/JPEG.
