# AGENT.md — pH Balance

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/molecular/ph_balance/` (the widget + these docs).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/theme/potatuhs.dart`,
  `lib/games/fx.dart` — no edits without escalation.
- **Do not touch** other games, the registry (`mini_game_registry.dart`), the catalog
  (`game_catalog.dart`), or the host (`mini_game_host.dart`). The spec for the registry
  entry is recorded at the bottom of this file for whoever owns the registry — you do not
  add it yourself.

## Scene / exit contract
- Host-owned clock/score/countdown/results. This widget renders ONLY the play area.
- A run begins on the `isRunning` rising edge (`_startRound`); it never ends itself.
- Calm ready state: when not running, the beaker idles green (pH 7) with gentle bubbles and
  the buttons are dimmed/disabled; the HUD shows `BALANCE THE pH`.
- Report progress through `session.addScore` and `session.noteStreak` only.

## Files
- Widget: `ph_balance_game.dart` → `PhBalanceGame`
- Spec: `GAME.md` (canonical rules — obey it; if rules change, update GAME.md first)
- Education: `EDUCATION.md` (this game's slice) + `../EDUCATION.md` (scale-wide)
- POTATUHS lens: `POTATUHS.md`

## Architecture (perf contract)
- **One `Ticker`** (`_onTick`) advances all state with a clamped `dt` (≤ 0.05 s).
- **One `CustomPainter`** (`_PhPainter`) draws everything except the two bottom buttons.
- Taps call `_addDrop` which **mutates fields without `setState`**; the running ticker
  repaints next frame. Do not add per-tap `setState` or per-frame widget-tree rebuilds.
- The two `_DropButton`s are separate `StatefulWidget`s (own press-scale state) so their
  feedback doesn't rebuild the painter tree.

## Tunable constants (current — all at file top)
| Constant | Value | Effect |
|---|---|---|
| `_kTolStart / Step / Min` | 0.90 / 0.06 / 0.35 | Target band half-width, tightens per level |
| `_kHoldStart / Step / Min` | 1.25 / 0.04 / 0.75 | Seconds in-band to lock a target |
| `_kDropBase / Step / Max` | 0.090 / 0.012 / 0.200 | pH delta per drop (pre-steepness) |
| `_kSteepBase / Step / Max` | 1.8 / 0.12 / 3.2 | Strength of the near-7 steep spike |
| `_kSigma` | 1.7 | Width of the steep region around pH 7 |
| `_kDriftStep / Max` | 0.05 / 0.35 | CO₂ acid-creep (level ≥ 3) |
| `_kTargetDrift` | 0.18 pH/s | Moving target (level ≥ 4) |
| `_kHitBase / Bonus` | 40 / 30 | Target-hit points + centered bonus |
| `_kDripPerSec` | 4.0 | Points/sec while holding |
| `_kHoldPullback` | 0.7 | Hold-meter bleed when out of band |

## The titration model (the load-bearing math)
- Drop effect: `delta = dropStrength × steep(pHgoal)`, `steep(p) = 1 + steepK · exp(−(p−7)²/(2σ²))`.
- So near pH 7 each drop is up to `(1+steepK)×` as strong → the needle leaps across neutral,
  overshoots, and slings to the other side. That IS the educational payload — do not flatten
  the curve or the lesson disappears.
- Keep it humanly possible: at max difficulty the near-7 drop (`0.20 × 3.2 ≈ 0.64 pH`) stays
  just under `2 × tolMin (0.70)` so the band is still landable. If you raise `_kDropMax` or
  `_kSteepMax`, re-check this invariant or near-neutral targets become impossible.

## Known notes / TODOs
- `humanMax` / `starThresholds` in the registry spec are first-pass estimates — tune by
  playtest (see registry block below).
- No haptics yet; a tap-tick on each drop and a heavier thunk on a target-lock would help.
- The acid-creep + moving-target facets are deliberately subtle; if playtesters don't notice
  the "homeostasis" pressure, bump `_kDriftStep` before touching anything else.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
- Liquid + scale colored by `_kPhColors` (universal-indicator ramp, one per integer pH).
- Beaker = rounded-bottom RRect, gradient liquid, wobble surface, white bubbles.
- Buttons = tinted rounded rects (acid red / base blue) with icon + label + sublabel.

## Registry spec (for the registry owner — DO NOT self-add)
```dart
// import line (mini_game_registry.dart):
import 'molecular/ph_balance/ph_balance_game.dart';

// MiniGameSpec entry:
MiniGameSpec(
  id: 'ph_balance',
  name: 'pH Balance',
  scale: BioScale.molecular,
  tagline: 'Titrate the beaker to the target pH — and hold it steady.',
  rules: [
    'Tap ACID to lower pH, BASE to raise it',
    'Land in the target band and hold to lock it',
    'Near pH 7 the curve is steep — drops swing hard',
  ],
  howToWin: 'Hit the most targets before time runs out.',
  durationSeconds: 50,
  scoreUnit: 'balance',
  enabled: true,
  accent: Color(0xFF3DDC97),
  icon: Icons.science,
  builder: (context, session) => PhBalanceGame(session: session),
  humanMax: 900,
  starThresholds: [300, 550, 800],
),
```
