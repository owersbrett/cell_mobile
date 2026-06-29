# AGENT.md — Reflex Gate (reflex_v2)

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> v2 is the UX-refinement sibling of `organ_system/reflex/`; the original stays untouched.

---

## Scope (hard boundary)
- **Work only within:** `lib/games/organ_system/reflex_v2/` — `reflex_v2_game.dart` and the four docs
  (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`.
- **Do not touch** the registry, catalog, host, `mini_game_page.dart`, the v1 `reflex/` module, or any
  other game. Wiring into registry/catalog is a lead task, not an in-game task.

## Dependency rule (EXTRACTION_RECIPE)
Imports are limited to: `dart:math`, `package:flutter/*`, `../../mini_game.dart`, `../../fx.dart`,
`../../../theme/potatuhs.dart`. Self-contained — no import of another game's code (including v1).

## What v2 changed vs v1 (the refinement brief)
1. **Decision layer (go/no-go).** The receptor now fires ORANGE (GO → react) or TEAL (NO-GO →
   inhibit). Tapping a NO-GO is a misfire. This is the skill ceiling the teardown demanded — pure
   twitch loses.
2. **CHARGE multiplier (push-your-luck).** Every correct decision raises `×charge` (+0.3, cap 3.5);
   any mistake resets it to ×1.0. All points scale by it. The competitive risk layer.
3. **Compressed dead air.** Tighter waits (`1.05–2.1 → 0.55–1.05`), short result holds
   (`_kHitHold 0.50`, `_kHeldHold 0.45`, `_kFailHold 0.62`) — no long stares.
4. **Competition framing.** A `BEST ⚡ {ms}` ghost (round-best GO reaction) + always-visible charge bar.
5. **Climax.** `_climax` (from `session.remaining`, final 12 s) shaves waits and ramps shake/glow.

## What v2 KEPT (do not regress)
- Flawless single-tap, full-field affordance. The only decision is *whether* to tap.
- The reflex-arc surface: receptor → cord → muscle, brain faded + dotted "bypassed", brain decoy.
- Instant legibility: cue colour + the big WAIT… / REACT! / HOLD! callout always say what to do.

## Scene / exit contract
- `ReflexV2Game` mounts inside an isolated scene managed by `MiniGameHost`. The host owns the timer,
  countdown overlay, results screen, and exit affordance — the game never reimplements these.
- `widget.session.isRunning` gates gameplay; the run (re)starts on the rising edge (`_startRun`),
  resetting trial/streak/charge so a fresh session begins clean. Do not advance state when paused.
- Let exceptions surface to the host's error boundary; never swallow them.

## Architecture (one ticker → one painter)
- Single `Ticker` (`_onTick`) computes `dt`, updates climax, advances the trial machine, decays juice,
  then one `setState`. One `_ReflexV2Painter` (RepaintBoundary-wrapped). No per-frame setState over a
  big tree, no second animation source. Keep this shape (web target, < 80 s rounds).
- Screen-shake is a single canvas `translate` in the painter (deterministic from `idlePhase`); no RNG
  in paint.

## State machine (`_Phase`)
`idle → ready → (go | noGo) → (reacting | held | failed) → ready …`. False start during `ready`
re-rolls the wait WITHOUT advancing the trial. Key fields: `_waitRemaining`, `_sinceStimulus`
(reaction OR hold timer), `_reactLimit`, `_holdWindow`, `_charge`, `_signalProgress`,
`_decoyFireAt/_decoyVisible`, `_bestRtMs`, `_climax`.

## Tunable constants (top of `reflex_v2_game.dart`)
| Constant | Value | Tune for |
|---|---|---|
| `_kDifficultyTrials` | 11 | Ramp speed (lower = steeper). |
| `_kWaitMin/MaxEasy/Hard` | 1.05/2.1 → 0.55/1.05 | Pre-stimulus delay across the ramp. |
| `_kReactLimitEasy/Hard` | 1.1 → 0.68 | GO reaction window. |
| `_kHoldWindowEasy/Hard` | 0.95 → 0.70 | NO-GO survive window. |
| `_kNoGoChanceEasy/Hard` | 0.16 → 0.42 | How often a cue is a NO-GO. Raise = harder discrimination. |
| `_kChargeStep` / `_kChargeMax` | 0.30 / 3.5 | Multiplier growth + cap. |
| `_kHoldReward` | 38 | Inhibition payout (before charge). |
| `_kFalseStartPenalty` / `_kWrongTapPenalty` | 18 / 24 | Misfire penalties. |
| `_kScoreBudgetMs` / `_kScoreDivisor` / `_kSpeedMax` | 600 / 5 / 110 | GO speed curve & cap. |

## Known TODOs / ideas
1. **[INFO] humanMax/starThresholds** (2600 / [800,1600,2400]) are first-pass; the charge multiplier
   makes totals sensitive — retune by playtest once real scores exist.
2. **[LOW] Cue-similarity hard mode.** Could nudge NO-GO toward orange at peak difficulty, but ONLY if
   it stays clearly distinguishable — legibility is sacred, do not trade it for difficulty.
3. **[LOW] Audio cue** on stimulus onset would sharpen feel; stay silent unless the host exposes audio.

## Canvas-only rule
All rendering is `CustomPainter` via `GameFx` primitives. **No PNG/JPEG/raster assets.** Procedural only.
