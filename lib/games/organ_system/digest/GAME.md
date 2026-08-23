# GAME.md — Digest

> Canonical rules manual for the organ-system-scale game **Digest**.
> **Rules are the asset; the `.dart` is disposable.** This spec outranks the implementation — lock
> changes here first.

- **Scale (cell):** organSystem
- **Game id:** digest
- **Widget:** `DigestGame(session)` — `lib/games/organ_system/digest/digest_game.dart`
- **One-line concept:** Run a living digestive tract: chew food thoroughly, spit out the bad, survive
  chokes and spice, and flush when the body is full.
- **Role:** solo high-score (also drops into party rotation).
- **Verb:** RUN-THE-TRACT (per-organ skills, not a glow-chase).

## Why the redesign (the critique it answers)
The old game reduced to "look at the bottom, when a button goes yellow tap it, rightmost first." Every
organ played identically. This version gives each organ a **real, distinct action** and layers three
alarm events on top, so the tract is a pipeline you actively *operate*, not five lanes you drain.

## The tract (the sequence you are learning)
Food (a *bolus*) travels left → right through five organs, each with its own action:

| # | Organ | Action | What the organ does | The skill |
|---|-------|--------|---------------------|-----------|
| 0 | MOUTH | **CHEW** / **SPIT** | Mechanical breakdown (teeth, saliva). | Chew tough food **1–3 taps**; **SPIT** bad food. |
| 1 | ESOPHAGUS | **SWALLOW** | Peristalsis pushes the bolus down. | A swallow can trigger a **CHOKE**. |
| 2 | STOMACH | **CHURN** | Acid + muscle → chyme. | Churn cycles build toward a **FLUSH**. |
| 3 | SMALL INTESTINE | **NUTRIENTS** | ~90% of nutrient absorption. | The big points. |
| 4 | LARGE INTESTINE | **WATER** | Reabsorb water; the rest is expelled. | WATER also **douses spice** and **washes down a choke**. |

## Core loop
1. Food enters at the MOUTH on a timer and **ripens** (a ring sweeps). When ripe it **glows gold**.
2. Give each organ the action it needs; the bolus advances and you score. **Absorption pays the most.**
3. One bolus per organ — if the next organ is full it can't move (`FULL`); **clear the FRONT first**.

## The seven mechanics

### 1. Ingress visuals (the pipeline reads)
When a bolus crosses into an organ it **squeezes through the boundary** (squash), the destination
**column lights up**, and the **organ icon reacts** (pops). The tract is a moving pipeline, not static
lanes.

### 2. Bad food — SPIT or SUFFER
Some morsels are **bad** (a sickly green-grey tell + queasy wobble). At the MOUTH a **SPIT** tab appears
under any morsel there:
- **Bad + SPIT** → `SPAT OUT!` **+5**, streak kept.
- **Bad + CHEW/advance** → you swallow it: `SICK!` **−8**, a **sick state** slows the whole tract (~2.6s),
  streak breaks.
- **Good + SPIT** → `WASTED` **−3**, streak breaks (don't spit good food).
The tell gets **more subtle as difficulty rises** (bad-food chance ramps **10% → 24%**).

### 3. Chew depth (1–3 taps)
Each morsel needs **1, 2, or 3 CHEW taps** by toughness, shown as **pips on the morsel** that deplete.
Chews have a short rhythm cooldown (no machine-gunning). Only the final chew advances it.

### 4. Choking event (swallow risk)
Randomly a SWALLOW starts a **CHOKE** emergency — the tract dims, a big red alarm button pulses:
**MASH ~10× fast** to dislodge (progress **decays** if you stop), then **SIP WATER** (tap the WATER
button) to wash it down. Clearing it pays **+12**. Choke chance ramps **5% → 16%** per swallow.
(Button-mash is the mechanic on every platform — no motion sensors required.)

### 5. Spicy event (WATER now)
**Spicy** morsels (chili-red tell + flame flicker) demand **WATER immediately** once chewed (they hit the
tongue). While burning, **points drain and the drain escalates** — the screen edges glow hot. Tap
**WATER** to douse (**+6** for a fast douse). Spicy chance ramps **6% → 18%**.

### 6. Flush handle (relief valve)
Every **5 churn cycles** a **flush handle** appears at the right edge. **Drag it DOWN** to flush the
tract: every bolus on board is cleared for **+6 each** plus a burst. A payoff for a heavy, well-run meal.

### 7. Header spacing
The organ band is stacked and centered (icon → name → action) with breathing room between columns so
labels never collide with each other or the tube.

## Scoring
- CHEW (final): +4 · SWALLOW: +4 · CHURN: +6 · **NUTRIENTS: +16** · **WATER: +10**
- Fully processed (exits large intestine): **+8** (`PROCESSED +N`).
- **Streak bonus:** every correct action adds `+floor(min(streak,10)/2)`. Any mis-action resets streak.
- Event bonuses: SPIT bad +5 · douse spice +6 · clear choke +12 · flush +6/bolus.
- Penalties (clamped at 0): swallow bad −8 · waste good −3 · burn drain over time.
- `scoreUnit`: "processed".

## How to win
Most food processed + nutrients/water absorbed when time runs out — while spitting the bad, surviving
chokes, dousing spice, and flushing a full tract.

## Acceleration (difficulty ramp)
- Intake **2.4 s → 1.0 s**; ripen **0.85 s → 0.5 s** (up to five boluses juggled at once).
- Bad **10→24%**, spicy **6→18%**, choke **5→16%**; bad-food tell grows subtler; chews skew toward 2–3.

## Spec (registry — orchestrator owns)
- `durationSeconds`: 55 · `humanMax`: 700 · `starThresholds`: [240, 440, 640]
- `accent`: `Color(0xFFE0734B)` · `icon`: `Icons.lunch_dining` · `enabled`: true

## Session / resume
Built to **MiniGameSession**: gates on `session.isRunning`, reports via `session.addScore` /
`session.noteStreak`. Host owns clock, countdown, HUD, results. All events (choke/spicy/flush) live
**inside the play area** and clear when the round ends — a run can close and a fresh one re-enter cleanly.
`autoPilot` (ATTRACT) chews fully, spits bad food, mashes through chokes, douses spice, and flushes.

## Dependency rule
Imports only: `flutter`, `dart:math`, `../../mini_game.dart`, `../../fx.dart`,
`../../../theme/potatuhs.dart`. No other game's code. One Ticker → one CustomPainter. No motion sensors.
