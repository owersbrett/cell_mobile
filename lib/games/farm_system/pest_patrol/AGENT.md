# AGENT.md — Pest Patrol

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/farm_system/pest_patrol/` — the widget + these docs.
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`FxParticle`/`FxBurst`/`GameFx`), `lib/theme/potatuhs.dart`. Do NOT modify them without explicit
  escalation.
- **Do NOT touch** other games, the registry (`mini_game_registry.dart`), the catalog
  (`game_catalog.dart`), the host (`mini_game_host.dart`), or the router. Registry/catalog wiring is
  done by the orchestrator, not by this agent.

## Scene / exit contract
- The MiniGameHost owns the clock, 3-2-1 countdown, score HUD, results and re-entry. This widget
  renders ONLY the play area and reports points via `session.addScore` / `session.noteStreak`.
- Gate all simulation on `session.isRunning`. While the host counts down (not yet running) render a
  calm, near-still field (a few aphids drifting, bees idling) — never an active swarm.
- If it throws, the host's error boundary must still let the player exit and continue the session.
  Don't swallow errors or block exit on game state.

## Files
- Widget: `pest_patrol_game.dart` → `class PestPatrolGame extends StatefulWidget`
- Spec: `GAME.md` (canonical rules — obey it; change rules THERE first)
- Education: `EDUCATION.md`
- POTATUHS lens: `POTATUHS.md`

## Architecture (don't regress this)
- **One `Ticker` → one `CustomPainter`.** The painter repaints off a `_RepaintNotifier`
  (`CustomPaint(painter:)` with `repaint:`); the game does NOT call `setState` during play. This is
  the "harvest lesson" — per-point `setState` over the whole tree caused black frames in other games.
- The painter reads state through the tiny `_StateView` extension (read-only getters). Keep it
  read-only; never mutate from the painter.
- Capped counts: pests ≤16, beneficials ≤8, bees 4, particles ≤130, popups ≤10. Don't lift these
  without re-checking frame cost.
- All `_glyph`/emoji via `TextPainter`; pests are cheap canvas shapes (legs + orb) to keep
  per-frame `TextPainter` count low. If you add pest types, keep them shape-drawn, not emoji.

## Tunable constants (top of file)
- Pests: `_kPestMaxAlive`, `_kPestSpeedBase/Scale`, `_kPestNibble`, `_kSpawnBase/Min`.
- Beneficials: `_kBenMaxAlive`, `_kBenSpeed`, `_kBenLife`, `_kBenEatRadius`, `_kDeployCooldown`.
- Crop/economy: `_kCropRegen`, `_kHealthDividend`, `_kPollinatorDividend`.
- Spray trap: `_kSprayPenalty`, `_kSprayResistance`, `_kSprayCooldown`, `_kResistanceMax/Decay`,
  `_kBenLostPenalty`.
- Scoring: `_kSmartKill`, `_kComboMax`. Calibration: `humanMax 800`, stars `[250,500,750]` — retune
  by playtest (set in the registry MiniGameSpec, not here).

## The design invariant (do not break)
Spraying must always net **negative** versus matched biocontrol over the round. If a balance change
makes spamming SPRAY the optimal strategy, the game has lost its entire point. The three levers that
guarantee the trap: outright point cost, resistance shrinking the dividend, and resistance making
survivors faster/hungrier. Keep all three.

## Known TODOs
- No drop/resume persistence yet (GAME.md lists the state to serialize).
- No audio (project is Canvas/visual-first — fine, note for parity).
- Parasitoid wasps / trap crops are candidate extra mechanics for an "accelerate" pass; keep the
  1-predator-per-pest legibility if added.

## Assets
Canvas-drawn / procedural + a handful of emoji glyphs ONLY (🐞 🦗 🐦 ☠). No PNG/JPEG.
