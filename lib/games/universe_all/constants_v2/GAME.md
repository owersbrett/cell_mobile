# Constants v2 — Manual (the **M** in GAMES)

**Scale:** `BioScale.universeAll` · **Verb:** TUNE-THE-DIALS · **id:** `constants_v2`

> UX-passed sibling of `constants`. SAME fine-tuning lesson and SAME 4-dial depth
> + accelerating climax — rebuilt input and watchability. Ships as its own spec so
> both are A/B-comparable in-app.

## Premise
You are at the control desk of reality. Up to four of the universe's fundamental
constants sit on dials, each with a narrow **habitable band**. Hold them all in
band and a universe that can form stars, atoms and chemistry stays
**life-permitting**. Let any one drift out and the cosmos fails in a specific,
physical way — named on the banner, shown in the live preview.

## The dials
| Dial | Constant | Out of band → |
|------|----------|---------------|
| **G** | Gravity strength | too strong → stars **collapse**; too weak → **no galaxies** |
| **S** | Strong nuclear force | off → **no nuclei**; too high → **no hydrogen** |
| **Λ** | Cosmological constant | too high → cosmos **rips apart**; too low → **instant recollapse** |
| **μ** | Electron/proton mass ratio | off → **no stable atoms / no chemistry** |

## Controls (v2 — fixed input)
- **Grab a dial and drag.** Touch a dial's row and the knob locks to your finger;
  it then tracks **1:1** from where it was — no teleport-to-finger jump, and the
  drag stays on the dial you started on (no hijacking a neighbour).
- The green zone is the habitable band; the centre tick is the ideal.

## What fights you
- A constant **drift** nudges every dial you are not holding.
- **Surges** — instead of firing instantly, a surge **telegraphs**: a pulsing
  amber ring + a chevron show *which* dial and *which way* it is about to be
  pushed. Pre-position and drag it back to **CATCH** it for a bonus.

## The spectator headline
A full-width **UNIVERSE HEALTH** meter (green → amber → red, with a live %) sits
at the top so anyone watching can read the universe thriving or dying at a glance.

## Rules
- Keep **every active dial** in its green band → life-permitting → continuous score.
- The round starts with 2 dials. **Λ** unlocks at ~30%, **μ** at ~62%.
- As time passes bands **narrow**, drift **speeds up**, and surges **quicken** —
  the last 20% is a **climax crunch** (the health bar pulses).

## How to win
Most time life-permitting (all dials in band) plus surges caught wins. The longer
you hold the whole universe in band without a break, the higher your **streak**.

## Scoring
- **+14 / second** while life-permitting (all active dials in band).
- **+60** each time you catch a surged dial back into its band.
- **Streak** = consecutive whole seconds life-permitting; resets the instant any
  dial leaves its band. Surfaced as the results streak award.

## GAMES rubric
- **G**ame — `constants_v2_game.dart` (`ConstantsV2Game`), playable, host-driven.
- **A**gent — `AGENT.md`.
- **M**anual — this file.
- **E**ducation — `EDUCATION.md` (fine-tuning of physical constants).
- **S**ession — host owns the clock; a run finishes and a fresh one re-enters
  cleanly (state re-inits on the not-running → running edge, `_initRun`).
