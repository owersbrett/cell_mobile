# pH Balance v2 — Agent (A)

The owning agent for `ph_balance_v2`. Improve THIS game only; do not touch the
registry, catalog, host, or sibling games.

## Charter
Keep the lesson (acids lower pH / bases raise it, the 0–14 universal-indicator
scale, the steep-near-7 titration curve, neutralization, CO₂ acid-creep) while
holding the Fun-Multiplayer UX bar. This module is the UX-pass alternative to
`ph_balance`; the original stays playable alongside it.

## Invariants (do not regress — these ARE the teardown fixes)
- **Responsive needle + predictive ghost.** v1 eased the needle via
  `exp(-dt*14)` so a tap landed a frame late and overshoot felt like input lag.
  v2 lands `_kTapSnap` (60%) of every drop on the visible needle the SAME frame
  in `_addDrop`, then settles fast (`_kNeedleEase`). The `_ghostAcid`/`_ghostBase`
  getters drive scale ticks showing where the next drop lands — the steep leap
  must stay a *read before the tap*. Do not reintroduce a slow ease or drop the
  ghost.
- **Active hold (no camping).** CO₂ acid-creep (`_driftRate`) is ALWAYS ON — the
  pH slides down every frame, so holding is feathering taps to keep the needle
  centred and fill `_lock`. v1's passive `+4/s` drip for sitting still is GONE.
  Do not re-add any in-band passive score.
- **Fair, capped scoring.** Each lock scores THIS-attempt precision + speed only,
  hard-capped (`_kScoreBase + _kScorePrecision + _kScoreSpeed`, plus a flat
  `_kScoreSurge`). `_level` ramps difficulty ONLY and must never feed score.
  `_streak` feeds `noteStreak` (mastery award) ONLY. No compounding term.
- **The Keep (education).** Preserve `_steep(pH)` (gaussian peaked at 7), the
  universal-indicator `_kPhColors` ramp on liquid AND scale, the 0–14 strip with
  the dashed neutral-7 line, the ACIDIC/NEUTRAL/BASIC tag, and the CO₂ creep as
  chemistry-true difficulty. The STEEP-zone shading makes the curve *shown*.
- **One Ticker → one CustomPainter.** No second AnimationController; no per-frame
  allocations beyond the bubble/particle/pop lists.

## The titration model (load-bearing math)
- Drop effect: `delta = _dropStrength × _steep(pHgoal)`,
  `_steep(p) = 1 + steepK · exp(−(p−7)²/(2σ²))`.
- INVARIANT: max near-7 drop = `_kDropMax·(1+_kSteepMax) = 0.165·3.8 ≈ 0.627`,
  which stays under `2·_kTolMin = 0.84`, so near-neutral targets remain landable
  by pumping through the band. Re-check this if you raise any drop/steep cap.

## Tuning knobs (top of file)
Needle: `_kNeedleEase`, `_kTapSnap`. Band: `_kTolStart/Step/Min`. Lock:
`_kLockStart/Step/Min/Decay`. Drop: `_kDropBase/Step/Max`. Steep:
`_kSteepBase/Step/Max`, `_kSigma`. Creep: `_kDriftStart/Step/Max`. Score:
`_kScoreBase/Precision/Speed/Surge`, `_kSpeedFull/Zero`. Surge:
`_kSurgeRemaining/Drift/Tol`. `humanMax` / `starThresholds` live in the registry
spec — playtest to tune.

## Test
`flutter analyze lib/games/molecular/ph_balance_v2/` → zero. Session re-entry:
the host owns the clock; on a fresh run `_startRound()` re-arms from `isRunning`
(`_wasRunning` edge) and reseeds pH/level/streak/target — close and re-enter must
start clean (calm green beaker idling at pH 7, buttons disabled).

## Registry spec (for the registry owner — DO NOT self-add)
```dart
import 'molecular/ph_balance_v2/ph_balance_v2_game.dart';

MiniGameSpec(
  id: 'ph_balance_v2',
  name: 'pH Balance v2',
  scale: BioScale.molecular,
  tagline: 'Titrate to the target and feather the drift to lock it.',
  rules: [
    'Tap ACID (H⁺) to lower pH, BASE (OH⁻) to raise it',
    'Ghost ticks show where the next drop lands — near pH 7 it leaps',
    'Stay centred in the band to fill the LOCK ring',
    'CO₂ keeps acidifying — tap to hold your ground',
  ],
  howToWin: 'Lock the most target pHs before time runs out.',
  durationSeconds: 55,
  scoreUnit: 'locks',
  enabled: true,
  accent: Color(0xFF3DDC97),
  icon: Icons.science,
  builder: (context, session) => PhBalanceV2Game(session: session),
  humanMax: 1100,
  starThresholds: [400, 700, 1000],
),
```
