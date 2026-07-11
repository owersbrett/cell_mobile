# Constants — Manual (the **M** in GAMES)

**Scale:** `BioScale.universeAll` · **Verb:** HOLD-REALITY-IN-BAND · **id:** `constants`

## Premise
You are at the control desk of reality. Four of the universe's fundamental
constants each have a narrow **habitable band** — but there are **no sliders**.
Every constant is tuned by a **bespoke physical gesture** that evokes its actual
physics. Keep them all in band at once and a universe that can form stars, atoms
and chemistry stays **life-permitting**. Let any one slip out and the cosmos
fails in a specific, physical way.

## The four gestures
Each control **fights back**, so you must keep re-applying the gesture — a tap
alone never holds a constant in band.

| Constant | Gesture | Physics feel | Out of band → |
|----------|---------|--------------|---------------|
| **G — Gravity** | **PULL DOWN** on the heavy handle | it floats back **up**; keep hauling it to the mid-depth band | too deep → stars **collapse**; too shallow → **no galaxies** |
| **S — Strong force** | **PINCH** the two nucleon halves toward the centre | they **spring apart**; hold them bound | too tight → **no hydrogen**; too loose → **no nuclei** |
| **Λ — Cosmological Λ** | **DRAG** the expansion orb onto the sweet-spot ring | the orb **wanders** on its own across the 2-D field | off the sweet spot → the cosmos **rips apart / recollapses** |
| **μ — Mass ratio** | **STRETCH** the breathing atom shell to the target ring | the shell is **alive**, inflating and deflating; resize it to hold | too big → **no stable atoms**; too small → **no chemistry** |

Each station shows a small **band meter** under its title (a green band + a
moving marker) so you always know how close that constant is. The panel rim goes
**green** when it is in band.

## The live universe
The **preview** at the top reacts in real time: gravity too strong pulls the
star cluster into a collapse singularity, gravity too weak disperses it, Λ off
the sweet spot flings stars outward, the strong force dimming kills stellar
fusion, and a bad mass ratio reddens the field as chemistry breaks. A banner
names the current failure — that diagnostic IS the teaching.

## Rules
- Keep **every active station** in band → the universe is life-permitting and
  you score continuously.
- The round starts with **G** and **S**. **Λ** comes online at ~30% of the
  round, **μ** at ~62% — so the number of gestures you juggle grows.
- Periodic **shocks** knock one station far out (red flash / red rim). Recover
  it back into band with its gesture to **RECOVER** it for a bonus.
- As time passes the bands **narrow** and the drift **speeds up** — a perfect
  hold becomes humanly impossible.

## How to win
Maximise total score: time spent life-permitting plus shocks recovered. The
longer you keep the whole universe in band without a break, the higher your
**stability streak**.

## Scoring
- **+14 / second** while life-permitting (all active stations in band).
- **+60** each time you recover a shocked station.
- **Streak** = consecutive whole seconds the universe stays life-permitting;
  resets to 0 the instant any station leaves its band. Surfaced as the results
  streak award.

## GAMES rubric
- **G**ame — `constants_game.dart` (`ConstantsGame`), playable, host-driven.
- **A**gent — `AGENT.md`.
- **M**anual — this file.
- **E**ducation — `EDUCATION.md` (fine-tuning of physical constants).
- **S**ession — host owns the clock; a run finishes and a fresh one re-enters
  cleanly (state re-inits on the not-running → running transition).
