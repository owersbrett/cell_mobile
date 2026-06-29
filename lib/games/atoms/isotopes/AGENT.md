# AGENT.md — Isotopes

> Context for an AI agent working on THIS game. Read this and GAME.md first.
> Stay in scope. **Status: BUILT — `isotopes_game.dart` exists and passes
> `flutter analyze lib/games/atoms/isotopes/` with zero issues.**

---

## Scope (hard boundary)

- **Work only within:** `lib/games/atoms/isotopes/`
  (`isotopes_game.dart`, `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`).
- **Read-only shared kit** (import, never edit): `lib/games/mini_game.dart`,
  `lib/games/fx.dart`, `lib/theme/potatuhs.dart`, `package:flutter/*`,
  `dart:math`.
- **Do not touch** other games, other scales, the host/router/registry/catalog,
  or `mini_game_page.dart`. Registry wiring is the orchestrator's job, not yours.
- **Canvas-only.** No PNG/JPEG/SVG. The nucleus, electrons, and juice are all
  procedural.

---

## Scene / exit contract

- `IsotopesGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the outer 50 s timer, the countdown, the live score readout, and
  the results screen. Do NOT reimplement any of these.
- `widget.session.isRunning` gates gameplay. When false (intro / countdown /
  finished) the steppers are disabled and the lock does nothing — only the calm
  ready-state prompt and the drifting atom show.
- Report points only through `session.addScore`; report the success streak via
  `session.noteStreak`. Never set the clock or end the round yourself (no
  `endEarly` — there is no fail state).
- If the game throws, the host's error boundary shows a fallback exit. Never
  swallow exceptions.

---

## Architecture

One `Ticker` → one `ValueNotifier<double>` clock → one `_NuclidePainter`.
**No per-frame setState.** The painter reads a shared mutable `_AtomModel`
(z, n, matched, flash, success, particles) and repaints off the clock notifier;
`shouldRepaint => false`. `setState` is called only on discrete user actions
(stepper taps, lock) and once at run-start — never every frame.

```
IsotopesGame (StatefulWidget)
  _IsotopesGameState  (Ticker, round state, gestures)
    _onTick            // advances clock + juice; gates run-start on isRunning
    _bumpProtons/_bumpNeutrons   // setState; clamp; _refreshMatch
    _lockIn            // scores a correct lock, serves next prompt
    _pickTarget        // difficulty-aware nuclide + prompt-kind selection
  _AtomModel           // mutable sim state shared with the painter
  _NuclidePainter      // atmosphere → match aura → shells → nucleus → flash → fx
  _TargetCard / _ReadoutBar / _Stepper / _LockButton  // HUD widgets (rebuild on tap)
```

Data: `_kElements` (Z→[name, symbol], 1..26), `_kPool` (Z→plausible neutron
counts), `_PromptKind` enum, `_Nuclide` (z, n, kind).

---

## Tunable constants (top of `isotopes_game.dart`)

| Constant | Value | Effect |
|---|---|---|
| `_kMaxProtons` | 26 | Proton stepper ceiling (up to iron) |
| `_kMaxNeutrons` | 40 | Neutron stepper ceiling |
| `_kBase` | 10 | Points for any correct lock |
| `_kMaxSpeedBonus` | 10 | Extra points for an instant lock |
| `_kSpeedWindow` | 7.0 | Seconds over which the speed bonus decays to 0 |
| `_kMaxStreakBonus` | 8 | Per-lock streak-bonus cap |
| element pool `zCap` | 8→14→20→26 | Widens at 3 / 7 / 12 solves (`_allowedPool`) |
| prompt unlocks | 2 / 4 / 7 | massName / neutrons / symbol (`_chooseKind`) |

---

## Calibration (registry spec — owned by the orchestrator)

- `durationSeconds: 50`
- `humanMax: 350`
- `starThresholds: [130, 240, 330]`

Re-tune by playtest if the prompt cadence or scoring economy changes.

---

## Known TODOs / ideas (not yet built)

1. **[MED] Ions.** A third electron stepper + a "net charge" prompt axis
   ("an O²⁻ ion") would extend the lesson to ions. Deliberately out of scope for
   v1 — the two steppers stay protons/neutrons.
2. **[LOW] "Same element, new isotope" combo.** Bonus for building two isotopes
   of the same element back-to-back, to spotlight the isotope concept.
3. **[LOW] Stability tint.** Colour the nucleus by rough N/Z ratio so wildly
   unbalanced builds read as "this isotope wouldn't last" — pure flavour.
4. **[LOW] Sound.** No audio yet; the app is silent across games.
