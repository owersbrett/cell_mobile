# AGENT.md — Body Map v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/organ/body_map_v2/`.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do NOT touch** other games, the registry (`mini_game_registry.dart`), the
  catalog, the host, or any megafile. This module imports ONLY:
  `package:flutter/*` (incl. `scheduler`, `services`), `dart:math`,
  `../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`.

## Architecture (obey it)
- **One** `Ticker` (`createTicker`, gated on `session.isRunning`) → a
  `_RepaintNotifier` → **one** `CustomPainter` (`_BodyMapV2Painter`). The painter
  reads game state by reference (`state: this`); no per-frame setState over a
  tree. All drawing is procedural canvas (no PNGs).
- The host owns clock/score/countdown/results/streak award. The game reports
  through `session.addScore`, `session.noteStreak`, and reads `session.isRunning`
  / `session.remaining`. It never draws its own timer or game-over screen, never
  owns lives, and never calls `endEarly()` (fairness — every player rides the
  full clock).

## Key pieces
- `_Organ` + `const _kOrgans` — 12 organs, each with `nx,ny` (normalised
  body-box coords), color, label, and a **`job`** string for JOB mode.
  **Landmark-first order** — early levels slice the front of this list.
- `_bodyPoint(size, nx, ny)` / `_bodyW(size)` — top-level geometry shared by
  state (hit test) and painter (draw). Single source of truth; never duplicate.
- `_Token` — a tray token (`jobMode`, `slot`, `life` decay, `held`, `returning`).
- `_Placed` — a correctly-placed organ that pops in then fades (`t` 0→1).
- Difficulty getters (`_level`, `_organCount`, `_jobProb`, `_tolFrac`,
  `_tokenLife`, `_showGhost`, `_trayCap`, `_mult`, `_isClimax`) — the ramp.

## What changed vs v1 (the teardown fixes)
1. **Tempo ceiling lifted** — the strict one-at-a-time fly-in + 1.4 s round
   freeze are gone. A continuous tray of up to 4–5 tokens lets a player chain
   placements as fast as they read+drag. Spawn rate climbs, decay shortens.
2. **Skill past recall** — JOB tokens (function → organ → location, ×1.5) plus
   tray TRIAGE under decay pressure add a real decision/risk axis.
3. **Paired organs** — generous region zone (`_tolFrac` 0.20→0.152, never pixel
   tight); accuracy is a bonus, not a gate. Side over pixels.
4. **Fair/readable** — no negatives, bounded ×4 multiplier, no `endEarly`.
5. **Climax** — final 10 s BODY SCRAMBLE surge (×1.5, faster feed, 5th slot).

## Tunable constants
| Where | Value | Effect |
|---|---|---|
| `_organCount` | `5 + (level-1)*2`, cap 12 | Organs in play |
| spawn interval | `lerp(1.25, 0.62)` → 0.42 climax | Tray feed rate |
| `_tokenLife` | `7 - (level-1)*0.8`, clamp 3.8 | Decay seconds |
| `_jobProb` | `(level-1)*0.16`, clamp 0.62 | Job-token chance |
| `_tolFrac` | `0.20 - (level-1)*0.012`, clamp 0.135 | Snap-zone radius |
| `_showGhost` | `level <= 2` | Training ghost ring (name tokens only) |
| base / acc | 10 / +6 | Per-correct scoring |
| job / climax | ×1.5 each | Hard-read & finale multipliers |
| `_mult` | `1 + streak~/4`, clamp 4 | Bounded streak multiplier |
| `_trayCap` | 4 (5 in climax) | Tokens in the tray |
| `_organR` | `bodyW*0.115`, clamp 16..40 | Token size |

## Anatomy note (positions are the education — keep them defensible)
`nx,ny` place each organ where it actually sits (heart centre-left chest, lungs
flanking, liver upper-right abdomen, stomach upper-left, kidneys mid/low flanks,
brain in the head, intestines lower abdomen, bladder pelvis). `nx` is screen-space
(viewer's left = small `nx`); "left/right" labels follow the player's view, a
deliberate kid-friendly simplification. JOB strings must stay anatomically honest
— if you change a job or a position, update GAME.md + EDUCATION.md.

## Known limitations / TODOs
- Coarse 2-D landmarks, not a surgical atlas. Do not over-engineer geometry.
- Haptics fire-and-forget (no-op on web). No audio. Procedural visuals only.
- Silhouette is one union path / one fill — keep it seam-free if restyled. Legs
  are shortened to `0.80h` to clear the bottom tray band.
