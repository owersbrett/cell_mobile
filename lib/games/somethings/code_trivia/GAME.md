# Code Trivia — Manual (M)

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** somethings
- **Game id:** `code_trivia`
- **One-line concept:** Rapid-fire 4-option programming trivia against a burning
  per-card fuse — tap the truth fast, chain streaks, and learn the why on every miss.
- **Role:** solo high-score (party-compatible via the standard host seam)
- **Six-in-one?** no

## Rules (canonical)
1. A question card shows one factual programming question (languages, concepts,
   git, HTTP, big-O, famous history) with **four answers**; exactly one is true.
2. A **fuse** starts burning when the card appears. Tap an answer before it dies.
3. **Correct** → points (base + speed bonus × streak multiplier), a spark burst,
   a quick green flash (~0.75 s), then the next card.
4. **Wrong tap or fuse-out** → the streak breaks, a red flash + small shake, and
   the correct answer is revealed with a **one-line why** (the teach-in-context
   moment). The reveal dwells ~2.6 s; tap to skip ahead.
5. **No repeats within a run.** Option order is shuffled per card.
6. Escalation: question tiers 1 → 2 → 3 by cards asked; the fuse shortens every
   card; tier-3 distractors are authored near-misses (closer together).

## Controls
Tap one of the four answer chips. Tap the reveal banner to skip its dwell.
All rendering is procedural (Canvas + widgets); no raster assets. Inline code
fragments (backtick-delimited in the bank) render in a monospace stack.

## Scoring (`scoreUnit: answers`)
- Correct: `(60 base + up to 60 speed) × multiplier`.
  - Speed bonus = `60 × (fuse remaining / fuse length)` — it literally follows the fuse.
  - Multiplier = `1 + streak ÷ 3`, capped at **×4**.
- Wrong / fuse-out: 0 points, streak resets to 0. No deductions — keep it fast and fun.
- `session.noteStreak` reports the running streak for the results-screen award.

## Win / end condition
The host owns the 60 s clock and the results. Highest score when time runs out
wins. The game never calls `endEarly` and is always quittable via the host.

## Difficulty curve (key tunables in `code_trivia_game.dart`)
| Knob | Value | Meaning |
|---|---|---|
| `_kFuseStart` | 8.0 s | first card's fuse |
| `_kFuseStep` | 0.22 s | fuse shaved per card asked |
| `_kFuseFloor` | 3.5 s | fuse never shorter than this |
| `_kTier2At` / `_kTier3At` | 8 / 16 | cards asked before tier 2 / tier 3 |
| `_kBasePoints` / `_kSpeedPoints` | 60 / 60 | scoring split |
| `_kStreakStep` / `_kMaxMultiplier` | 3 / 4 | streak → multiplier |

A perfect run becomes humanly impossible: late cards pair tier-3 near-miss
distractors with a ≤3.5 s fuse, so scores cluster at peak skill, not a ceiling.

## Question bank (`code_trivia_data.dart`)
67 questions, tiers 22/22/23. Coverage: language identities (`fun` → Kotlin),
language relationships (TypeScript = JS + static types), core concepts
(compiler/interpreter/linter, git basics, HTTP verbs/status codes, big-O of
common operations, API/IDE/regex), history-lite (Guido, Linus, Ritchie,
Stroustrup, Eich, ~1995 JS — famous and uncontested only), syntax facts
(significant whitespace, `fn`/`fun`/`func`, `#` comments). Every question is
factual and unambiguous and carries a one-line `why`.

## Educational blocks engaged
This game teaches **programming literacy** directly through the mechanic: the
miss-path IS the lesson (every wrong answer surfaces the truth plus a why), and
the speed pressure drives recall consolidation. See `EDUCATION.md` for the
block ledger. (Note: it is a general-programming game placed on the somethings
scale by orchestrator decision; it does not engage the geometry blocks.)

## Potato angle
None forced. The fuse spark is the closest thing to a hot potato — the card is
too hot to hold for long.

## Session / resume (S)
The host owns clock, countdown, score, results. On a session reset back to the
intro phase, the game rebuilds fresh pools and a fresh card (`_onSessionPhase`),
so a session can close and a clean one re-enter. Nothing persists between runs.

## ATTRACT autopilot
`session.autoPilot` answers correctly ~85% of the time (it reads the card's
answer) at a ~1.2 s human pace, and skips reveal banners — watchable b-roll.

---

## Registry wiring (orchestrator block)

```dart
// lib/games/mini_game_registry.dart — append; import the game folder:
// import 'somethings/code_trivia/code_trivia_game.dart';
MiniGameSpec(
  id: 'code_trivia',
  name: 'Code Trivia',
  scale: BioScale.somethings,
  tagline: 'Beat the fuse — prove you speak computer',
  rules: [
    'Tap the true answer before the fuse burns out',
    'Faster taps bank a bigger speed bonus',
    'Every 3 in a row raises your ×multiplier (up to ×4)',
    'Wrong or too slow: streak breaks, the truth flashes with a why',
  ],
  howToWin: 'Highest score when time runs out wins',
  durationSeconds: 60,
  scoreUnit: 'answers',
  enabled: true,
  accent: Potatuhs.glaucous, // Color(0xFF7272AB)
  icon: Icons.terminal_rounded,
  builder: (context, session) => CodeTriviaGame(session: session),
  humanMax: 3200,                    // FIRST-PASS — tune by playtest
  starThresholds: [900, 1800, 2800], // FIRST-PASS — tune by playtest
  legendFrames: codeTriviaLegendFrames,
),
```
