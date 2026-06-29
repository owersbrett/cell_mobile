# Constants — Manual (the **M** in GAMES)

**Scale:** `BioScale.universeAll` · **Verb:** TUNE-THE-DIALS · **id:** `constants`

## Premise
You are at the control desk of reality. Four of the universe's fundamental
constants sit on dials, each with a narrow **habitable band**. Set them all in
band and a universe that can form stars, atoms and chemistry stays
**life-permitting**. Let any one drift out and the cosmos fails in a specific,
physical way.

## The dials
| Dial | Constant | Out of band → |
|------|----------|---------------|
| **G** | Gravity strength | too strong → stars **collapse**; too weak → **no galaxies** |
| **S** | Strong nuclear force | off → **no nuclei**; too high → **no hydrogen** |
| **Λ** | Cosmological constant | too high → cosmos **rips apart**; too low → **instant recollapse** |
| **μ** | Electron/proton mass ratio | off → **no stable atoms / no chemistry** |

The live **universe preview** at the top reacts in real time: gravity high pulls
the star cluster into a collapse singularity, gravity low disperses it, Λ high
flings stars outward, the strong force dimming kills stellar fusion, and a bad
mass ratio reddens the field as chemistry breaks. A banner names the current
failure — that diagnostic IS the teaching.

## Controls
- **Drag a dial's knob** left/right to set its value. The green zone is the
  habitable band; the centre tick is the ideal.
- You are fighting two things: a constant **drift** that nudges every dial, and
  periodic **shocks** that knock one dial far out (red flash). Drag a shocked
  dial back into band to **STABILISE** it for a bonus.

## Rules
- Keep **every active dial** inside its green band → the universe is
  life-permitting and you score continuously.
- The round starts with 2 dials. **Λ** unlocks at ~30% of the round, **μ** at
  ~62%.
- As time passes the bands **narrow** and the drift **speeds up**.

## How to win
Maximise total score: time spent life-permitting plus shocks stabilised. The
longer you keep the whole universe in band without a break, the higher your
**stability streak**.

## Scoring
- **+14 / second** while life-permitting (all active dials in band).
- **+60** each time you stabilise a shocked dial.
- **Streak** = consecutive whole seconds the universe stays life-permitting;
  resets to 0 the instant any dial leaves its band. Surfaced as the results
  streak award.

## GAMES rubric
- **G**ame — `constants_game.dart` (`ConstantsGame`), playable, host-driven.
- **A**gent — `AGENT.md`.
- **M**anual — this file.
- **E**ducation — `EDUCATION.md` (fine-tuning of physical constants).
- **S**ession — host owns the clock; a run finishes and a fresh one re-enters
  cleanly (state re-inits on the not-running → running transition).
