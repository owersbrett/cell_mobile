# GAME.md — Life Cycle (Organism scale)

> Canonical rules manual (the **M** in GAMES). A fast "what comes next" — NOT a drag-order puzzle.

- **Scale (cell):** organism
- **Game id:** `life_cycle` (widget: `LifeCycleGame` in
  `lib/games/organism/life_cycle/life_cycle_game.dart`)
- **Verb:** PREDICT-NEXT.
- **One-line concept:** An organism's life-cycle wheel turns; the CURRENT stage is shown and you
  tap the correct NEXT stage from four options. Fast correct picks score more and build a streak.
- **Role:** solo score-attack (also drops into party rotation via the spec).

## Core loop
1. A wheel for one organism turns on screen, its full cycle laid out as nodes; the current stage
   node glows and the NEXT node is a `?`.
2. The prompt reads **"What comes after &lt;current stage&gt;?"** with the organism name and a
   metamorphosis-type chip.
3. Four option cards appear (one correct next stage + three distractors).
4. **Tap the correct next stage.** Faster = more points (speed bonus decays over ~3.5s).
5. After the tap, a flare reveals the correct next stage (on a miss) plus a one-line biology fact;
   tap it (or wait) to advance to the next round.

## Scoring
- Correct: `speedBonus × streakMultiplier`. Speed bonus runs 120 (instant) → 20 (slow) over 3.5s.
- Streak multiplier: +1× every 3 consecutive correct (×1, ×2, ×3 …). One miss resets the streak.
- Wrong: 0 points, no penalty (keep it fast and fun). The correct answer is revealed.
- `scoreUnit`: "transitions".

## How to win
Most correct life-cycle transitions before the host timer runs out. Answer fast and keep the streak
alive for the multiplier.

## Acceleration (it gets harder)
- **Faster wheel** — rotation speed climbs with rounds answered.
- **More organisms** — tier 0 (butterfly, frog, chicken, sunflower) for the first ~5 rounds, then
  tier 1 (ladybug, bee, apple tree, sea turtle, potato), then tier 2 (grasshopper, dragonfly,
  mosquito, cockroach — incomplete metamorphosis & confusable aquatic larvae).
- **Trickier distractors** — early distractors come from OTHER organisms (easy to rule out); later
  they are SIBLING stages from the same cycle, so you must know the ORDER, not just recognise a word.

## Organisms & metamorphosis types (the lesson)
- **Complete metamorphosis** (egg → larva → pupa → adult): butterfly, ladybug, bee, mosquito.
- **Incomplete metamorphosis** (egg → nymph → adult, no pupa): grasshopper, dragonfly, cockroach.
- **Direct development** (no metamorphosis): chicken, sea turtle.
- **Plant life cycle** (seed → seedling → plant → flower → seed): sunflower, apple tree, potato.

## Potato angle
The **Potato** is a playable cycle (seed potato → sprout → plant → flower → tuber → seed potato) and
its fact is the organism-scale headliner: *a potato is an organ of the plant, but an organism once it
grows an eye and is planted — the tuber IS the next seed.*

## Implementation notes
- Self-contained module. Imports ONLY `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`, and Flutter. No other game's code.
- **One Ticker → one background `CustomPainter`** (`_WheelPainter`: atmosphere + turning wheel +
  particles). The widget tree is tiny (HUD chip, prompt, four cards) and rebuilds on the throttled
  per-frame `setState`, like `arcade/organ_quiz.dart`.
- Host owns clock/countdown/score/results; the game never calls `endEarly` and reports only via
  `session.addScore` / `session.noteStreak`. Calm idle state when `!session.isRunning` (wheel just
  spins, taps ignored), auto-plays on `isRunning`.
- All organism/stage/fact data is inline `const` in the module — no asset files, no shared data dep.
