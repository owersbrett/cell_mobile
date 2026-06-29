# Pattern Lock v2 — AGENT.md (the A in GAMES)

Owner agent for the `pattern_lock_v2` mini-game. You may change THIS folder only.
Do not touch the registry, catalog, host, or any other game.

## Scope
- `pattern_lock_v2_game.dart` — the playable widget + all its private helpers
  (`_Puzzle`, `_Elem`, the family generators, `_Repaint`, `_StagePainter`).
- `GAME.md`, `EDUCATION.md`, `POTATUHS.md`.

## Dependency rule (EXTRACTION_RECIPE.md)
Import ONLY: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
`../../fx.dart`, `../../../theme/potatuhs.dart`. MUST NOT import another game's
code. Keep helpers private and inlined.

## Contract with the host
- `PatternLockV2Game({required MiniGameSession session})`.
- The host owns the clock / countdown / **score HUD** / results. Render ONLY the
  play area; do NOT draw a score/timer HUD (it lives in `_GameHud` above this
  widget). Game-owned chrome here is only the streak chip + lightning banner.
- Gate all simulation on `session.isRunning`. Never call `session.endEarly`.
- Report points via `session.addScore`; report the running streak via
  `session.noteStreak`.
- Auto-start when `isRunning` flips true (`_resetForPlay`); show the calm ready
  state before play.

## Performance guardrails (the v2 architecture)
- ONE `Ticker` → ONE `CustomPainter` (`_StagePainter`) under a `RepaintBoundary`.
- The painter repaints off a `_Repaint` pump ticked each frame; the widget tree
  is **never** rebuilt per frame (no `setState` in the loop).
- The ENTIRE game is canvas — sequence, options, toast, fx — hit-tested via
  geometry rects shared by painter and input (`_seqRects`, `_optionRects`).
- Generation is procedural and allocation-light; no asset/icon-font loads
  (shapes/arrows are drawn geometrically, not Material icons).

## Design intent (UX pass — the named teardown fixes)
- **No blocking reveal.** A correct tap = a ~0.3s kinetic lock (`_kLockDur`),
  then the next puzzle. The clock NEVER stops. Rule/teach ride a fading toast.
- **Kinetic lock-in.** Fly-in token + `?`-cell overshoot pop + streak-scaled
  shockwave ring. Keep this punchy; it is the game's signature beat.
- **Skill ramp.** Family chip hidden at level 2+ and through the surge.
- **Fair competition.** Streak multiplier capped at `_kMultCap` (×3).
- **Climax.** Last `_kSurgeSeconds` (10s) = LIGHTNING ROUND: chip hidden, window
  tightest (`_decayWindow` → 2.0), points ×`_kSurgeScoreMul`, vignette + banner.

## Tuning knobs
- `_kMaxPoints` / `_kFloorPoints` — speed-bonus band.
- `_kStreakStep` / `_kMultCap` — streak cadence + the non-runaway cap.
- `_decayWindow(lvl)` — how fast you must answer for max points.
- `_kLockDur` / `_kLockSurge` — the kinetic lock window (do not regrow toward a
  reading wall — this is juice, not a gate).
- `_allowed(lvl)` — which families appear at each level.
- `humanMax` / `starThresholds` live in the registry spec (out of scope here);
  re-tune from playtest, not guesswork.

## Do / Don't
- DO keep distractors plausible but unambiguous (one correct continuation).
- DO keep number magnitudes readable (`_fittedText` shrinks to fit).
- DON'T introduce two correct answers (ambiguous starts).
- DON'T reintroduce a post-answer gate longer than the kinetic lock.
- DON'T add network, audio, shared mutable singletons, or a second loop.
