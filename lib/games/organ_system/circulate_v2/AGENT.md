# AGENT.md — Circulate v2

The assigned agent (the **A** in GAMES) for the `circulate_v2` module.

## Scope
- Owns **only** `lib/games/organ_system/circulate_v2/`:
  `circulate_v2_game.dart`, `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`.
- Does **not** edit the registry, catalog, host, or any other game. Wiring the
  `MiniGameSpec` into `mini_game_registry.dart` and a `CatalogGame` into
  `game_catalog.dart` is the orchestrator's job.

## Contract
- Widget: `class CirculateV2Game extends StatefulWidget` taking
  `{ required MiniGameSession session }`.
- Reads `session.isRunning` to gate the loop and `session.remaining` to detect
  the CODE RED surge window; reports via `session.addScore` and
  `session.noteStreak`. Never owns the clock, opponents, or standings — the
  host does.
- Self-contained: imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`,
  and Flutter. Must not import another game's code.
- Layout: a `Column` of `[Expanded(play-area CustomPaint), bottom control row]`.
  The three controls are lightweight widgets (`_HoldButton` ×2, `_BeatButton`)
  that only flip a boolean or feed the lub-dub detector — **all animated feedback
  stays on the canvas** (lung expansion, CO₂ venting, the lub-dub rings).

## The three-axis loop (the redesign — do not flatten)
- **INHALE (hold)** loads the O₂ reserve (`_inhaling` → `_o2 += _inhaleRate·dt`).
  It replaced the old tap-the-lungs recharge.
- **EXHALE (hold)** vents `_co2` (`_exhaling` → `_co2 -= _exhaleRate·dt`). CO₂
  accrues over time + a kick per organ pumped; above `_co2Warn` it drives an
  acidosis drain penalty. This whole axis is NEW — keep it.
- **HEARTBEAT (double-tap)** is the pump. A beat-tap within `_beatWindow` of the
  prior one = lub-dub → `_pumpHeart()`, which fires every PRIMED organ a delivery
  (neediest first), spending one whole charge each. Works on the heart node
  (`_onTap` near `_heart`) AND the `_BeatButton`.
- **PRIME (tap a low organ)** arms it (`_Organ.armed`); no charge until the pump.
  **This is the beloved continuous spawn-and-tap loop — leave the spawn cadence
  and drain curves exactly as they are.**

## Invariants (do not regress)
- **One Ticker → one CustomPainter.** No second `AnimationController`, no
  per-frame `setState` in the play area (button local `setState` on press only
  is fine). Particles ≤60, pops ≤6. Guard every paint path against non-finite
  metrics.
- **The reserve stays VISIBLE and countable.** The charge magazine (with the
  active pip filling as you inhale) is the hero read. Do not revert it to a tiny
  opaque bar. A pump must spend a visible whole charge per organ.
- **Three distinct, signposted controls.** INHALE / EXHALE / HEARTBEAT in the
  bottom row must stay visually and behaviourally distinct; don't merge them or
  add a hidden whole-screen tap meaning. Voice law: labels stay plain — Butter is
  smooth, no "uhhh…" anywhere (that is Russ's alone).
- **Breathing ≠ circulation.** Loading/venting (breath) and moving blood (beat)
  are separate — that separation IS the lesson. Never let an inhale or exhale
  auto-deliver; only the heartbeat pumps.
- **The lub-dub reads.** The double-tap must land a visible two-ring pump + heart
  kick. Don't collapse it to a single tap.
- **Fair scoring + no early end.** Keep the rescue bonus spread modest
  (`5 + (1−o2)·15`); keep streak as a *display/award* only (never a multiplier).
  A starved organ must NOT end the run — the run always rides the full clock.
- **Climax preserved.** The final `_surgeWindow` seconds spike demand + CO₂ and
  apply the uniform ×2 (shared host clock) — don't remove the crescendo.
- **Session re-entry (the S).** `_resetRun` on the `isRunning` rising edge resets
  O₂/CO₂/organs AND re-arms the in-context teach flags; a fresh run leaves no
  residue.
- **autoPilot drives all three controls.** `_autoStep` must exercise
  inhale/exhale/prime/pump on a sensible rhythm so ATTRACT looks like real play.

## Verify
- `flutter analyze lib/games/organ_system/circulate_v2/` → **zero** issues.
- `flutter test test/games` stays green after the orchestrator wires the spec.

## Tuning notes
- `humanMax` / `starThresholds` in the spec are playtest-tuned, not gates.
- If the late game feels unfair, prefer easing `_surgeDrainMult` /
  `_surgeDemandKick` / `_co2DrainBoost` over widening the rescue bonus (which
  would reintroduce runaway). To make the O₂ loop tighter, lower `_chargeCap` or
  `_inhaleRate`; to relax the CO₂ axis, lower `_co2BaseRate` / `_co2PerDeliver`
  or raise `_exhaleRate`. `_beatWindow` sets how forgiving the lub-dub is.
