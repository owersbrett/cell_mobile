# AGENT.md — Standard Model

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** this game's folder — `lib/games/particles/standard_model/`
  (`standard_model_game.dart` + these docs). Shared scale education:
  `lib/games/particles/EDUCATION.md`.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games, the router, the catalog, the host, or the registry. The registry
  spec for this game already exists; only an explicit task changes it.

## Scene / exit contract
- Isolated scene; never trap the player. Exit / timer / countdown / results / score are host-owned
  (`MiniGameHost` + `MiniGameSession`). The widget renders ONLY the play area.
- Auto-starts on `session.isRunning`; shows a calm "ready" hint while not running.

## Files
- Widget: `standard_model_game.dart` → `StandardModelGame`
- Spec: `GAME.md` · Education: `EDUCATION.md` · Potatuhs lens: `POTATUHS.md`
- Scale education: `../EDUCATION.md`

## Architecture (keep it this way)
- One `AnimationController(duration: 1 day)` → `_tick` → `setState`. One `_SMPainter`. No second
  ticker, no per-particle widgets, no `setState` over a big tree.
- `_clock` always advances (ambient atmosphere even in the ready state); game physics run only when
  `session.isRunning`. A `_wasRunning` edge resets the run → clean session re-entry (the S in GAMES).

## Data model
- `_PData` — the 17 immutable particle definitions (`_kParticles`): symbol, name, family, generation,
  forceLabel, chargeLabel/chargeColor, hasColor, massRank.
- `_kTricky` — indices of neutral/ambiguous particles, weighted up at difficulty ≥3.
- `_Particle` — a live falling instance (id, data, x/y, vy, dragging).

## Tunable constants (current)
- Difficulty: `(sorted ÷ 4) + (elapsed ÷ 14)`, clamped `0..6`.
- Fall speed `42 + diff×13` (cap 130) · spawn interval `1.55 − diff×0.16` (floor 0.62) ·
  max concurrent `3 + diff` (cap 7).
- Tell fade: family colour `1 − diff/4`; charge badge hidden at diff ≥4; colour rim hidden at diff ≥5.
- Score: `10 + min(streak,12)×2 + diff×2 + speedBonus(≤8)`.

## To build / extend (ideas, not required)
- Optional finer sub-sort at very high tiers (sort by generation within a family) — would need a
  fourth/contextual bin; design first, it changes the core UX.
- Persist best score / best streak for resume polish (host already shows results).

## Known bugs / TODOs
- None known. If the field ever overflows on a very small screen, lower `maxConcurrent` cap.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
