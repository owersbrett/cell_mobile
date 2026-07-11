# GAME.md — Powerhouse

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **Status: BUILT — `powerhouse_game.dart`, `class PowerhouseGame`.**

- **Scale (cell):** organelle
- **Game id:** powerhouse
- **One-line concept:** Run a mitochondrion through the three real stages of cellular respiration —
  and each stage is its OWN mechanic, not the same tap. SPLIT glucose (glycolysis), CYCLE the ring
  (Krebs), then PUMP protons and RELEASE the ATP-synthase rotor (electron transport). Every full pass
  mints ATP; the game speeds up and tightens every window until a perfect run is humanly impossible.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

The mitochondrion is the cell's power plant. It takes the sugar the cell eats (glucose) and the
oxygen it breathes and, through a three-stage chemical relay, charges up ATP — the rechargeable
battery that powers everything the cell does. Those three stages are genuinely different chemistry,
so the game makes them genuinely different to play: glycolysis is a clean SPLIT, the Krebs cycle is
a turning LOOP you feed at the right beats, and electron transport is a proton GRADIENT you build and
then cash out on a spinning rotor — the real ATP synthase. You run that plant for ~60 seconds.

---

## Rules (canonical)

The three stages LOOP. One full pass (glycolysis → Krebs → electron transport) is one respiration
cycle. Each stage is a distinct move:

### 1. GLYCOLYSIS — the split (cytoplasm)
- A 6-carbon glucose molecule slides back and forth across a **cut line** at the centre.
- **Tap** when the molecule is inside the acceptance window at the line to cleave it into two
  3-carbon pyruvates. The more centred the cut, the bigger the reward (up to +4, the NADH bonus).
- Miss the window → "OFF-CENTRE", small shake, the glucose keeps sliding; tap again.
- **Escalation:** the slide speeds up and the acceptance window shrinks as the run goes on.

### 2. KREBS / CITRIC ACID CYCLE — the cycle (matrix)
- A marker sweeps around a **rotating ring**. Lit **gates** sit around the loop — each is a point
  where **CO₂ leaves and NADH is captured**.
- **Tap** as the marker passes each un-hit gate (within an angular tolerance). Hit every gate in the
  loop to complete the turn (+3 each).
- Miss (tap with no gate under the marker) → "MISSED GATE", small shake.
- **Escalation:** the ring spins faster, the number of gates grows (3 → 5), and the hit tolerance
  narrows as the run goes on.

### 3. ELECTRON TRANSPORT — pump & release (inner membrane / cristae)
- Two **proton pumps** sit left and right. **Alternate-tap** them (left, right, left, …) to build
  the H⁺ gradient (6 pumps to charge). Tapping the wrong side = "ALTERNATE PUMPS", no progress.
- Once charged, the **ATP-synthase rotor** spins. **Tap to release** when the rotor blade is in the
  **green zone** at the top. Yield scales with rotor precision AND how full the gradient still is.
- The gradient **leaks** while you line up the release — wait too long and it drains to zero
  ("GRADIENT LOST"), dropping you back to charging.
- **Escalation:** the rotor spins faster, the green zone shrinks, and the gradient leaks faster as
  the run goes on. This is the climax stage — the biggest single ATP payoff (~12–32).

Completing electron transport finishes the respiration cycle and loops back to glycolysis.

---

## Controls

- **Single tap anywhere** — the meaning is set by the current stage:
  - Glycolysis: cleave the glucose at the line.
  - Krebs: hit the marker through a gate.
  - Electron transport: tap LEFT/RIGHT half to work the two pumps; tap to release the rotor.

All visuals are canvas-drawn (`CustomPainter`): the double-membrane mitochondrion housing, the
sliding carbon chain, the turning Krebs ring with pulsing gates, the two proton pumps + spinning
ATP-synthase rotor with its green release zone, plus particle bursts and floating score pops.

### Legibility (how the player always knows what to do)

- **Always-visible instruction line** — a pill under the phase title tells the player the literal
  action for the current stage/sub-state, updating on every transition:
  glycolysis → *"TAP when the green glucose is on the CENTER line"*;
  Krebs → *"TAP as the white marker crosses each lit GATE"*;
  ETC charging → *"TAP LEFT then RIGHT — alternate the two pumps"* (the two pumps are labelled
  LEFT/RIGHT on the field); ETC releasing → *"TAP when the spinning blade is in the GREEN zone"*.
- **ATP goal (the "rush to gather ATP" framing)** — a big top-right **ATP** tally + a filling
  **goal bar** (`_atpGoal`, default 120). It ticks up on every score and pays a one-time
  *"ATP GOAL!"* flourish when reached. Purely motivational: it never ends or gates the run
  (the host clock still owns the length) — it just makes the player feel the race to stack ATP.
- **Intro / legend** — the three legend cards each teach exactly one input (split / cycle /
  pump+release) with the same components the live game draws, opening on "RUSH TO STACK ATP".

---

## Scoring

| Event | Score |
|---|---|
| Glycolysis split (near-perfect) | +2 … +4 ATP (NADH bonus for a centred cut) |
| Krebs gate hit | +3 each (all gates = one full turn) |
| Electron transport release (in-zone) | ~+12 … +32 ATP (rotor precision × gradient fullness) |
| Any miss (off-centre / missed gate / wrong pump / gradient lost) | 0 + brief shake, no cycle progress |

Score unit: **ATP**. The electron-transport release is the dominant payoff, exactly as in the real
energy economy — most ATP is made at the chain.

---

## Win / end condition

Timed score attack. Duration is owned by the host (`session.spec.durationSeconds`, 60s). Most ATP
produced when time runs out wins.

---

## Difficulty curve

A single ramp `f = runElapsed / duration` (0→1) tightens every stage together:

- **Glycolysis:** slide speed 0.9 → 2.4 half-sweeps/sec; window 0.20 → 0.075.
- **Krebs:** spin 1.05 → 2.6 turns/sec; gates 3 → 5; hit arc shrinks toward 0.6×.
- **Electron transport:** rotor 1.1 → 2.9 turns/sec; green zone 0.9 → 0.42 rad; leak 0.12 → 0.5/sec.

Early cycles are forgiving; late cycles demand tight timing on three different inputs — a perfect run
becomes humanly impossible, so scores cluster at peak skill (the studio gameplay law).

Key tunables (in `powerhouse_game.dart`): `_glySlideStart/End`, `_glyWindowStart/End`,
`_krebsSpinStart/End`, `_krebsGatesStart/End`, `_krebsHitArc`, `_etcPumpsNeeded`,
`_etcRotorStart/End`, `_etcZoneStart/End`, `_etcLeakStart/End`.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Cellular respiration (three stages) | Each stage is a SEPARATE mechanic you physically perform | ✅ |
| Glycolysis: C₆ → 2 × C₃ | The split IS the move; the carbon chain visibly halves | ✅ |
| Krebs cycle releases CO₂ + NADH | The ring's gates are the CO₂/NADH release points, once per turn | ✅ |
| Electron transport = proton gradient + ATP synthase | You pump H⁺ across the membrane and spin the real rotor | ✅ |
| Oxygen / where most ATP is made | Facts + the electron-transport payoff being the largest | ✅ |
| Mitochondrion structure | Double membrane housing is drawn; stages run inside the matrix | ⚠️ (visual) |

---

## Potato angle

A potato cell respires just like any other — it burns the sugar broken down from its own stored
starch to power growth. The same glycolysis → Krebs → electron-transport relay this game models is
what lets a seed potato sprout in the dark, spending its starch reserves before it can photosynthesise.

---

## Session / resume

The host owns the clock and the close/re-enter cycle (the S in GAMES). On a fresh run the game resets
its own state (`_resetRun`): back to glycolysis, cycle 0, cleared particles. A previous run leaves no
residue — close the results screen, start again, clean board.

---

## Implementation notes

**Canvas-only. No raster assets.** One `AnimationController` ticker drives one `_PowerhousePainter`;
game state mutates every frame WITHOUT setState (canvas repaints off the ticker) — all continuous
motion (slide, ring spin, rotor spin, gradient leak) lives in `_advancePhase`, not in widget
rebuilds; the widget tree (fact banner) rebuilds at a throttled ~15fps. Particles capped at 60, pops
at 5. All paint paths guard against non-finite metrics. Imports limited to `mini_game.dart`, `fx.dart`,
`theme/potatuhs.dart`, and Flutter — self-contained, depends on no other game. ATTRACT autopilot
(`_autoStep`) plays all three stages competently for OBS b-roll.

**Perf (stutter fix, 2026-07-08):** the earlier stutter came from building a fresh `TextPainter` +
`.layout()` for every HUD/label string on every 60fps frame (phase title, instruction line,
cycle/stage, ATP tally, per-stage labels, pump "TAP"s — ~8 layouts/frame). All static/rarely-changing
canvas text now routes through a per-painter `_TextCache` that lays each glyph run out once and reuses
it; only the alpha-animated flash message is drawn uncached. dt is the real elapsed ticker delta
(never a fixed `1/60`). Result: smooth 60fps on the canvas, no per-frame text-shaping churn.
