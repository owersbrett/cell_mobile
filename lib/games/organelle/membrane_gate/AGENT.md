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
  finished) the game must NOT spawn-for-score, resolve at the membrane, or accept
  taps — it shows the calm ready state and drifts molecules cosmetically.
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
`State` holds all simulation data (`_mols`, `_particles`, `_pops`,
`_channelGlow`, `_streak`, `_vitality`). The painter reads that state and has
`shouldRepaint => false` (the notifier drives repaints). **No per-frame
setState** — `setState`-free; `_size` is captured in `LayoutBuilder`.

```
MembraneGateGame (StatefulWidget)
  _MembraneGateGameState  (Ticker, sim state, gestures)
    _onTick → _update(dt)   // gated on session.isRunning
    _onTapUp                 // hit-test molecules above the membrane
  _MembraneGatePainter      // atmosphere → cytoplasm → membrane → molecules → fx → hud
```

Data: `_MolDef` (label/color/wanted/glyph/transport/channel) + two const lists
`_kWanted` / `_kUnwanted`. `_Glyph` enum selects the procedural draw routine.

---

## Tunable constants (top of `membrane_gate_game.dart`)

| Constant | Value | Effect |
|---|---|---|
| `_kMembraneFrac` | 0.64 | Membrane y as a fraction of height |
| `_kMolRadius` | 17 | Molecule radius |
| `_kHitPad` | 24 | Tap forgiveness around a molecule |
| `_kSpawnEarly` / `_kSpawnLate` | 1.05 / 0.42 | Arrival interval ramp (s) |
| `_kFallEarly` / `_kFallLate` | 74 / 184 | Descent speed ramp (px/s) |
| `_kGoodScore` | 10 | Base points per correct import |
| `_kToxinPenalty` | 8 | Penalty for importing a toxin |
| `_kMaxMolecules` | 14 | On-screen cap (perf guard) |
| wanted share | 0.62 → 0.46 | In `_spawn`, ramps with progress |

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
