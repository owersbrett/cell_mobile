# Homeostasis v2 — Manual (M)

**Scale:** Organism · **Verb:** MULTI-BALANCE (juggle several gauges at once)

## Premise
You are a body's autonomic control. Internal variables each drift on their own,
and your job is to keep **every one** inside its safe band at the same time. When
a gauge wanders, trigger the corrective response that pushes it back toward the
set point — the body counteracting its own deviation (negative feedback).

## The systems (wake in one at a time)
| System | Too HIGH → tap | Too LOW → tap |
|--------|----------------|---------------|
| **TEMP** *(live from start)* | SWEAT (cool) | SHIVER (warm) |
| **WATER** *(wakes ~16%)* | PEE (excrete) | DRINK (rehydrate) |
| **SUGAR** *(wakes ~34%)* | INSULIN (lower) | GLUCAGON (raise) |
| **O₂** *(wakes ~55%)* | EXHALE | BREATHE |

The round **opens with one big, centered gauge** and a "hold it in the green"
beat. As each new system comes online, the live gauges spread to fill the width —
legibility builds instead of dumping a full cockpit on you at second one.

## The whole-screen read
A **health vignette** + a **vital-sign pulse** tell you how the whole body is
doing at a glance: calm green when balanced, reddening and **beating faster** as
systems slip. The status word reads **STABLE / DRIFTING / CRITICAL**. This is the
glanceable outcome — the gauges are the controls.

## Rules
- Tap **▼ (lower)** or **▲ (raise)** under a gauge to nudge it toward its band.
- A gauge in the green band quietly earns points every second.
- Pulling a gauge back **into** its band scores a **+25 recovery**.
- When **all** active systems are in-band at once, you earn a balance bonus and
  build a streak (one rung per whole second held).
- **Don't slam.** Over-correcting — driving the needle through the set point and
  out the far band — is a **WHIPLASH**: it docks points and breaks your streak.
  Negative feedback nudges; it never overshoots.
- **Shocks** (EXERCISE, COLD SNAP, BIG MEAL, DEHYDRATION, THIN AIR…) shove one or
  more gauges suddenly — react fast.

## How to win
Highest **balance** score when the timer ends. Score = time every system spends
in-band + every recovery (minus any whiplash penalties).

## Acceleration & climax
Over the round drifts speed up, the safe bands **narrow**, systems wake in, and
hints fade. The final **10 seconds** are a CRITICAL surge: shocks come faster and
bigger and the all-systems-in-band bonus multiplies — holding everything green at
the end is worth the most.

## Tuning
See the `_k…` feel constants at the top of `homeostasis_v2_game.dart`
(band widths, correction step, drip/recovery/whiplash points, wake fractions,
climax window/multiplier).
