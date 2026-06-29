# AGENT.md — Half-Life

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/atoms/half_life/half_life_game.dart` (`HalfLifeGame`)
  - Game docs: `lib/games/atoms/half_life/` (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md)
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`, `FxParticle`, `FxBurst`, `FxPop`), `lib/theme/potatuhs.dart`. Read as needed; **no
  edits**.
- **Do not touch** other games, other scales, the registry/catalog/host, or `mini_game_page.dart`.
  Registry wiring is owned by the orchestrator, not this agent.

---

## Scene / exit contract

- `HalfLifeGame` mounts inside an isolated scene managed by `MiniGameHost`.
- **The host owns the clock, countdown, score HUD, results screen, and the exit affordance.** The
  game renders ONLY the play area and reports points via `session.addScore` / streak via
  `session.noteStreak`. Never reimplement timer, score display, or exit.
- Gameplay is gated on `widget.session.isRunning`. The single `Ticker` always runs (so the ready
  state animates during countdown), but decay/scoring only advance while `isRunning` is true. On the
  first running tick the game auto-starts round 0 (`_started` latch).
- If the game throws, the host's error boundary shows a fallback. Never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/atoms/half_life/half_life_game.dart` → `HalfLifeGame` |
| Canonical spec | `lib/games/atoms/half_life/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/atoms/half_life/EDUCATION.md` |
| POTATUHS lens | `lib/games/atoms/half_life/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.atoms` (owned by orchestrator) |

---

## Architecture (performance contract)

- **One `Ticker` → one `setState` per frame → one `CustomPaint`/`_HalfLifePainter`.** Do not add
  per-frame `setState` over large widget trees; do not add a second ticker or animation controller.
- The atom grid, decay curve, sparks, pops, prompt, reveal card, and ready state are ALL drawn by
  the single painter. The only Flutter widget overlay is the MEASURE button (`_MeasureButton`),
  which is static chrome (rebuilds only on enable/disable).
- `shouldRepaint` returns `true` (state changes every frame while running). Acceptable: one painter,
  ~36 orbs + a polyline + a handful of particles.

---

## Tunable constants (current values — all in `half_life_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kBasePoints` | 100 | Per-round ceiling before the perfect bonus. Raise to make the game score-richer. |
| `_kPerfectBonus` | 40 | Reward for a sub-`_kPerfectErr` tap. Raise to reward precision harder. |
| `_kTol` | 0.8 | Half-lives of error that collapse the score to 0. Lower = harsher accuracy demand. |
| `_kGoodErr` | 0.22 | Streak-keeping window. Widen to make streaks easier. |
| `_kPerfectErr` | 0.06 | Perfect-bonus / "PERFECT!" window. |
| `_kRevealTime` | 1.6 | Seconds the reveal card holds before the next round. Lower = faster pace. |
| `_cfgFor(r)` | `t½=max(1.4,3.4−0.16r)`, `targetN=min(3,1+r÷3)` | The whole difficulty ramp. |

---

## Educational integrity (do not break)

- The visible glowing count MUST track `36 × 2^(−t/t½)`. This comes from uniform per-atom thresholds
  (`_seedThresholds`) compared against the live `frac`. Do not replace with a fixed decay order or a
  per-atom Poisson roll that drifts off the curve — the grid and the curve must agree, or the lesson
  breaks.
- The decay curve drawn under the grid is the real `2^−n`. Keep it accurate; it is the teaching
  surface, not decoration.

---

## Known TODOs (priority order)

1. **[LOW] No mid-round restart** — host owns session lifecycle; do not add one.
2. **[LOW] Isotope WOW flare** — EDUCATION.md names real isotopes (C-14, I-131, U-238). A future
   upgrade could surface the round's half-life as a named isotope on the reveal card. Non-scoring,
   must not block input, separate overlay slot.

---

## Canvas-only rule

All rendering is `CustomPainter` + the one button widget. **No PNG/JPEG/raster assets.** Atoms are
`GameFx.orb` calls; decayed husks are dim circles; the curve is a `Path`; sparks/pops use the `fx.dart`
primitives; all text is `GameFx.text`. Keep it that way.
