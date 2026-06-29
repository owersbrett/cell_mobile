# AGENT.md — Body Map

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/organ/body_map/`.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do NOT touch** other games, the registry (`mini_game_registry.dart`), the catalog,
  the host, or any megafile. This module imports ONLY: `package:flutter`, `dart:math`,
  `../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`.

## Architecture (obey it)
- **One** `AnimationController` (days-long, gated on `session.isRunning`) → `_tick` → **one**
  `setState` → **one** `CustomPainter` (`_BodyMapPainter`). Do not add more tickers, and do not
  call `setState` per-organ or over a widget tree. All drawing is procedural canvas (no PNGs).
- The host owns the clock/score/countdown/results/streak award. The game reports through
  `session.addScore`, `session.noteStreak`, and reads `session.isRunning`. It never draws its
  own timer or game-over screen, and never owns lives.

## Key pieces
- `_OrganDef` + `const _kOrgans` — the 12 organs, each with `nx,ny` (normalised body-box coords),
  color, label. **Landmark-first order** — early rounds slice the front of this list.
- `_bodyPoint(size, nx, ny)` / `_bodyW(size)` — top-level geometry shared by state (hit test)
  and painter (draw). Keep them the single source of truth; never duplicate the mapping.
- `_Active` — the live organ (fly-in `flyT`, `grabbed`, `bouncing`, `aliveT` for the speed bonus).
- `_Placed` — a snapped organ (`bornClock` drives the pop-in).
- Difficulty getters (`_tier`, `_flyDur`, `_tolFrac`, `_speedWindow`, `_showGhost`) — the climb.

## Tunable constants
| Where | Value | Effect |
|---|---|---|
| `_buildRound` count | `4 + roundIndex*2`, cap 12 | Organs per body |
| `_flyDur` | `1.1 − tier*0.09`, clamp 0.45 | Arrival speed |
| `_tolFrac` | `0.15 − tier*0.011`, clamp 0.075 | Snap-zone tightness (× bodyW) |
| `_speedWindow` | `3.5 − tier*0.25`, clamp 1.5 | Speed-bonus window (s) |
| `_showGhost` | `tier <= 1` | Training ghost ring |
| base / speed / acc | 30 / +30 / +20 | Per-correct scoring |
| streak bonus | `(streak−1)*5` | Combo reward |
| wrong penalty | −5 + streak reset | Per-wrong |
| round bonus | `40 + roundIndex*20 (+40 perfect)` | Body cleared |
| `_organR` | `bodyW*0.11`, clamp 16..42 | Token size |

## Anatomy note (positions are the education — keep them defensible)
`nx,ny` place each organ where it actually sits (heart center-left chest, lungs flanking, liver
upper-right abdomen, stomach upper-left, kidneys mid/low flanks, brain in the head, intestines
lower abdomen, bladder pelvis). If you adjust a position, keep it anatomically honest and update
GAME.md + EDUCATION.md. Note `nx` is screen-space (viewer's left = small `nx`); "left lung/kidney"
labels follow the player's view, not strict anatomical left — a deliberate simplification for kids.

## Known limitations / TODOs
- Positions are coarse 2-D landmarks, not a precise atlas. Fine for the organ scale; do not
  over-engineer into exact mediastinum geometry.
- No audio. No haptics. Procedural visuals only.
- The silhouette is a simple union path (head, torso, arms, legs). If you restyle it, keep the
  single-`Path` single-fill approach so translucency stays seam-free.
