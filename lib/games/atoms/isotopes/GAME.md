# GAME.md — Isotopes

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (atoms):** atoms
- **Game id:** `isotopes`
- **Display name:** Isotopes
- **Duration:** 50 s (host-owned clock)
- **Score unit:** nuclides
- **Verb:** SET / IDENTIFY — a build-a-spec puzzle, not a multiple-choice quiz.
- **One-line concept:** A prompt names a specific nuclide. You dial PROTONS and
  NEUTRONS until your atom matches it, then lock it in.

---

## Lore

Every atom is bookkept by two numbers. The **atomic number Z** (the proton count)
is the atom's identity — Z=6 *is* carbon, always, no exceptions. The **mass
number A** (protons + neutrons) tracks how heavy that particular atom is. Two
atoms of the same element with different neutron counts are **isotopes**:
carbon-12, carbon-13, and carbon-14 are all carbon (Z=6), differing only in
neutrons (6, 7, 8). The player is the builder at the bench, assembling a named
nuclide proton by proton, neutron by neutron.

---

## Core loop

A live atom sits in the middle of the field — a golden-spiral nucleus of red
protons and grey neutrons, ringed by faint neutral-atom electron shells. Two big
steppers sit below it.

1. A **prompt card** asks for a specific nuclide (see prompt kinds below).
2. **+/- PROTONS** changes Z. The live readout's element name/symbol updates the
   instant Z changes — dial up to 6 and it reads CARBON.
3. **+/- NEUTRONS** changes A (= Z + N). The element stays put; only the mass
   number moves — the felt meaning of "isotope".
4. Two status pills on the card confirm each axis independently: **ELEMENT**
   (Z matches) and **ISOTOPE** (N matches). When both are green the atom blooms
   and the **LOCK IT IN** button arms.
5. **LOCK IT IN** while matched → the nuclide is banked, a fresh (harder) prompt
   loads. Lock while wrong → "NOT A MATCH", the streak breaks, no points lost.

There is no fail state and the game never ends itself — the host's 50 s clock
owns the round.

---

## Prompt kinds (acceleration)

Prompts get terser — handing the player less — as nuclides are built:

| Kind | Unlocks at | Example | What's given |
|---|---|---|---|
| `counts` | start | "6 PROTONS · 8 NEUTRONS" | both numbers, explicit |
| `massName` | 2 solves | "CARBON-14" | element + mass number A |
| `neutrons` | 4 solves | "OXYGEN · 10 neutrons" | element + neutron count |
| `symbol` | 7 solves | "¹⁴C" | raw isotope notation only |

The element pool also widens with progress: Z ≤ 8 (the familiar light elements)
→ Z ≤ 14 → Z ≤ 20 → all the way to iron (Z=26). The two newest-unlocked prompt
kinds are weighted heavier so the game keeps reaching for the harder phrasing.

---

## Scoring

| Event | Effect |
|---|---|
| Lock a correct nuclide | +10 base |
| …locked fast | +0…10 speed bonus (full within the first instant, fading to 0 over 7 s) |
| …on a streak | +min(streak, 8) streak bonus |
| Lock while wrong | streak resets, red flash, **no** point loss |

Streak is reported via `session.noteStreak` and surfaces as the results-screen
streak/mastery award. A clean fast streak is the path to a high score.

---

## Win / end condition

Highest score (most nuclides built, weighted by speed and streak) when the 50 s
clock runs out wins. No sudden death — a slow run still finishes and scores.

---

## Session / resume (the S in GAMES)

The host owns clock, countdown, score, and results. The game holds no persistent
state between runs: the first frame the host flips to `playing`, `_onRunStart`
resets the build to Z=1 / N=0, clears streak/solves/particles, and serves a fresh
first prompt. Before the round (intro/countdown) the steppers are disabled and a
calm ready-state prompt is shown; gameplay is fully gated on
`session.isRunning`. A finished run and a re-entered one are indistinguishable
from clean boot.

---

## Potato angle

Potatoes are radiocarbon-datable starch: the carbon a tuber pulls from the air
carries a trace of **carbon-14**, the same isotope the player builds. Same
element, heavier nucleus — the bench where you set protons and neutrons is the
bench where a potato's atoms were sorted long before it hit the soil.
