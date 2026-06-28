# GAME.md — Whose Idea? (idea-attribution quiz)

> Canonical spec for the **somethings**-scale attribution quiz. A rapid-fire multiple-choice game:
> a big idea appears, you tap the historical thinker that accepted, recorded history credits with
> introducing it. Same genre and scoring idiom as `arcade/organ_quiz.dart` (Organ Rush), different
> content. The somethings scale already hosts "Corners"; a scale may carry multiple games — this is fine.

- **Scale (cell):** somethings
- **Game id:** `whose_idea` (widget `WhoseIdeaGame` in
  `lib/games/somethings/whose_idea/whose_idea_game.dart`)
- **Question bank:** `lib/games/somethings/whose_idea/whose_idea_data.dart` (`kWhoseIdeaBank`, ~41 items)
- **Role:** host-integrated mini-game. Score is reported to the host session via `session.addScore`;
  the streak high-water mark via `session.noteStreak`. The host (`MiniGameHost`) owns the
  clock / countdown / score HUD / results. This widget renders **only** the play area and never
  calls `endEarly`.

## ⚠️ Attribution disclaimer (load-bearing — read this)

**"History is written by the winners."** Every attribution in this game pertains to **ACCEPTED,
RECORDED history** — the credit the collective broadly agrees on. The game makes **NO claim** that
these ideas were absolutely, solely, or first originated by the credited thinkers. Priority disputes
(Newton vs. Leibniz on calculus), uncredited collaborators (Rosalind Franklin on the DNA double
helix), and independent multiple discovery (Wallace and Darwin; Stigler's law of eponymy) are the
rule, not the exception in the history of ideas.

This disclaimer is surfaced **in-game** in two places:
1. A one-time **ready-state card** before play begins ("History is written by the winners…").
2. A small **persistent footer line** during play ("Attributions reflect accepted, recorded history").

Where the credit is genuinely contested, the post-answer **context card** says so explicitly
(e.g. "Wallace reached the same idea independently"; "Photo 51 was shown to Watson without her
knowledge"). The full discussion lives in `EDUCATION.md`.

## Core loop

1. A **big idea / concept** is shown as the prompt ("Evolution by natural selection",
   "The categorical imperative", "The invisible hand of free markets", "Operant conditioning"…).
2. **Four options**, each a historical thinker. Tap the one credited with introducing the idea.
3. **Faster correct answers score more** — a speed bonus decays from max (120) to a floor (20) over
   ~4 seconds.
4. A **streak multiplier** rewards consecutive correct answers: every 3 in a row adds +1× (×1, ×2,
   ×3…). A wrong answer resets the streak to 0 but costs **no** points.
5. After **every** answer a **context card** drops: the credited thinker, the era, and a one-line
   fact — frequently the contested credit behind the attribution. This is the education beat.
6. Questions are drawn in **random order** from the bank with **no repeat until the bank is
   exhausted**, then reshuffled.

The bank spans six fields — **science, philosophy, mathematics, economics, political theory,
psychology** — each shown with its own color chip. Distractors are same-field / same-era thinkers,
so a wrong tap is plausible, not trivial.

## Scoring

- **Correct:** `speedBonus × streakMultiplier`.
  - `speedBonus` = linear decay from **120** (instant) to **20** (≥ 4 s), per `_speedBonus()`.
  - `streakMultiplier` = `1 + (streak ÷ 3)` — ×1 for streak 0–2, ×2 for 3–5, ×3 for 6–8, …
- **Wrong:** 0 points, streak resets, the correct attribution is revealed on the card.
- Reported via `session.addScore(pts)` on each correct answer; `session.noteStreak(streak)` keeps the
  results-screen streak award (a 7+ streak is strong play).

### Tuning (mirrors Organ Rush, the sibling quiz)

- **durationSeconds:** 60 (host-controlled).
- **humanMax:** **520** — a skilled 60 s run answers ~15–18 questions; fast answers (~90 avg speed
  bonus) under a building streak average out near this ceiling. Matches the calibrated Organ Rush
  value, which shares this exact scoring model.
- **starThresholds:** **[150, 320, 520]** — ⭐ casual/mixed run · ⭐⭐ fast and mostly correct ·
  ⭐⭐⭐ near-flawless speed-and-streak run.

## How to win

**Most points when the 60-second clock runs out wins.** Answer fast and keep the streak alive —
speed × streak is where the points compound.

## Implementation notes

- Self-contained in `WhoseIdeaGame` (`whose_idea_game.dart`) + the inline bank in
  `whose_idea_data.dart`. Constructor: `WhoseIdeaGame({super.key, required MiniGameSession session})`.
- Imports **only** framework utils (`../../mini_game.dart`) + its sibling data file. No dependency on
  any other game (per `lib/games/EXTRACTION_RECIPE.md`).
- A single `Ticker` drives the per-frame loop (question timer, post-answer countdown, particle
  decay) and the `CustomPainter` background — the established Organ Rush idiom. The loop only
  advances while `session.isRunning`; before that a calm ready/disclaimer state shows with options
  inert (the host overlays the countdown).
- All-Canvas background (no raster assets): dark base, a field-colored radial glow, drifting ambient
  orbs, deterministic star field, and burst particles on correct answers.

## Registry wiring (orchestrator does this — not this game's job)

```dart
import 'somethings/whose_idea/whose_idea_game.dart';

MiniGameSpec(
  id: 'whose_idea',
  name: 'Whose Idea?',
  scale: BioScale.somethings,
  tagline: 'Tap the mind history credits with the big idea',
  rules: [
    'A big idea appears with four historical thinkers.',
    'Tap the one credited with introducing it — faster answers score more.',
    'Build a streak for a multiplier; a context card drops after every answer.',
    'Attributions reflect accepted history — credit the winners wrote down.',
  ],
  howToWin: 'Most points when time runs out wins.',
  durationSeconds: 60,
  scoreUnit: 'points',
  enabled: true,
  accent: const Color(0xFFFFD600),
  icon: Icons.lightbulb_rounded,
  builder: (context, session) => WhoseIdeaGame(session: session),
  humanMax: 520,
  starThresholds: const [150, 320, 520],
),
```
