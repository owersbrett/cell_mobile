# AGENT.md — Area Under

> Context for an AI agent working on THIS game. Read this and GAME.md (and EDUCATION.md for the
> math) first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/infinities/area_under/`
  - `area_under_game.dart` (`AreaUnderGame` / `_AreaUnderGameState` / `_AreaPainter` + the small
    private widgets `_MatchMeter`, `_StepButton`, `_ConfirmButton` and value types `_Spark`,
    `_Result`)
  - `area_under_data.dart` (`AreaCurve`, `buildAreaCurveBank()`, `riemannMidpoint()`)
  - The docs in this folder: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/theme/potatuhs.dart`,
  `lib/games/EXTRACTION_RECIPE.md`. Read as needed; **no edits**.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`, or
  `mini_game_host.dart`. The orchestrator wires those.

---

## Scene / exit contract

- `AreaUnderGame` takes a `MiniGameSession`.
- `widget.session.isRunning` gates the loop — the first round auto-starts when it flips true; the
  ticker advances round time only while playing.
- Score reaches the host **only** via `widget.session.addScore(n)`; the streak via
  `widget.session.noteStreak(streak)`. The host owns the timer, the results screen and the exit
  affordance. This game has **no** results screen and **never** calls `endEarly`.
- If the game throws, the host's error boundary shows an exit fallback — never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/infinities/area_under/area_under_game.dart` → `AreaUnderGame` |
| Curve bank + math | `lib/games/infinities/area_under/area_under_data.dart` |
| Canonical spec | `lib/games/infinities/area_under/GAME.md` (rules live here — edit first, then code) |
| Education | `lib/games/infinities/area_under/EDUCATION.md` |
| POTATUHS lens | `lib/games/infinities/area_under/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` (out of scope — orchestrator only) |

---

## Tunable constants (current values — top of `area_under_game.dart`)

| Constant | Value | Tune it for |
|---|---|---|
| `_kNMax` | 80 | Slider ceiling. Raise to let players push convergence further; lower for a coarser feel. |
| `_kNStart` | 3 | Opening rectangle count. Keep small so the first drag *feels* the convergence. |
| `_kBasePoints` | 120 | Per-lock base before factors. |
| `_kSpeedWindow` | 14 s | Speed-bonus decay window. Shorten to reward faster locks harder. |
| `_kFeedbackSecs` | 2.0 s | Reinforcement-card dwell. |
| `_kMeterMaxErr` | 0.30 | Relative error mapped to an empty MATCH meter. Shrink to make the meter feel twitchier. |
| `_kStreakStep` | 3 | Tight locks per +1× multiplier. |
| tolerance ramp | `max(0.025, 0.08 − 0.006·round)` | Per-round precision gate (in `_startRound`). |
| tier ramp | `round<2 ? 0 : round<5 ? 1 : 2` | When signed-area curves arrive (in `_pickCurve`). |

`humanMax` (1400) and `starThresholds` ([450, 900, 1400]) live in the registry spec, not here —
flag changes for the orchestrator.

---

## Design invariants (do not break)

1. **The true area is never printed during play.** The player reads closeness off the MATCH meter
   only; the exact value is revealed **after** the lock, on the reinforcement card. Printing it would
   collapse the lesson (just type the number — n becomes irrelevant).
2. **n is the one control.** The whole point is that increasing n → tighter estimate → the limit
   (the integral). Do not add a control that lets the player set the estimate directly.
3. **Midpoint Riemann sum** for both the player's estimate and the on-screen rectangles
   (`riemannMidpoint`). The true area uses a 20k-subdivision midpoint sum at curve construction —
   accurate to display precision; no analytic antiderivative is required.
4. **TIGHT (error ≤ tol/2) extends the streak; a merely-in-tolerance lock resets it.** This is what
   pushes players to add more rectangles — keep that asymmetry.
5. **Signed area is the late twist.** Tier-2 curves dip below the axis; below-axis rectangles render
   rose and subtract. The net signed integral is the target. Keep tier-2 curves' |net area| well
   away from 0 so relative error stays well-behaved.

---

## Performance rule (the "black screen / jitter" bug class)

- The animated plot is a **single `CustomPainter`** repainted via a `ValueNotifier` ticked once per
  frame, inside a `RepaintBoundary`. Keep it that way.
- **No per-frame `setState`.** Control widgets rebuild only on discrete events. If you add live
  animated HUD elements, paint them on the canvas — do not lift them into the widget tree on a
  per-frame timer.
- Dispose the ticker and the notifier (already done in `dispose`).

---

## Known TODOs / ideas (not blocking)

1. **[LOW] Left/right-rule toggle.** A pre-round toggle between left / midpoint / right Riemann sums
   would make the over-/under-estimate lesson explicit. Midpoint-only today (it hugs best).
2. **[LOW] Trapezoid bonus round.** A late "trapezoid rule" curve would show a faster-converging
   approximation — good contrast with rectangles, reinforces "the integral is the limit either way."
3. **[LOW] Bigger curve bank.** 12 curves today (4 per tier). More variety would reduce repeats over
   a long session.
4. **[INFO] `_AreaPainter.shouldRepaint` returns true.** Repaint is already gated by the
   `ValueNotifier` `repaint:` argument, so this is fine — the painter only rebuilds when the notifier
   fires.

---

## Canvas-only rule

All plot rendering is `CustomPainter`. **No PNG/JPEG/raster assets.** The painter draws: the grid +
frame, the emphasised x-axis (the area's baseline), the shaded true region, the midpoint Riemann
rectangles (teal positive / rose negative, each with a midpoint contact dot), the curve (glow +
stroke), the lock bloom and the spark burst. The `a` / `b` endpoint labels use `TextPainter`.
