# AGENT.md — Predator & Prey

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/ecosystem/predator_prey/predator_prey_game.dart` (`PredatorPreyGame`)
  - Game docs: `lib/games/ecosystem/predator_prey/` (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md)
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`
  — import as needed, **no edits**.
- **Do not touch** other games, other scales, the host/router, `mini_game_registry.dart`,
  `game_catalog.dart`, or `mini_game_page.dart`. Registry wiring is the orchestrator's job, not yours.

---

## Scene / exit contract

- `PredatorPreyGame` mounts inside an isolated scene managed by `MiniGameHost`, which builds it ONCE
  as the `child` of an `AnimatedBuilder` (the game widget is NOT rebuilt when the session notifies).
- The host owns the timer, score display, countdown, results screen and exit. The game must not
  reimplement or intercept these.
- Gameplay is gated on `widget.session.isRunning`: the ODE integration, shocks, scoring and player
  nudges are all no-ops when false. Respect this — never advance the sim when not running.
- The ready overlay + button-enabled state react to phase changes via a **phase-guarded** session
  listener (`_onSession` only `setState`s when `session.phase` actually changes) — this is the ONLY
  `setState` path, and it deliberately ignores the per-frame `addScore` notifications.
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/ecosystem/predator_prey/predator_prey_game.dart` → `PredatorPreyGame` |
| Canonical spec | `lib/games/ecosystem/predator_prey/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/ecosystem/predator_prey/EDUCATION.md` |
| POTATUHS profile | `lib/games/ecosystem/predator_prey/POTATUHS.md` |
| Registry entry | `mini_game_registry.dart` → `BioScale.ecosystem` (owned by orchestrator) |

---

## Tunable constants (current values — all at top of `predator_prey_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kAlpha` | 0.95 | Hare growth rate. Raise to make prey rebound faster (easier recovery). |
| `_kBeta` | 0.020 | Predation rate. Raise to make lynx crash hares harder/faster. |
| `_kDelta` | 0.50 | Lynx conversion efficiency. Raise to make predator booms steeper. |
| `_kGamma` | 0.42 | Lynx death rate. Raise to make predators starve faster. |
| `_kK` | 170.0 | Hare carrying capacity (the K line). Lower to squeeze the playfield. |
| `_kBeta2`/`_kDelta2`/`_kGamma2` | 0.018/0.50/0.50 | Hawk dynamics. Tune the third-species pressure. |
| `_kApexAt` | 0.55 | Fraction of round when hawks arrive. Lower = three species sooner. |
| `_kFloor` | 4.0 | Collapse-risk threshold. |
| `_kSeed` | 6.0 | Reseed size after a local extinction. |
| `_kExtinctPenalty` | 40 | One-off score hit when a species hits zero. |
| `_kAliveRate` | 4.0 | Pts/sec while both survive. |
| `_kBalanceRate` | 8.0 | Pts/sec while both are in the balance band. |
| `_kPreyNudge`/`_kPredNudge` | 10/5 | Individuals added/removed per nudge tap. |
| `_kProtectDur`/`_kProtectCd`/`_kProtectBeta` | 3.0/7.0/0.40 | Refuge length / cooldown / predation multiplier. |
| `_kSampleDt`/`_kHistMax` | 0.08/150 | Graph sample interval / window length. |

Difficulty is driven by `frac = elapsed / durationSeconds`: `speed = 1 + 1.3·frac`,
`βEff = β·(1 + 0.5·frac)`, shock gap `13 − 6·frac`.

---

## Known bugs / TODOs (priority order)

1. **[MEDIUM] No drawn balance band.** `_preyEq`/`_predEq` are computed for scoring but the healthy
   window is not shaded on the graph. Drawing it (faint per-species band) would make "you are in
   balance" legible at a glance. Use the equilibrium getters; do not invent new ones.
2. **[LOW] Hawks vanish silently.** When lynx collapse the hawk line just disappears — add a brief
   non-scoring "third species lost" callout (reuse the `_shock` flash channel).
3. **[LOW] No in-session restart.** Host owns restart; do not add one to the game.
4. **[INFO] Euler integration with 4 substeps.** Mild logistic damping + clamps keep it bounded. If
   you raise the rates a lot, bump the substep count rather than the step size to keep it stable.

---

## Canvas-only rule

All rendering is one `CustomPainter` (`_EcoPainter`): atmosphere + scrolling two/three-line graph +
K line + extinction floor + phase label + legend counters + shock flash + `FxPop`s. **No PNG/JPEG/
raster assets.** Keep it that way, and keep it to ONE painter on ONE ticker — no per-frame setState.
