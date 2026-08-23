# GAME.md — Circulate v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> **Status: BUILT — `circulate_v2_game.dart`, `class CirculateV2Game`.**
> The breath-and-beat rework of `circulate`: you run the whole gas cycle —
> **breathe O₂ in, vent CO₂ out, and beat the heart to actually move the blood** —
> while oxygen-starved organs keep coming online and demanding delivery.

- **Scale (organ system):** organSystem
- **Game id:** circulate_v2
- **One-line concept:** The body doesn't run itself. You **HOLD INHALE** to draw
  O₂ into the reserve, **HOLD EXHALE** to vent the CO₂ that keeps building, tap
  the oxygen-starved organs to **prime** them, and **double-tap the heart —
  lub-dub —** to pump the primed, oxygenated blood out to the body. Breathing
  loads and cleans the blood; only the heartbeat circulates it.
- **Role:** score attack (host owns clock / opponents / standings)
- **Six-in-one?** no

---

## Lore

A body is three jobs braided together. You **inhale** to load oxygen into the
blood. You **exhale** to expel the carbon dioxide the cells hand back — neglect
it and CO₂ builds into an acid pressure that stresses every organ. And you
**beat the heart** — the lub-dub — because breathing alone moves no blood at all;
the heart is the pump. Between breaths and beats, organs across the body burn
through their oxygen and flash for more. You are the body's dispatcher on all
three axes at once, and the demand only climbs.

---

## Rules (canonical)

1. **The O₂ reserve is countable.** The heart holds up to **5 O₂ charges**, a row
   of red pips above it ("O₂ RESERVE 3/5"), the active pip filling as you inhale.
   This is the hero read — the whole coupling is visible at a glance.
2. **INHALE (hold) — load O₂.** Hold the **INHALE** button (bottom-left) to draw
   oxygen in; the reserve fills while held. The lungs expand and pull O₂ motes in.
   You cannot deliver oxygen you have not breathed in.
3. **EXHALE (hold) — vent CO₂.** Cells return **carbon dioxide**, shown as a
   rising **CO₂ pressure bar** by the lungs. Hold the **EXHALE** button
   (bottom-right) to expel it. Let it max out and the body goes into acidosis:
   organs drain **faster** and the alarm flashes. Real physiology — exhalation is
   how CO₂ leaves the body.
4. **PRIME (tap a low organ).** Organs continuously come online oxygen-starved and
   drain over time; below 34% they flash "LOW O₂", at 0 they're "STARVED".
   **Tap** one to **prime** it — arm it for the next pump (a bright arterial line
   lights to it). Priming spends no charge yet; the pump does. *(This continuous
   spawn-and-tap loop is unchanged — it is the core of the game.)*
5. **HEARTBEAT (double-tap the heart — lub-dub).** Breathing alone doesn't move
   blood. **Double-tap the heart node** (or the **HEARTBEAT** button, centre) in
   a quick **lub-dub** rhythm to **pump**: every primed organ gets a red arterial
   pulse of oxygenated blood, spending **1 charge each** (neediest first). The
   lub-dub lands a two-ring pump burst and a heart kick. No beat, no delivery.
6. **You can't pump empty.** If a primed organ has no charge to send, the pump is
   blocked for it and the reserve flashes "HOLD INHALE". Because the count is
   always visible, this is a rule you learn by anticipation, not by surprise.
7. **The heart's colour teaches oxygenation.** The heart lerps **blue → red**
   with the reserve: pump charges out and it darkens (deoxygenated), inhale and
   it reddens (oxygenated).
8. **No early end (fairness).** A starved organ never ends the run — it can be
   revived by a pumped delivery, the run always rides the full clock, and
   standings stay comparable across players.
9. **CODE RED climax.** In the final **12 seconds** demand spikes, organs crash
   faster, CO₂ builds faster, and **every delivery scores ×2**. The host owns the
   shared clock, so the surge hits all players equally — stakes up, no runaway.
10. **Score = oxygen delivered well.** Highest wins.

---

## Controls

Three actions live in a **bottom control row**, plus taps on the play field:

- **INHALE — hold** (bottom-left): fill the O₂ reserve while held.
- **HEARTBEAT — double-tap** (centre) OR **double-tap the heart node**: lub-dub
  to pump the primed deliveries out.
- **EXHALE — hold** (bottom-right): vent the CO₂ pressure while held.
- **Tap a low organ** (play field): prime it for the next pump. Lower organ =
  more points on delivery (triage).

All visuals are canvas-drawn (`CustomPainter`): a pumping heart with the charge
magazine and lub-dub rings, breathing lungs, a CO₂ pressure bar, arteries to each
organ (bright when primed), organ O₂ ring gauges, travelling red blood, a CODE
RED banner, particles and floating "+N" pops. The bottom buttons are lightweight
widgets; all of their animated feedback (lung expansion, CO₂ venting, the
lub-dub) plays on the canvas.

---

## Scoring

| Event | Score |
|---|---|
| Pump to a near-empty organ | up to +20 (×2 in CODE RED = +40) |
| Pump to a healthy organ | +5 (×2 in CODE RED = +10) |
| Pump a primed organ with 0 charges | blocked, 0 — reserve flashes |
| Inhale / exhale | 0 (they enable and protect delivery) |
| Organ starves | streak reset (run continues) |

Score unit: **deliveries**. The rescue bonus is `5 + (1 − o2)·15`, so triaging
the lowest organ earns the most — without lapping the field (modest spread).

---

## Win / end condition

Timed score attack. Duration owned by the host
(`session.spec.durationSeconds`, ~55s). Most oxygen delivered when time runs out
wins. No sudden death — a starve never ends the run.

---

## Difficulty curve

- **Demand:** 1.0 → 2.0 across the run, **+0.6** during CODE RED.
- **Organ count:** 3, adding one every ~11s up to 6.
- **Drain:** organ-specific (0.052–0.075/sec), **×1.6** during CODE RED, and
  further boosted while CO₂ pressure is high (acidosis).
- **CO₂:** accrues continuously plus a kick per organ pumped; **×1.5** in CODE
  RED. Must be vented or it chokes the body.
- Early: one inhale + one lub-dub covers several organs comfortably, CO₂ is slow.
  Late: more organs, higher demand, faster CO₂, and the surge force a tight
  inhale → prime → lub-dub → exhale cycle right as the ×2 makes each rescue most
  valuable.

Key tunables (in `circulate_v2_game.dart`): `_chargeCap`=5, `_deliverAmt`=0.62,
`_pulseSpeed`=2.5, `_lowO2`=0.34, `_inhaleRate`=3.2, `_exhaleRate`=0.85,
`_co2BaseRate`=0.05, `_co2PerDeliver`=0.06, `_co2Warn`=0.6, `_beatWindow`=0.5s,
`_addOrganEvery`=11, `_demandStart`=1.0 / `_demandEnd`=2.0, `_surgeWindow`=12s,
`_surgeMult`=2, `_surgeDrainMult`=1.6, `_surgeDemandKick`=0.6, `_surgeCo2Mult`=1.5.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Gas exchange (O₂ in, CO₂ out) | INHALE loads O₂; EXHALE vents CO₂ — the two directions of breathing, as two held controls | ✅ |
| Why we exhale (CO₂ removal) | CO₂ visibly accumulates as pressure; unvented, it drives acidosis stress that speeds organ drain | ✅ |
| The cardiac cycle / lub-dub | The double-tap IS the heartbeat; breathing alone moves no blood — only the beat pumps it | ✅ |
| Systemic vs pulmonary circulation | Lungs load the blood (pulmonary); the beat pumps it to the organs (systemic) | ✅ |
| Oxygenated vs deoxygenated blood | The heart lerps red↔blue with the reserve; arterial pulses are red | ✅ |
| Oxygen demand & organ failure | Organs drain and starve without delivery; brain/muscle priority is triage | ✅ |

---

## Potato angle

A potato has no heart and no lungs, but it still runs coupled transport and gas
exchange: water and minerals rise through the **xylem**, sugars descend through
the **phloem**, and its cells respire — taking in O₂, giving off CO₂ — through
tiny pores called **lenticels** and **stomata**. Same principle: a living
body — spud or human — keeps working only while its transport and gas loops keep
turning.

---

## Session / resume

The host owns the clock and the close/re-enter cycle (the S in GAMES). On a
fresh run the game resets its own state (`_resetRun`): reserve full, CO₂ zero, 3
organs, streak 0, cleared pulses/particles, and the in-context teaching prompts
re-arm so the next session re-teaches. A previous run leaves no residue — close
the results screen, start again, clean board.

---

## Implementation notes

**Canvas-only. No raster assets.** ONE `AnimationController` ticker drives ONE
`_CirculateV2Painter`; game state mutates every frame WITHOUT setState (the
canvas repaints off the ticker). The three bottom buttons are lightweight widgets
that only flip a boolean (hold) or feed the lub-dub detector (beat) — their rich
animation lives on the canvas. Input on the play field is honest spatial taps
(organ = prime; heart = beat-tap) through a single `GestureDetector`. In-flight
pulses keep travelling after time-up so a delivery pumped at the buzzer still
lands (fairness). Particles capped at 60, pops at 6. All paint paths guard
against non-finite metrics. Imports limited to `mini_game.dart`, `fx.dart`,
`theme/potatuhs.dart`, and Flutter — self-contained, depends on no other game.

The **node-spawn loop is untouched** from the prior version: organs still come
online oxygen-starved on the same cadence and drain on the same curves — that
loop is the core Brett called out to keep. What changed is the resource engine
around it: recharge-by-tapping-lungs became **HOLD INHALE**, a **CO₂ / EXHALE**
axis was added, and delivery now fires through the **lub-dub heartbeat** instead
of an instant per-organ tap.
