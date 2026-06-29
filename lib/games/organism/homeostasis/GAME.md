# Homeostasis — Manual (M)

**Scale:** Organism · **Verb:** MULTI-BALANCE (juggle several gauges at once)

## Premise
You are a body's autonomic control. Several internal conditions each drift on
their own, and your job is to keep **every one** inside its safe band at the
same time. When a gauge wanders, trigger the corrective response that pushes it
back toward the set point — the body counteracting its own deviation.

## The systems
| System | Too HIGH → tap | Too LOW → tap |
|--------|----------------|---------------|
| **TEMP** | SWEAT (cool) | SHIVER (warm) |
| **WATER** | PEE (excrete) | DRINK (rehydrate) |
| **SUGAR** | INSULIN (lower) | GLUCAGON (raise) |
| **O₂** *(wakes up mid-round)* | EXHALE | BREATHE |

Each gauge is a vertical bar. The green stripe is the **safe band**; the line
through it is the **set point**. The needle is the current value; a small arrow
shows which way it is drifting.

## Rules
- Tap **▼ (lower)** or **▲ (raise)** under a gauge to nudge it.
- A gauge in the green band quietly earns points every second.
- When **all** active systems are in-band at once, you earn a balance bonus and
  build a streak (one rung per whole second held).
- Pulling a gauge back **into** its band scores a **+25 recovery**.
- **Shocks** (EXERCISE, COLD SNAP, BIG MEAL, DEHYDRATION, THIN AIR…) shove one
  or more gauges suddenly — react fast.

## How to win
Highest **balance** score when the timer ends. Score = time every system spends
in-band + every recovery.

## Acceleration
Over the round: drifts get faster and larger, the safe bands **narrow**, shocks
hit more often, and a **4th system (O₂)** comes online. Early hints (a glowing
corrective button) fade out as you speed up.

## Tuning
See the `_k…` feel constants at the top of `homeostasis_game.dart`
(band widths, correction step, drip/recovery points, O₂ wake fraction).
