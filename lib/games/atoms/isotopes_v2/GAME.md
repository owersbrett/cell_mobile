# Isotopes v2 — Manual (M)

> UX-passed alternative to `isotopes`. Same lesson, dialed-up fun. Ships as a
> sibling spec (`isotopes_v2`) so both are A/B-comparable in-app.

## One-liner
Build the named nuclide by **dialing PROTONS and NEUTRONS** with coarse + fine
controls, then **LOCK IT IN** before its time bar empties — over and over, faster
and faster, to a final-10s ×2 surge.

## Scale
`BioScale.atoms` · scoreUnit: `nuclides` · 50s.

## Rules
1. A prompt names a target nuclide. It is phrased four ways, getting terser as
   you level up: explicit counts (`6 PROTONS · 8 NEUTRONS`) → mass name
   (`CARBON-14`) → neutron count (`OXYGEN · 10 neutrons`) → raw notation (`¹⁴C`).
2. **PROTONS set the element** (atomic number Z). **NEUTRONS set the isotope**;
   mass `A = protons + neutrons`. Both axes have **−coarse / −1 / +1 / +coarse**
   buttons (protons ±5, neutrons ±10) — reach any value in a few taps.
3. The build is **not reset** between prompts — you dial onward from where you
   are, so planning the cheapest path is part of the skill.
4. Match the **ELEMENT** pill (Z) and the **ISOTOPE** pill (N), then **LOCK IT
   IN**. The live `Z / N / A` readout updates as you dial.
5. Each prompt has a shrinking **time bar**. Lock before it empties for a speed
   bonus; let it empty and the prompt is **skipped** (streak breaks, no points
   lost) and a fresh one feeds in.
6. The time bar **tightens** as you build more nuclides — the round accelerates.

## How to win
Most nuclides built when time runs out wins. (Pass-and-play: same pool, same
ladder, same fixed clock and surge window for everyone; highest score takes the
round.)

## Scoring
- Correct lock: `+10` base **+ up to +12 speed** (scaled by time left on the
  prompt bar).
- **Final 10 seconds = FUSION SURGE ×2** on all points — a shared, readable
  climax.
- Wrong lock: no points, **streak resets**, field flashes.
- Timed-out prompt: no points, streak resets, skip to the next.
- There is **no streak score multiplier** (streak feeds the mastery award only)
  and **no clock extension**, so the standing stays comparable — no runaway
  leader.

## Controls
- **Tap coarse/fine buttons** on each axis (`[−5][−1] Z [+1][+5]`,
  `[−10][−1] N [+1][+10]`). One verb, big targets, no tap-grind.
- **Tap LOCK IT IN** to commit when both pills are green.

## Perf
ONE `Ticker` → ONE `CustomPainter`. The painter renders the entire live field in
a single pass: atmosphere, the prompt panel + time bar, the ELEMENT/ISOTOPE
pills, the live `Z/N/A` readout, the atom (electron shells + golden-spiral
nucleus), the success aura, error flash, particle burst, the surge wash, and the
big lock stamp. Only the bottom control buttons are widgets, and they rebuild on
tap — never per frame. `shouldRepaint => false`; the painter repaints from the
ticker clock.
