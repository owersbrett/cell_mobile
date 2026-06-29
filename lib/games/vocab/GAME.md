# GAME.md — Vocab Engine (+ Finance Lingo)

> Canonical spec for the **reusable vocab mini-game engine** and its first instance, **Finance Lingo**.
> A rapid-fire multiple-choice recall game: a definition appears, you tap the term it describes. Same
> genre and scoring idiom as `arcade/organ_quiz.dart` (Organ Rush) and
> `somethings/whose_idea/whose_idea_game.dart` (Whose Idea?), but fully **DATA-DRIVEN** — one engine,
> a `VocabBank` per domain.

- **Engine:** `VocabGame` in `lib/games/vocab/vocab_game.dart` (also defines the models `VocabTerm` /
  `VocabBank`).
- **First bank:** `kFinanceVocab` in `lib/games/vocab/vocab_banks.dart` (~30 finance terms).
- **First instance id:** `finance_vocab` — name **"Finance Lingo"**, scale `BioScale.financial`.
- **Role:** host-integrated mini-game. Score is reported to the host session via `session.addScore`;
  the streak high-water mark via `session.noteStreak`. The host (`MiniGameHost`) owns the
  clock / countdown / score HUD / results. This widget renders **only** the play area and never
  calls `endEarly`.

## The engine is reusable by design

The whole point: **every scale can have a vocab game for the cost of a data file.** The engine is
fully parameterized by the `VocabBank` you hand it — gameplay, scoring, layout and juice are
identical across domains; only the content changes.

> **Adding a new per-scale vocab game = a new `VocabBank` + a registry spec. NO new game code.**

```dart
// 1. Define a bank (in vocab_banks.dart or a sibling file):
const VocabBank kBiologyVocab = VocabBank(title: 'Biology', terms: [ /* VocabTerm… */ ]);

// 2. Register a spec that points the SAME VocabGame at the new bank:
MiniGameSpec(
  id: 'biology_vocab', name: 'Cell Lingo', scale: BioScale.cell, /* … */
  builder: (context, session) => VocabGame(session: session, bank: kBiologyVocab),
)
```

## Core loop

1. A **definition** is shown as the prompt ("How quickly an asset can be sold for cash…").
2. **Four options**, each a term. Tap the one the definition describes.
3. **Faster correct answers score more** — a speed bonus decays from max (120) to a floor (20).
4. The bonus's **decay window shortens as the round runs** (4.0 s → 2.0 s) — *escalating speed*: the
   longer you play, the faster you must answer to bank full points.
5. A **streak multiplier** rewards consecutive correct answers: every 3 in a row adds +1× (×1, ×2,
   ×3…). A wrong answer resets the streak to 0 but costs **no** points.
6. After **every** answer a **reinforcement card** drops: the term, its definition, and the optional
   one-line note. This is the active-recall education beat.
7. Terms are drawn in **random order** with **no repeat until the bank is exhausted**, then
   reshuffled. Distractors come from the term's own `distractors` list (padded from the bank if short).

## Scoring

- **Correct:** `speedBonus × streakMultiplier`.
  - `speedBonus` = linear decay from **120** (instant) to **20** (≥ the current decay window).
  - decay window = `max(2.0, 4.0 − 0.1 × answered)` seconds — shrinks as the round escalates.
  - `streakMultiplier` = `1 + (streak ÷ 3)` — ×1 for streak 0–2, ×2 for 3–5, ×3 for 6–8, …
- **Wrong:** 0 points, streak resets, the correct term is revealed on the card.
- Reported via `session.addScore(pts)` on each correct; `session.noteStreak(streak)` for the
  results-screen streak award.

### Tuning (mirrors Organ Rush / Whose Idea?, the sibling quizzes)

- **durationSeconds:** 60 (host-controlled).
- **humanMax:** **520** — a skilled 60 s run answers ~15–18 questions; fast answers under a building
  streak average near this ceiling. Matches the calibrated sibling-quiz value (shared scoring model).
- **starThresholds:** **[150, 320, 520]** — ⭐ casual/mixed run · ⭐⭐ fast and mostly correct ·
  ⭐⭐⭐ near-flawless speed-and-streak run.

## How to win

**Most points when the 60-second clock runs out wins.** Answer fast and keep the streak alive —
speed × streak is where the points compound, and the speed bar tightens as you go.

## Implementation notes

- Self-contained in `VocabGame` (`vocab_game.dart`) + banks in `vocab_banks.dart`. Constructor:
  `VocabGame({super.key, required MiniGameSession session, required VocabBank bank})`.
- Imports **only** framework utils (`../mini_game.dart`) — no dependency on any other game (per
  `lib/games/EXTRACTION_RECIPE.md`). `vocab_banks.dart` imports only `vocab_game.dart` for the models.
- A single `Ticker` drives the per-frame loop (question timer, post-answer countdown, particle decay)
  and the `CustomPainter` background — the established quiz idiom. The loop only advances while
  `session.isRunning`; before that a calm ready state shows with options inert (the host overlays the
  countdown).
- All-Canvas background (no raster assets): dark base, an accent radial glow, drifting ambient orbs,
  deterministic star field, and burst particles on correct answers.

## Registry wiring (orchestrator does this — NOT this game's job)

```dart
import 'vocab/vocab_game.dart';
import 'vocab/vocab_banks.dart';

MiniGameSpec(
  id: 'finance_vocab',
  name: 'Finance Lingo',
  scale: BioScale.financial,
  tagline: 'Match the definition to the right money term',
  rules: [
    'A definition appears with four candidate terms.',
    'Tap the term it describes — faster answers score more.',
    'The pace tightens as you go; build a streak for a multiplier.',
    'A card after every answer reinforces the term and its meaning.',
  ],
  howToWin: 'Most points when time runs out wins.',
  durationSeconds: 60,
  scoreUnit: 'points',
  enabled: true,
  accent: const Color(0xFF4CAF50),
  icon: Icons.savings_rounded,
  builder: (context, session) => VocabGame(session: session, bank: kFinanceVocab),
  humanMax: 520,
  starThresholds: const [150, 320, 520],
),
```
