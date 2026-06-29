# Predator & Prey v2 — Agent (A)

**Owner agent:** ecosystem-dynamics game agent.
**Module:** `lib/games/ecosystem/predator_prey_v2/predator_prey_v2_game.dart`
**Spec id:** `predator_prey_v2` (registry + catalog).

## Charter
Own the UX-passed alternative to `predator_prey`. Preserve the Lotka–Volterra
model **exactly** (it is the asset); evolve only the surface, the standing, the
feedback and the pacing. The v1 sim constants are copied verbatim — do not retune
the ODE without a paired education review.

## Invariants (do not break)
- **One Ticker → one CustomPainter.** All continuous motion + the ODE
  integration run in `_onTick`; state mutates WITHOUT setState; the widget tree
  (buttons) rebuilds at a throttled ~15fps. Never per-frame setState over the
  control tree.
- **Session contract:** gate the sim on `session.isRunning`; report points via
  `session.addScore`; report the balance streak via `session.noteStreak`.
  Reseed-on-extinction (penalty, not game-over) keeps the full clock running so a
  session always completes and a fresh one re-enters (the **S** in GAMES).
- **Self-contained module.** Only depends on `mini_game.dart`, `fx.dart`,
  `theme/potatuhs.dart`, Flutter, `dart:math`. No other game's code.
- **Fairness:** scoring stays bounded-rate (alive + balance), no runaway leader.
- **Caps:** creatures `_kMaxHare/Lynx/Hawk`, particles `_kMaxParticles` — keep
  the field cheap.

## Levers to tune (by playtest)
- `_kPreyNudge` / `_kPredNudge` / refuge timings — input weight vs sim swing.
- `_kAliveRate` / `_kBalanceRate` / `_kClimaxMult` — score shape; keep `humanMax`
  + `starThresholds` in the registry spec in sync.
- `_kPerHare/Lynx/Hawk` — population-to-creature density (legibility vs clutter).

## Watch-fors
- The dial (`_health`) is smoothed toward `_targetHealth`; scoring uses the
  binary `_inBalance` band. Keep the two visually consistent (green dial ≈
  scoring) or the standing lies.
- Coach line fades by `_frac 0.45` — keep it a *teach-by-doing* nudge, not a
  permanent HUD.
