# AGENT.md — Cell Type

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/cell/cell_type/cell_type_game.dart`
    (`CellTypeGame` / `_CellTypeGameState` / `_StagePainter` / `_Cell`)
  - Game docs: `lib/games/cell/cell_type/` (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md)
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — read as needed, **no edits**.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or `mini_game_page.dart`. The registry entry already exists; if its
  copy needs changing, flag it — do not edit it from here.

---

## Self-contained module rule

Per `lib/games/EXTRACTION_RECIPE.md`, this module imports ONLY:
`dart:math`, `package:flutter/material.dart`, `package:flutter/scheduler.dart`,
`package:cell_mobile/games/mini_game.dart`, `package:cell_mobile/games/fx.dart`,
`package:cell_mobile/theme/potatuhs.dart`. It must never import another game's code. Keep it
that way — isolation beats DRY here.

---

## Scene / exit contract

- `CellTypeGame` takes a `MiniGameSession`. The **host owns** the 60 s clock, countdown, score
  readout and results. This widget renders only the play area.
- One `Ticker` drives one `_StagePainter` via a `_Repaint` notifier. **Do not add a second
  ticker or per-frame `setState` over the widget tree** — the HUD reads the session through an
  `AnimatedBuilder`, the painter repaints off the pump. `setState` is only for discrete
  transitions (answer tapped, next cell, reset-for-play).
- Gating: `_classify` no-ops unless `session.isRunning`. On the `isRunning` rising edge the loop
  calls `_resetForPlay` (auto-start). The game never calls `endEarly`.
- Score/streak go through `session.addScore` and `session.noteStreak` only.
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/cell/cell_type/cell_type_game.dart` |
| Canonical spec | `lib/games/cell/cell_type/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/cell/cell_type/EDUCATION.md` |
| POTATUHS lens | `lib/games/cell/cell_type/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `id: 'cell_type'`, `BioScale.cell` |

---

## Tunable constants (all in `cell_type_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kFlareDuration` | 1.9 s | How long the fact card holds before auto-advance. |
| `_kMaxPoints` | 110 | Instant-correct ceiling. |
| `_kFloorPoints` | 15 | Slowest-correct floor. |
| `_kDecayFast` | 3.4 s | Speed-bonus decay window at round start (generous). |
| `_kDecaySlow` | 1.7 s | Decay window at round end (tight — the "faster" ramp). |
| `_kStreakStep` | 3 | Consecutive-correct count per +1x multiplier. |

Difficulty is in `_generate(progress)`: `clarity = (1 - progress*0.65).clamp(0.35,1)` controls
chloroplast count (plant), rod-vs-coccus + flagellum presence (bacterial), and size. Raise the
`0.65` for a steeper subtlety ramp.

---

## Known TODOs

1. **[MEDIUM] Resume not implemented.** Each mount re-generates from cell #1. If drop-and-resume
   is needed, persist `_streak`, `_factIdx`, and the current `cell` via the host.
2. **[LOW] Type bag is random with a 70% anti-repeat re-roll**, not a true shuffled bag. Over a
   60 s round the spread is even enough; switch to a 4-type bag if a fairer distribution is wanted.
3. **[LOW] Fungal vs plant at low clarity** leans on "no chloroplasts" alone. Consider adding a
   subtle hyphal-bud cue to fungal cells so the tell isn't purely an absence.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG/JPEG/raster assets.** The painter draws every cell from
primitives: rigid walled box + grana-striped chloroplasts + central vacuole (plant); thin-membrane
blob + cristae mitochondria + central nucleus (animal); capsule + wall + free nucleoid tangle +
ribosome dots + flagellum (bacterial); round chitin wall + granules + nucleus (fungal).
