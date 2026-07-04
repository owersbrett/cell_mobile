# GAME.md — Parse

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** somethings — the "first distinctions" scale. Naming what a
  symbol-blob IS is the first distinction.
- **Game id:** `parse`
- **One-line concept:** A short code snippet appears; tap what construct it IS
  (FUNCTION / CLASS / VARIABLE / INTERFACE, growing to LOOP / IMPORT / ENUM),
  reading past the language's surface syntax.
- **Role:** solo high-score (both — network-agnostic host, works in party too)
- **Six-in-one?** no

## Rules (canonical)
1. One snippet is shown at a time on a code card, with a **language chip**
   naming the language (Python / Swift / Kotlin / Java / TypeScript /
   JavaScript). The language is given — the player is NOT guessing it.
2. The player taps the **construct chip** that names what the snippet is.
3. **Correct** → points (speed-scaled) + streak grows + green flash + particle
   burst. The chip lights green.
4. **Wrong** → streak resets to 0, the card shakes, a red flash fires, and the
   correct chip flashes green (teach in-context). No points are deducted.
5. **Timeout** (late phase, per-card timer) → same as wrong; the card auto-fails
   and reveals the correct construct.
6. **No immediate snippet repeats** — a rolling memory of the last 6 snippets is
   excluded from selection.
7. Every reveal shows a one-line **tell** for tricky forms (e.g. "An arrow
   function — still a FUNCTION, even assigned to a const").

## Controls
Tap a construct chip (Canvas/widget-drawn, no raster assets). Tap again during
the reveal to skip to the next card. Fully quittable via the host.

## Scoring (`scoreUnit: "constructs"`)
- Correct: **speed bonus × streak multiplier**.
  - Speed bonus decays from **110 → 30** over the answer window (a fixed 3.5s in
    early phases; the shrinking per-card limit in the late phase).
  - Streak multiplier: **+1× every 3** consecutive correct (×1, ×2, ×3…).
- Wrong / timeout: **0 points**, streak resets.

## Win / end condition
The host owns the 60-second clock. Highest score when time runs out wins (solo:
score attack; party: high score takes the round).

## Difficulty curve
Escalation is driven off run fraction (`_phaseFor`):
- **Phase 0** (`f < 0.22`): single language (Python/JavaScript), obvious forms
  only (no tricky), 4 base chips, no per-card timer.
- **Phase 1** (`0.22 ≤ f < 0.55`): all six languages mix in, tricky forms
  allowed, still 4 base chips.
- **Phase 2** (`f ≥ 0.55`): LOOP / IMPORT / ENUM chips unlock (7 chips),
  trickiest snippets preferred (~65%), and a **per-card timer appears and
  shrinks** from 6.0s → 3.2s across the phase; a card auto-fails on timeout.

Key tunables (in `parse_game.dart`): `_kMaxPoints`, `_kFloorPoints`,
`_kDecayWindow`, `_kStreakStep`, `_kCardLimitStart/End`, `_kRecentMemory`, the
`_phaseFor` thresholds.

## Educational blocks engaged
Teaches the mechanic of **construct recognition across languages** — that a
FUNCTION is a FUNCTION whether it's a Python `def`, a JS arrow, a Kotlin
single-expression `fun`, or an anonymous callback; that Swift `protocol` and
Python `Protocol` ARE interfaces; that `const x = require(...)` is an IMPORT.
The tricky snippets are the lesson: surface syntax varies, the underlying
construct is the invariant. See `EDUCATION.md`.

## Potato angle
None forced — the through-line here is the somethings-scale "first distinction"
idea (naming what a blob IS), not a literal potato.

## Session / resume
Stateless across runs: the host owns clock/countdown/score/results. A fresh run
starts from phase 0 automatically (phase is derived from the host's run
fraction, not stored). Nothing to persist — close and re-enter cleanly.

---

## Registry wiring (for the orchestrator)

```dart
MiniGameSpec(
  id: 'parse',
  name: 'Parse',
  scale: BioScale.somethings,
  tagline: 'Name the construct — read past the syntax',
  rules: const [
    'A code snippet appears — tap what it IS',
    'FUNCTION / CLASS / VARIABLE / INTERFACE… then LOOP / IMPORT / ENUM',
    'Right: points + streak. Wrong or timeout: streak resets',
    'Answer fast — the bonus falls and, late, a card timer shrinks',
  ],
  howToWin: 'Most constructs identified when time runs out wins',
  durationSeconds: 60,
  scoreUnit: 'constructs',
  enabled: true,
  accent: const Color(0xFF7E57C2), // somethings purple
  icon: Icons.data_object_rounded,
  builder: (context, session) => ParseGame(session: session),
  humanMax: 3200,            // first-pass — tune by playtest
  starThresholds: const [900, 1800, 2900], // first-pass — tune by playtest
  legendFrames: parseLegendFrames,
)
```

`ParseGame` and `parseLegendFrames` are exported from
`lib/games/somethings/parse/parse_game.dart`.
```
