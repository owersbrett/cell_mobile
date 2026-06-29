# AGENT.md — Membrane Gate v2

The agent (A in GAMES) accountable for this game module.

- **Module:** `lib/games/organelle/membrane_gate_v2/membrane_gate_v2_game.dart`
- **Widget:** `MembraneGateV2Game extends StatefulWidget { final MiniGameSession session; }`
- **Registry id:** `membrane_gate_v2` · **Scale:** organelle
- **Origin:** UX Refinement Pass (Sprint 1), the alternative to `membrane_gate`.
  Brief: `docs/ux_pass/teardowns/membrane_gate.md`. Coexists with v1 for A/B.

## Charter

Own selective-permeability play at the organelle scale. Keep the lesson exact
(see EDUCATION.md) while holding the Fun-Multiplayer UX bar. Education is
non-negotiable; fun is sharpened *around* it, never at its expense.

## What changed vs the original (the teardown fixes)

1. **Legibility (failures #1 & #2).** Wanted vs unwanted now sort
   pre-attentively by **silhouette + luminosity + an affordance badge**:
   wanted = bright body, smooth shape, pulsing cyan import ring + ↓ chevron;
   unwanted = muddy body, jagged hazard ring, red **✕** badge. Na⁺/K⁺ recoloured
   off green so they can't collide with the now-muddy Toxin. Labels kept but no
   longer load-bearing.
2. **Live score (failure #1).** Big in-widget score + score-unit, an always-on
   multiplier pill, and a **PACE bar** with a par tick. Never depends on host
   chrome for the deciding number.
3. **Fair scoring (failure #3).** Toxin tap = **no negative score** — streak
   reset + a 0.85 s import **lockout** + flash/shake. Restraint now has teeth and
   feedback. The ready screen demonstrates the don't-tap verb with worked
   examples.
4. **Lifted ceiling + skill.** Multiplier ×1→×6 (was ×3); a **PERFECT** bonus
   for catching molecules high keeps a clean run paying off all 60 s.
5. **Catch-up.** Behind par → slower fall + a golden **rescue nutrient** (×3).
6. **Climax.** Final 10 s "FINAL PUSH" surge (faster spawns, red vignette, ×1.5
   imports) + a big final-molecule beat. Haptics on good/toxin/climax.

## Invariants — do not break

- **One Ticker → one CustomPainter** via `_RepaintNotifier`. No per-frame
  setState. `shouldRepaint => false`. Keep it.
- Gate all play on `session.isRunning`; report via `session.addScore` /
  `session.noteStreak`. Host owns clock + results; never self-`endEarly`.
- **Score never goes negative by design** (also clamped by the session).
- Self-contained module: depend only on `mini_game.dart`, `fx.dart`,
  `theme/potatuhs.dart`, Flutter, `dart:math`, `flutter/services` (haptics).
  Never import another game.
- Keep the wanted taxonomy, the three channel proteins lighting by transport
  type, and the per-intake route one-liner — that is the lesson.

## Tuning knobs (top of file)

`_kSpawnEarly/_Late/_Climax`, `_kFallEarly/_Late`, `_kGoodScore`,
`_kPerfectBonus`, `_kLockout`, `_mult` cap, par factor (`_par`). Tune by
playtest; update `humanMax` / `starThresholds` in the registry spec to match.

## Verify

`flutter analyze lib/games/organelle/membrane_gate_v2/` → zero issues.
