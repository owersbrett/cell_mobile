# AGENT.md — Standard Model v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> v2 = the UX-refinement-pass rebuild of `standard_model`. The original stays untouched.

## Scope (hard boundary)
- **Work only within:** this game's folder — `lib/games/particles/standard_model_v2/`
  (`standard_model_v2_game.dart` + these docs). Shared scale education:
  `lib/games/particles/EDUCATION.md`.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games, the router, the catalog, the host, or the registry.

## Scene / exit contract
- Isolated scene; never trap the player. Exit / timer / countdown / results / score are host-owned
  (`MiniGameHost` + `MiniGameSession`). The widget renders ONLY the play area.
- Auto-starts on `session.isRunning`; shows a "ready" hint (with the three input verbs) while not running.

## Files
- Widget: `standard_model_v2_game.dart` → `StandardModelV2Game`
- Spec: `GAME.md` · Education: `EDUCATION.md` · Potatuhs lens: `POTATUHS.md`
- Scale education: `../EDUCATION.md`

## Architecture (keep it this way)
- One `Ticker` (`createTicker`) → `_onTick` → `setState(() {})`. One `_SMV2Painter`. The play tree is
  just a `CustomPaint`, so the per-frame setState is over a tiny tree — no second ticker, no
  per-particle widgets.
- `_clock` always advances (ambient atmosphere even in the ready state); game physics run only when
  `session.isRunning`. A `_wasRunning` edge calls `_startRun()` → clean session re-entry (the S in GAMES).
- Geometry (`_binTopFor` / `_binRectFor` / `_dangerLineFor`) is top-level so input hit-testing and the
  painter share one definition. Keep it that way.

## Data model (preserved from v1)
- `_PData` — the 17 immutable particle definitions (`_kParticles`).
- `_kTricky` — neutral/ambiguous indices, weighted up at difficulty ≥3.
- `_kLegend` — the fading mini-legend members per bin (the v2 onboarding cue).
- `_Particle` — a live instance (id, data, x/y, vy, dragging). `_selId` marks the frozen/held one.

## The three-speed verb (the core v2 change — don't regress to drag-only)
- **Tap particle** → freeze (`_selId`); **tap bin** → `_resolve`. Novice floor.
- **Tap empty bin** → toggle `_armedBin`; then **tap particle** → fires into the armed bin (one tap).
  Skill ceiling — rapid-clears clusters.
- **Flick** (pan velocity > 650, downward) → `_flickBin` throws to the nearest bin. Drag-into-bin is
  the fallback. All four routes funnel through `_resolve(particle, bin)`.

## Tunable constants (current)
- Difficulty: `(sorted ÷ 4) + (elapsed ÷ 14)`, clamped `0..6`.
- Fall speed `(42 + diff×13) × (climax?1.32:1)` · spawn interval `(1.55 − diff×0.16, floor 0.62) ×
  (climax?0.62:1)` · max concurrent `3 + diff + (climax?2:0)`, cap 9.
- Tell fade: family colour `1 − diff/4`; charge badge hidden ≥ diff 4; colour rim hidden ≥ diff 5.
- Legend fade: `1 − diff/2.5` (gone by ~tier 2.5).
- Multiplier: `1 + streak÷4`, cap ×4 (×8 in climax). Score: `(10 + diff×2 + speedBonus≤6) × mult`.
- Climax: `remaining ≤ 10 s` → BEAM BURST; every 10th sort fires a milestone flash.

## To build / extend (ideas, not required)
- Tune `humanMax` / `starThresholds` in the registry spec by playtest (faster verb ⇒ higher counts).
- Optional high-tier sub-sort by generation (needs a contextual bin — design first).

## Known bugs / TODOs
- None known. If the field overflows on a very small screen, lower the `maxConcurrent` cap.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
