# GAME.md — pH Balance

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** molecular
- **Game id:** ph_balance
- **One-line concept:** Titrate a beaker to a target pH and hold it steady — acid and
  base drops swing hardest near neutral, where the titration curve is steep.
- **Verb:** TITRATE / BALANCE
- **Role:** solo high-score (host-timed, party-compatible)
- **Six-in-one?** no

---

## Lore (titrate to the target)

A beaker of liquid sits on the bench, its color reading its acidity on a universal
indicator (red = acid, green = neutral, violet = base). Each round the bench calls a
**target pH**. You add drops — **ACID (H⁺)** to push the pH down, **BASE (OH⁻)** to push
it up — until the needle lands inside the target band, then you hold it there until it
locks. The twist is real chemistry: near pH 7 the titration curve is steep, so a single
drop near neutral swings the needle hard and slings it past the equivalence point. Far
from neutral the liquid is "buffered" and barely moves. Learn where the curve is steep
and you stop overshooting.

---

## Rules (canonical — as implemented in `PhBalanceGame`)

1. The beaker has a live **pH** (0–14), shown as a big readout over the liquid and as a
   marker on a 0–14 indicator scale (right edge). The liquid + scale are colored by a
   universal-indicator ramp.
2. A **target pH** is named each round, drawn as a white band on the scale plus a
   `TARGET pH X.X` readout with a color dot up top.
3. **Tap ACID** → pH drops by `dropStrength × steep(pH)`. **Tap BASE** → pH rises by the
   same. `steep(pH)` peaks near pH 7 (gaussian, σ≈1.7), so drops move the needle MUCH more
   near neutral than at the extremes — the titration-curve lesson, in the mechanic.
4. The visible needle **eases** toward the chemical pH (~0.1 s) for smooth motion; the
   land/hold check uses the visible needle.
5. **Land & hold:** while the needle is inside the band (`|pH − target| ≤ tol`) a hold
   meter (green ring around the readout) fills. Hold for `holdNeeded` seconds → the target
   is **hit**: points score, a new target is named, the level climbs. Leaving the band
   bleeds the hold meter back down (it does not hard-reset).
6. **Overshoot / streak break:** once you've closed to within `1.6 × tol`, flinging the
   needle out past `3.5 × tol` counts as an overshoot — the streak resets and a red flash
   fires. (Score is never taken away; only the streak.)
7. **Host owns the clock.** Round length is the host's `durationSeconds` (50 s). The game
   does not end itself; it reports score/streak and the host runs the countdown + results.

---

## Accelerate (difficulty ramp — by targets hit, `level = targetsHit + 1`)

| Facet | Start | Per level | Cap | Effect |
|---|---|---|---|---|
| Tolerance `tol` (±pH) | 0.90 | −0.06 | 0.35 min | Tighter band to hold |
| Hold time `holdNeeded` (s) | 1.25 | −0.04 | 0.75 min | Lock faster |
| Drop strength | 0.090 | +0.012 | 0.200 | Stronger acid/base → faster swings |
| Steepness `steepK` | 1.8 | +0.12 | 3.2 | Curve gets sharper near pH 7 |
| Acid drift (CO₂ creep) | 0 (L<3) | +0.05/s | 0.35/s | Liquid self-acidifies; hold actively |
| Target drift | 0 (L<4) | — | 0.18 pH/s | The goal slowly moves |

Target selection biases toward the **hard near-neutral region (pH 6–8)** more often as the
level climbs (`neutralChance = clamp(0.18 + level·0.06, 0, 0.65)`), and always picks a
target ≥ 1.6 pH from the current value so there's titration work to do.

---

## Controls

Two large bottom buttons: **ACID (H⁺ · pH ▼)** and **BASE (OH⁻ · pH ▲)**. Each tap adds one
drop. No drag, no precision-aim — the skill is *timing and restraint* near the steep zone.
Canvas-drawn play area: beaker with colored liquid + rising bubbles + surface wobble, the
0–14 indicator scale strip with target band + neutral-7 dashed line + current-pH arrow, a
big pH readout with ACIDIC/NEUTRAL/BASIC tag, a green hold ring, LV and STREAK badges, and
`+points` popups. No raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Target hit (land + hold) | `40 + round(centered × 30)`, where `centered = 1 − err/tol` |
| Hold drip (in-band) | +4 / second (fractional-accumulated, no rounding loss) |
| Overshoot | no score change; **streak → 0** |

`scoreUnit`: **balance**. Streak = consecutive targets hit without an overshoot; reported
via `session.noteStreak` and surfaced as the results-screen streak award.

---

## Win / end condition

Highest score when the host clock hits zero. There is no internal fail state — the round is
purely time-boxed by the host. `howToWin`: hit the most targets before time runs out.

---

## Educational blocks engaged (molecular scale)

- **Water ✅** — pH 7 is the neutral point of pure water; the whole game orbits the
  neutralization point where H⁺ and OH⁻ balance. The dashed pH-7 line is literally water's
  neutrality drawn on the scale.
- **Air Content ⚠️** — the CO₂-creep drift (acidifying the liquid at higher levels) models
  carbonic-acid formation: dissolved CO₂ lowers pH. That's the same chemistry that
  acidifies rainwater and soil.
- **Carbon ⚠️** — indirectly, via the CO₂/carbonic-acid drift.
- **Solanine ⚠️ (potato angle)** — acid/base chemistry is the bridge to why potato
  storage pH and soil pH matter (see Potato angle).

The core teaching is **the acid–base / pH / neutralization concept itself**, which is a
named molecular-scale idea: H⁺ vs OH⁻, the 0–14 logarithmic scale, indicators, and the
steep equivalence point of a titration.

---

## Potato angle

Soil pH decides whether a potato thrives: spuds like slightly acidic ground (~pH 5–6), and
growers literally titrate their fields with lime (a base) to raise pH or sulfur (acidifying)
to lower it. Scab disease is suppressed in acidic soil; over-liming invites it. The beaker
is the field, the drops are the amendments, and holding the target band is the grower
keeping the soil in the potato's happy zone. Storage water pH also governs how cut potatoes
brown. The titration you're doing IS potato agronomy at bench scale.

---

## Session / resume (the S in GAMES)

Fully host-driven via `MiniGameSession`. A run starts when `session.isRunning` flips true
(the game arms its first target on that edge, resetting pH to 7.0, streak and targets to 0),
scores through `session.addScore`, reports the streak through `session.noteStreak`, and ends
when the host countdown finishes. Closing the run and entering a fresh one re-arms cleanly —
no internal clock, no leftover state. This satisfies the session re-entry test.

---

## Implementation

- `lib/games/molecular/ph_balance/ph_balance_game.dart` → `PhBalanceGame`.
- One `Ticker` → one `CustomPainter` (`_PhPainter`); taps mutate fields without `setState`
  (the next frame paints them). Imports only `flutter`, `../../mini_game.dart`, and
  `../../../theme/potatuhs.dart` — self-contained per the extraction recipe.
