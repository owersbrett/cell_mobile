# AGENT.md — Space Rush

> Context for an AI agent working on THIS game. Read this and GAME.md first, then EDUCATION.md.
> Stay in scope.

---

## What this is

A WarioWare-style **microgame gauntlet** on solar-system bodies. One widget (`SpaceRushGame`) runs a
string of ~2-second micro-challenges, each a self-contained `_MicroGame` (DODGE / CATCH / LAND / SPIN /
SORT / TILT / FLARE). The whole game is a single file driven by ONE ticker and ONE painter.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/solar_systems/space_rush/`
  - `space_rush_game.dart` — the widget, the state machine, all `_MicroGame` subclasses, the painter.
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`,
  `lib/models/bio_entity.dart` — read as needed, **no edits**.
- **Do NOT touch:** `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`, any other
  game folder, or anything outside this folder. The orchestrator wires the registry/catalog spec
  (`id: space_rush`). Flag registry needs here; do not make them.

---

## Scene / exit contract

- `SpaceRushGame` is a registry mini-game driven by `MiniGameSession`.
- `widget.session.isRunning` gates the loop: `_onTick` returns early until the host enters play; the
  internal round machine auto-starts (`_startGame`) on the first running tick. Before that, a calm
  starfield ready state shows (the host overlays its countdown).
- Score via `widget.session.addScore(1)` per cleared microgame; streak high-water via
  `widget.session.noteStreak(_round)`.
- Out of lives → `widget.session.endEarly()`. The game does **not** draw its own timer/intro/results;
  the host owns those. Never swallow exceptions — the host's error boundary handles throws.

---

## Anatomy

| Piece | Where | Notes |
|---|---|---|
| Widget + state machine | `_SpaceRushGameState` | phases: preGame → instruction → playing → result → speedUp; lives, round, difficulty |
| Abstract microgame | `_MicroGame` | `init/update/paint/isComplete` + `onDown/onMove/onUp`; `title/hint/fact/tint` |
| Microgames | `_DodgeGame`, `_CatchGame`, `_LandGame`, `_SpinGame`, `_SortGame`, `_TiltGame`, `_FlareGame` | each tiny, owns its own small lists |
| Painter | `_SpaceRushPainter` | atmosphere + starfield, then per-phase draw; instruction card shows the fact |
| Helpers | `_miniBar`, `_slideArrow`, `_dragGlyph`, `_drawStars`, `_burst` | shared draw utils |

## Tunable constants (top of file)

| Constant | Value | Tune for |
|---|---|---|
| `kRoundTimeStart` / `kRoundTimeMin` / `kRoundTimeDrop` | 3.0 / 1.3 / 0.18 | per-round play window + how fast it shrinks |
| `kInstructionTimeStart` / `kInstructionTimeMin` | 0.75 / 0.30 | how long the prompt flashes |
| `kDifficultyCapRound` | 10 | round at which `_difficulty` hits 1.0 |
| `kResultDuration` / `kSpeedUpDuration` | 0.32 / 0.55 | win/lose flash + WARP UP flash |

Per-microgame difficulty knobs live inside each class's `init(size, rng, diff)` (counts, speeds,
windows, tolerances). Keep each microgame **tiny** and self-contained — the black-screen lesson is
render-cost overload, so don't add heavy per-frame subtrees or raster assets.

## Adding / editing a microgame

1. Subclass `_MicroGame`; implement `title` (one word), `hint`, `fact` (one science beat), `tint`,
   and `init/update/paint/isComplete` (+ pointer hooks as needed).
2. Add an instance to `_gamePool` in `initState`. Clear condition = `isComplete`; failing = the round
   timer expiring (there is no per-microgame fail flag — design clears, not deaths).
3. `flutter analyze lib/games/solar_systems/space_rush/` → 0 issues.

Registry spec (`humanMax`, `starThresholds`, accent, icon) is OUT OF SCOPE — it's the literal in
`GAME.md`; flag changes for the orchestrator.
