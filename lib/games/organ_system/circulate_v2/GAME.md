# GAME.md — Circulate v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> **Status: BUILT — `circulate_v2_game.dart`, `class CirculateV2Game`.**
> UX-refinement-pass alternative to `circulate`. Same two-loop lesson, the
> deliver↔recharge coupling made VISIBLE, fair scoring, an accelerating climax.

- **Scale (organ system):** organSystem
- **Game id:** circulate_v2
- **One-line concept:** The heart holds a COUNTABLE reserve of oxygen charges.
  Tap low organs to DELIVER O₂ (systemic loop, −1 charge each), tap the lungs to
  RECHARGE the reserve (pulmonary loop). You can't deliver oxygen you don't
  have — the countable reserve makes the loop legible before you ever starve.
- **Role:** score attack (host owns clock / opponents / standings)
- **Six-in-one?** no

---

## Lore

Blood runs two coupled loops. In the **systemic** loop the heart pumps
bright-red, oxygen-rich blood out through the arteries to every organ, handing
off its oxygen. The blood comes back blue and spent through the veins — and in
the **pulmonary** loop it's pumped to the lungs, reloads oxygen, and reddens
again. You are the body's dispatcher: route oxygen to the organs that need it,
and you cannot route what you haven't reloaded. Keep both loops turning while
demand climbs.

---

## Rules (canonical)

1. **The reserve is countable.** The heart holds up to **5 O₂ charges**, shown
   as a row of red pips above it ("O₂ RESERVE 3/5"). This is the hero read — the
   whole coupling is visible at a glance.
2. **DELIVER (systemic loop).** Tap an organ to send a red arterial pulse to it.
   It spends **1 charge** (pops "−1" at the heart) and tops the organ's oxygen
   back up. Tapping a *low* organ scores more (triage).
3. **RECHARGE (pulmonary loop).** Tap the **LUNGS** — a big, persistent,
   clearly-labelled refuel node — to send blood out and reload the reserve to
   full. The lungs and the pulmonary vessel **light up and pulse when the
   reserve runs low**, prompting the recharge *before* you run dry.
4. **You can't deliver empty.** With 0 charges, a delivery is blocked, the lungs
   flash "RECHARGE AT THE LUNGS". Because the count is always visible, this is a
   rule you learn by anticipation, not by surprise.
5. **Organs drain.** Each organ burns oxygen continuously; demand climbs across
   the round and more organs come online (3 → 6). Below 34% an organ flashes
   "LOW O₂"; at 0 it's "STARVED".
6. **No early end (fairness).** A starved organ never ends the run — it can be
   revived by a delivery, the run always rides the full clock, and standings
   stay comparable across players.
7. **The heart's colour teaches oxygenation.** The heart lerps **blue → red**
   with the reserve: spend charges and it darkens (deoxygenated), recharge and
   it reddens (oxygenated).
8. **CODE RED climax.** In the final **12 seconds** demand spikes, organs crash
   faster, and **every delivery scores ×2**. The host owns the shared clock, so
   the surge hits all players equally — stakes up, no runaway leader.
9. **Score = oxygen delivered well.** Highest wins.

---

## Controls

- **Tap a low organ** — deliver O₂ to it (−1 charge). Lower organ = more points.
- **Tap the LUNGS** — recharge the reserve to full (one pulmonary cycle at a
  time; the blood has to travel there and back).
- All visuals are canvas-drawn (`CustomPainter`): a pumping heart with the
  charge magazine, a refuel-lit lungs node, arteries to each organ, organ O₂
  ring gauges, travelling red/blue blood, a CODE RED banner, particles and
  floating "+N" / "−1" pops.

---

## Scoring

| Event | Score |
|---|---|
| Deliver to a near-empty organ | up to +20 (×2 in CODE RED = +40) |
| Deliver to a healthy organ | +5 (×2 in CODE RED = +10) |
| Deliver with 0 charges | blocked, 0 — lungs flash |
| Recharge at the lungs | 0 (it enables future deliveries) |
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
- **Drain:** organ-specific (0.052–0.075/sec), **×1.6** during CODE RED.
- Early: one recharge covers several deliveries comfortably. Late: more organs,
  higher demand, and the surge force tight deliver↔recharge cycling right as the
  ×2 makes each rescue most valuable.

Key tunables (in `circulate_v2_game.dart`): `_chargeCap`=5, `_deliverAmt`=0.62,
`_pulseSpeed`=2.5, `_lowO2`=0.34, `_rechargePrompt`=2, `_addOrganEvery`=11,
`_demandStart`=1.0 / `_demandEnd`=2.0, `_surgeWindow`=12s, `_surgeMult`=2,
`_surgeDrainMult`=1.6, `_surgeDemandKick`=0.6.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Systemic vs pulmonary circulation | The two literal loops: heart→arteries→organs (deliver) vs heart→lungs→reload (recharge) | ✅ |
| Oxygen transport / the reserve | The countable charge magazine: blood carries a finite oxygen load that must be reloaded | ✅ |
| Oxygenated vs deoxygenated blood | The heart lerps red↔blue with the reserve; pulses are red out, blue back | ✅ |
| Oxygen demand & organ failure | Organs drain and starve without delivery; the brain/muscle priority is triage | ✅ |
| The lungs as gas-exchange site | The only node that reloads O₂ — the recharge half of the loop | ✅ |

---

## Potato angle

A potato has no heart, but it still moves resources on loops: water and minerals
rise through the **xylem**, sugars made in the leaves travel down through the
**phloem**. Same principle — a body keeps working only while its transport loops
keep turning.

---

## Session / resume

The host owns the clock and the close/re-enter cycle (the S in GAMES). On a
fresh run the game resets its own state (`_resetRun`): reserve full, 3 organs,
streak 0, cleared pulses/particles. A previous run leaves no residue — close the
results screen, start again, clean board.

---

## Implementation notes

**Canvas-only. No raster assets.** ONE `AnimationController` ticker drives ONE
`_CirculateV2Painter`; game state mutates every frame WITHOUT setState (the
canvas repaints off the ticker). Input is honest spatial taps routed through a
single `GestureDetector` (organ = deliver, lungs = recharge — two distinct,
signposted targets). In-flight pulses keep travelling after time-up so a
delivery launched at the buzzer still lands (fairness). Particles capped at 60,
pops at 6. All paint paths guard against non-finite metrics. Imports limited to
`mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and Flutter — self-contained,
depends on no other game.
