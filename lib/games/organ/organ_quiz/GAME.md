# GAME.md — Organ Rush (reworked from "Grow the Plant")

> The canonical spec. Replaces the old elemental-phases "Grow the Plant" game on the Organ scale.

- **Scale (cell):** organ
- **Game id:** organ_rush (replaces `grow_the_plant`)
- **One-line concept:** Rapid-fire multiple choice — "The part that does X" with 4 options. Answer
  fast for more points. Alternates between **human organs** and **plant/potato organs.**
- **Role:** solo high-score
- **Six-in-one?** no

## Why the rework
The old Grow the Plant (4 elemental phases) was busy but didn't teach organs. The Organ scale is
about organs, so the game becomes a fast organ-identification quiz spanning **two bodies** — the
human body and the plant (mostly potato) — so players learn the parallel: every body, animal or
plant, is organs doing jobs.

## Rules (canonical)
1. A prompt appears: **"The part that ..."** (e.g. "...pumps blood through your body"), with **4
   tappable options.**
2. Tap the correct organ. **The faster you answer, the more points** — a per-question timer decays
   the available points (e.g. full points in the first ~1s, sliding down to a floor).
3. **Wrong answer:** small penalty / no points, brief shake on the wrong option, the correct one
   highlights.
4. Questions **alternate realm: human → plant → human → plant ...** (so you ping-pong between the two
   bodies). Shuffle within each realm; don't repeat a question until the pool recycles.
5. **After each answer, a fun-fact flare** shows the question's `fact` (our signature mechanic) —
   brief, non-blocking, then the next question loads.
6. Timed round (~45–60 s) — answer as many as you can. Most points wins.

## Content
- Data: `lib/games/organ/organ_quiz_data.dart` → `kOrganQuiz` (32 questions, `OrganRealm.human` /
  `OrganRealm.plant`, each with `prompt`, `answer`, 3 `wrong` distractors, and a `fact`). Shuffle
  `question.options` per question.

## Controls
Tap an option card. Option cards are Flutter widgets (Containers/GestureDetectors) styled to match
the app; background/fx Canvas-drawn. No raster assets.

## Scoring (tune on build)
- Correct: `base + speedBonus` where speedBonus decays with answer time (reward sub-second answers).
- A streak multiplier for consecutive correct answers feels good here — consider it.
- Wrong: 0 or a small penalty; never hard-fail (keep it fast and forgiving).

## Win / end condition
Timed score attack. Round ends on the timer; show total + correct count.

## Educational blocks engaged
- Organ scale plant blocks (Root, Stem, Leaf, Flower, Seed, Fruit) — ✅ directly quizzed.
- Plus a parallel set of **human organs** (heart, lungs, liver, kidneys, brain, …) — broadening the
  scale beyond plants (the potato stays the headline plant body). The fun-fact flare carries extra
  learning on every answer.

## Potato angle
The plant half is mostly potato: the tuber is a *stem* (not a root), the eyes are buds, green skin
makes solanine. Human-vs-potato ping-pong keeps the potato present without making every question potato.

## Session / resume
Build to the **MiniGameSession** interface (like the other registry games — takes a session, uses
`session.isRunning` / `session.addScore`) so it slots into the registry, Explore, the picker, and
party mode. Persist: question index, score, streak, realm toggle, current-question timer.

## Implementation
- New widget `OrganQuizGame` in `lib/games/arcade/organ_quiz.dart`, constructed `(session)`.
- **Registry swap (follow-up, NOT done by the build agent):** point the Organ spec's `builder` to
  `OrganQuizGame`, update `name`/`tagline`/`icon`/`scoreUnit` (e.g. name "Organ Rush", scoreUnit
  "points"). Done by the lead, after the widget exists, so it compiles.
