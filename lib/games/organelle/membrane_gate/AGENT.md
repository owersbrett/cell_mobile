# AGENT.md — Membrane Gate

> Context for an AI agent working on THIS game. Read this and GAME.md first.
> Stay in scope. **Status: BUILT — `membrane_gate_game.dart` exists and passes
> `flutter analyze` with zero issues.**

---

## Scope (hard boundary)

- **Work only within:** `lib/games/organelle/membrane_gate/`
  (`membrane_gate_game.dart`, `GAME.md`, `AGENT.md`, `EDUCATION.md`,
  `POTATUHS.md`).
- **Read-only shared kit** (import, never edit): `lib/games/mini_game.dart`,
  `lib/games/fx.dart`, `lib/theme/potatuhs.dart`.
- **Do not touch** other games, other scales, the host/router/registry/catalog,
  or `mini_game_page.dart`. Registry wiring is the orchestrator's job, not yours.

---

## Scene / exit contract

- `MembraneGateGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the outer 60 s timer, the countdown, the live score readout, and
  the final results screen. Do NOT reimplement any of these.
- `widget.session.isRunning` gates gameplay. When false (intro / countdown /
  finished) the game must NOT spawn-for-score, apply pull/repel fields, resolve
  at the membrane, or accept input — it shows the calm ready state and drifts
  molecules cosmetically, with the active gate released.
- Report points only through `session.addScore`; report the success streak
  through `session.noteStreak`. Never set the clock or end the round yourself
  (no `endEarly` — there is no fail state).
- If the game throws, the host's error boundary shows a fallback exit. Never
  swallow exceptions.
- **Canvas-only.** No PNG/JPEG/SVG. Every molecule, the bilayer, and the channel
  proteins are procedural.

---

## Architecture

One `Ticker` → one `_RepaintNotifier` → one `_MembraneGatePainter`. The
`State` holds all simulation data (`_mols` with per-molecule velocity,
`_particles`, `_pops`, `_gateGlow`, `_gateReject`, `_activeGate`, `_repelPulse`,
`_streak`, `_vitality`). The painter reads that state and has
`shouldRepaint => false` (the notifier drives repaints). **No per-frame
setState** — `setState`-free; `_size` is captured in `LayoutBuilder`.

The interaction is a **continuous field model**: HOLD a gate → `_activeGate`
set → a radial PULL accelerates molecules toward that gate's mouth in `_update`.
RELEASE → `_activeGate = -1` → a HISTAMINE REPEL field pushes molecules up and
away from the membrane band (intruders hard, wanted lightly). Molecules resolve
by reaching an active gate (`_resolveAtGate`), leaving the top (`_leaveTop` —
repel win), or crossing the membrane un-pulled (`_resolveAtMembrane`).

```
MembraneGateGame (StatefulWidget)
  _MembraneGateGameState  (Ticker, sim state, gestures)
    _onTick → _update(dt)          // gated on session.isRunning; integrates fields
    _onTapDown/_onPanStart/Update  // set _activeGate to the nearest gate column
    _onTapUp/_onPanEnd             // release → repel/histamine
  _MembraneGatePainter  // atmosphere → cytoplasm → field(pull|repel) → membrane → mols → fx → hud
```

Data: `_MolDef` (label/color/wanted/glyph/transport/channel) + two const lists
`_kWanted` / `_kUnwanted`. `_Glyph` enum selects the procedural draw routine.

---

## Tunable constants (top of `membrane_gate_game.dart`)

| Constant | Value | Effect |
|---|---|---|
| `_kMembraneFrac` | 0.72 | Membrane y as a fraction of height |
| `_kMolRadius` | 17 | Molecule radius |
| `_kGateHalfW` | 30 | Horizontal reach of a gate's touch column |
| `_kSpawnEarly` / `_kSpawnLate` | 1.15 / 0.5 | Arrival interval ramp (s) |
| `_kDriftEarly` / `_kDriftLate` | 30 / 66 | Baseline downward drift ramp (px/s) |
| `_kMaxMoleculesEarly/Late` | 5 / 10 | On-screen cap ramp (perf + crowding) |
| `_kPullRange` / `_kPullAccel` | 320 / 900 | Active-gate pull reach & strength |
| `_kRepelAccel` / `_kRepelBand` | 640 / 200 | Histamine push strength & band height |
| `_kGoodScore` | 10 | Base points per correct import |
| `_kWrongGatePenalty` | 6 | Penalty for wrong-gate pull / breach |
| `_kIntruderReject` | 4 | Reward for repelling an intruder off-screen |
| wanted share | 0.64 → 0.46 | In `_spawn`, ramps with progress |

---

## Calibration (registry spec — owned by the orchestrator)

- `humanMax: 800`
- `starThresholds: [280, 520, 760]`

Re-tune by playtest if the multiplier economy or ramp changes.

---

## Known TODOs / ideas (not yet built)

1. **[LOW] Osmosis pressure beat.** A periodic "water surge" where several H₂O
   arrive at once could teach osmotic gradients more explicitly. Keep optional.
2. **[LOW] Active-transport variant.** A "pump against the gradient" molecule
   that costs an ATP tap to import — would tie into the Molecular ATP block.
3. **[LOW] Sound.** No audio yet; the app is silent across games.
