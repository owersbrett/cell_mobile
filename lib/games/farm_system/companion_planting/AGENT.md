# AGENT.md — Companion Planting

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/farm_system/companion_planting/`
  - Game code: `companion_planting_game.dart` (`CompanionPlantingGame` /
    `_CompanionPlantingGameState` / `_GardenPainter`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only framework:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart`. Do NOT modify.
- **Do not touch** other games, the host/router, `mini_game_registry.dart`, or
  `game_catalog.dart` without explicit escalation. (Registry/catalog wiring is done
  by the orchestrator, not this agent.)

---

## Scene / exit contract

- The HOST owns the clock, the 3·2·1 countdown, the score HUD and the results screen.
  This widget renders ONLY the play area.
- Drive everything from `widget.session`: gate the tick on `session.isRunning`, report
  points via `session.addScore`, report flawless-plot runs via `session.noteStreak`.
- Do NOT draw a run timer, a final score, or a game-over/restart screen — the host does
  all of that. Never trap the player.
- One `AnimationController` (Ticker) drives one `CustomPainter`. Do not add a second
  ticker or per-frame `setState` over a large widget tree.

---

## Files

| Role | Path |
|---|---|
| Game widget | `companion_planting_game.dart` → `CompanionPlantingGame` |
| Canonical spec | `GAME.md` (rules live here — update first, then code) |
| Education | `EDUCATION.md` |
| POTATUHS lens | `POTATUHS.md` |

---

## Architecture notes

- **Relationships** are the heart of the game. `_kFriendPairs` / `_kFoePairs` are
  symmetric pair lists; `_kRelations` is built once into a `Map<int,int>` keyed by
  `_pairKey` (order-independent). `_relation(a,b)` returns +1 / 0 / −1. To tune the
  biology, edit the pair lists — nothing else.
- **Palette/plot ramp** lives in `_paletteForLevel` and `_plotForLevel`, keyed off
  `_level = _plotsCompleted` (capped at 6). Early levels are deliberately foe-free.
- **Geometry** is computed in `_computeGrid` (grid origin + cell size from the play
  area) and `_layoutHand` (tray). Both run on size change. `_cellAt` / `_cellCenter` /
  `_neighbors` are the shared hit-test + adjacency helpers.
- **Phases**: `_Phase.placing` → drag tiles until the plot fills → `_Phase.growth`
  (≈1.6 s thrive/wilt animation, award fires once via `_growthAwarded`) → next plot.

---

## Tunable constants (current values)

| Knob | Value | Tune for |
|---|---|---|
| Friend points | +12 / neighbour | Reward weight for good adjacency. |
| Combo bonus | `combo × 4` | How much sustained clean play pays. |
| Thrive bonus | `8 × net` | Growth-phase payoff for well-surrounded plants. |
| Flawless bonus | `25 + level × 10` | The clean-plot target prize. |
| `_handSize` | 5 | Tray size (visible choices at once). |
| Growth duration | ~1.6 s | Length of the thrive/wilt beat. |
| Level cap | 6 | Max difficulty tier (5×5 + full palette). |

---

## Known TODOs / ideas (not bugs)

1. **[LOW] Hand quality.** Tiles are drawn uniformly at random from the palette. A
   weighted deck (guaranteeing a solvable foe-free arrangement exists) could smooth
   variance on small plots.
2. **[LOW] Relationship legend.** A toggle showing the friend/foe matrix would help
   first-time players; currently the "+helps/−hurts" cues teach implicitly.
3. **[IDEA] Pollinator crop.** A flowering tile that buffs every neighbour (pollinator
   attraction) would add a fifth mechanism beyond the current four.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG/JPEG. Rendering uses `GameFx.atmosphere`
(background), `GameFx.orb` (plants/tiles), `GameFx.text` (badges/labels/cues),
`drawRRect` (soil beds), `drawLine` (relationship beams), and simple `_Dot` particles.
