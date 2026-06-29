# GAME.md — Pollination Dash

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** farmSystem
- **Game id:** pollination
- **One-line concept:** Steer a **bee** around a meadow, carrying **pollen from one flower to
  another flower of the same kind** to set fruit — fast, before the blooms **wilt**, dodging
  pesticide clouds and wind.
- **Role:** solo high-score (Explore) + party-mode round (highest score wins)
- **Six-in-one?** no

## Mechanic (canonical)
1. **Steer the bee** by dragging/holding anywhere — the bee flies toward your finger (a smooth
   "seek" with arrival damping; release to coast to a hover).
2. The meadow grows **flowers in several species** (each species has its own color = its own
   pollen kind).
3. **Touch a flower to LOAD its pollen.** The bee now carries that species' pollen (shown as a
   glowing aura + a top-left pollen chip).
4. **Touch a DIFFERENT flower of the SAME species while carrying its pollen → POLLINATE it.** The
   bloom sets **fruit (a little potato)** and scores. You must travel between two flowers — sitting
   on one flower never scores (the "must visit a different flower" rule is the whole point).
5. Pollinating **keeps the pollen loaded**, so sweeping a patch of same-color flowers chains a
   **combo** (a chain-life bar drains between visits — keep moving to hold it).
6. Touching a flower of a **new species** swaps your carried pollen to that kind.

## Pressure & hazards
- **Wilt timer:** every open bloom has a draining ring; let it empty and the flower **wilts away**
  (lost opportunity) then regrows fresh. The bloom desaturates as its window closes.
- **Pesticide clouds:** drift across the field; flying into one **strips your pollen and breaks
  the combo** (brief woozy stun + screen flash).
- **Wind gusts:** periodic directional shoves that knock the bee off course.

## Controls
Drag / press-and-hold to steer the bee toward your finger. Canvas-drawn only (bee, flowers,
fruit, clouds, gust streaks, particles) — no raster assets.

## Scoring
- Each pollination: `10 + min(combo, 15) × 4` points.
- Combo increments on each pollination within the chain window (1.9 s); it resets on a missed
  window or a pesticide hit.
- `session.noteStreak(combo)` reports the chain so the results screen can award mastery.
- **Score unit:** "fruit set".

## Win / end condition
60-second score attack. Most fruit set (highest score) when time runs out wins.

## Difficulty curve (over the 60 s)
Driven by the host clock (`session.remaining`): live flower count **5 → 14**, species **3 → 5**,
wilt window **7.5 s → 3.4 s**, pesticide clouds **0 → 3** (faster), wind gusts more frequent and
stronger.

## Tunable constants (single block at top of the file)
Bee: `_kBeeMaxSpeed 540`, `_kBeeArriveRadius 70`, `_kBeeSteerLerp 0.00075`. Flowers: `_kMaxSlots
14`, `_kFlowerHitRadius 30`, `_kWiltMaxEasy/Hard 7.5/3.4`. Combo: `_kComboWindow 1.9`, `_kScoreBase
10`, `_kComboBonus 4`, `_kComboCap 15`. Hazards: `_kMaxClouds 3`, `_kStunTime 0.7`, gust interval
`7.0 → 2.6 s`, gust strength `230 → 540`.

## Calibration
`humanMax: 2000`, `starThresholds: [500, 1000, 1600]` — first-pass, tune by playtest.

## Educational hook (E — see EDUCATION.md)
The score loop **is** the lesson: you only earn points by physically moving pollen **between two
different flowers of the same species** — exactly how a real pollinator sets fruit/seed. Threats in
the game (pesticide, losing pollen) mirror real threats to bees. ~1/3 of crop production depends on
animal pollinators.

## Session / resume
Stateless per run — the host owns the clock, score and results. A round closes cleanly and a fresh
one starts from the calm ready state (flowers blooming, bee following the finger, no hazards or
scoring until `isRunning`).
