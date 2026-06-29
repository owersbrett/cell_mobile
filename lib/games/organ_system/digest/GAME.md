# GAME.md — Digest

> Canonical rules manual for the organ-system-scale game **Digest**.

- **Scale (cell):** organSystem
- **Game id:** digest
- **Widget:** `DigestGame(session)` — `lib/games/organ_system/digest/digest_game.dart`
- **One-line concept:** Route a morsel of food (a *bolus*) down the digestive tract, doing the right
  organ's job at each stage.
- **Role:** solo high-score (also drops into party rotation).
- **Verb:** ROUTE-THROUGH-STAGES.

## The tract (the sequence you are learning)
Food travels left → right through five stages, each with its own action:

| # | Stage | Action button | What the organ does |
|---|-------|---------------|---------------------|
| 0 | MOUTH | **CHEW** | Mechanical + chemical breakdown begins (teeth, saliva). |
| 1 | ESOPHAGUS | **SWALLOW** | Peristalsis pushes the bolus down to the stomach. |
| 2 | STOMACH | **CHURN** | Acid + muscle churn the bolus into chyme. |
| 3 | SMALL INTESTINE | **NUTRIENTS** | **Almost all nutrient absorption** into the blood. |
| 4 | LARGE INTESTINE | **WATER** | **Water (and salt) reabsorption**; the rest is expelled. |

## How it plays
1. Food enters at the MOUTH on a timer.
2. Each stage's work takes a beat — the bolus **ripens** (a ring sweeps around it). When done it
   **glows gold** and the stage's action button lights up.
3. **Tap the matching action button while the bolus glows** → the bolus advances to the next stage and
   you score. Nutrients (small intestine) and water (large intestine) absorbed at the correct stage
   score the most.
4. A stage holds **one bolus at a time**. If the next stage is full, the bolus can't move (`FULL`) —
   you must **clear the front of the tract first** (the pipeline lesson).
5. **Mis-actions stall it:** pressing a button when its stage isn't ripe (`TOO SOON`) or has no food
   (`NOTHING HERE`) breaks your streak and knocks the bolus's progress back.

## Scoring
- CHEW / SWALLOW: +4 each · CHURN: +6 · **ABSORB NUTRIENTS: +16** · **ABSORB WATER: +10**
- Fully processed (exits the large intestine): **+8 completion bonus**.
- **Streak:** consecutive correct actions; any mis-action resets it. Reported via `noteStreak`.
- `scoreUnit`: "processed".

## How to win
Most food processed and nutrients + water absorbed when time runs out wins.

## Acceleration (difficulty ramp)
- Intake interval ramps **2.3 s → 0.95 s** (food arrives faster).
- Ripen time ramps **0.85 s → 0.48 s** (stages finish sooner).
- Result: up to **five boluses on the tract at once**, one per stage — you juggle every action.

## Spec (registry)
- `durationSeconds`: 55 · `humanMax`: 700 · `starThresholds`: [240, 440, 640]
- `accent`: `Color(0xFFE0734B)` · `icon`: `Icons.lunch_dining` · `enabled`: true

## Session / resume
Built to the **MiniGameSession** interface: takes a session, gates on `session.isRunning`, reports via
`session.addScore` / `session.noteStreak`. Host owns clock, countdown, score HUD and results. A run can
close and a fresh one re-enter cleanly (host `hostReset`); this widget keeps no cross-run state.

## Dependency rule
Imports only: `flutter`, `dart:math`, `../../mini_game.dart`, `../../fx.dart`,
`../../../theme/potatuhs.dart`. No other game's code. One Ticker → one CustomPainter.
