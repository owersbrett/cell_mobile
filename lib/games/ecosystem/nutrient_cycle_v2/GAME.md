# GAME.md — Nutrient Cycle v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> The UX-refined alternative to `nutrient_cycle` (see
> `docs/ux_pass/teardowns/nutrient_cycle.md`).

- **Scale (ecosystem):** ecosystem
- **Game id:** `nutrient_cycle_v2`
- **One-line concept:** Route one atom round a ring of reservoirs by valid named
  processes — **matter cycles and is conserved, but the atom's ENERGY leaks out
  every step and only re-enters at the sun-driven process.** Keep it charged,
  bank combos and deliveries, before the cycle stalls.
- **Role:** solo score-attack + pass-and-play party (host owns clock, opponents, standings)
- **Six-in-one?** no

---

## Lore

A single atom of carbon, water or nitrogen never disappears — it just moves
between reservoirs (atmosphere, plant, animal, soil, ocean, microbes…) along
real biogeochemical **processes** (photosynthesis, respiration, fixation,
evaporation, denitrification…). That matter is conserved: it goes round and
round forever. **Energy is the opposite.** It enters the living system only at
the sun-driven step — photosynthesis, evaporation, fixation — and from there it
only ever leaks away as heat. An ecosystem that loses its energy input dies even
though every atom is still present. You are the router holding the cycle alive.

---

## Rules (canonical — as implemented in `NutrientCycleV2Game`)

1. **Tap the next reservoir.** The atom sits in a reservoir; its valid outgoing
   processes brighten and name themselves (the live hint), and reachable nodes
   pulse. Tap a reachable node to slide the atom there. A tap with **no process**
   between the pools is a **DEAD END**.

2. **Matter is conserved, energy leaks (the lesson, lived).** The atom carries an
   **ENERGY** charge (top bar + a glowing aura around the atom). **Every** transfer
   leaks a chunk of it as heat motes that drift up and vanish — energy never
   returns the way it left. The atom itself (the matter) is never consumed.

3. **Recharge only at the sun.** Energy re-enters the system **only** on the
   sun-driven, energy-input process — **photosynthesis** (carbon),
   **evaporation** (water), **fixation** (nitrogen). That edge glows **gold with
   a ☀**; taking it refills the charge (`+0.55`). You must keep routing back
   through the sun or the cycle **STALLS**.

4. **Every transfer matters — the COMBO.** Each clean valid transfer scores
   `+combo` and grows the combo `×1 → ×5` (capped). A **DEAD END** or an
   energy **STALL** wipes the combo back to ×1 — so each tap carries weight and
   sloppy routing is punished.

5. **DEMAND deliveries — a routing decision.** One reservoir is ringed gold and
   labelled **NEEDS {symbol}**; routing the atom there pays a juicy bonus
   (`6 × combo`) and a new demand rolls. This is the shortest-path-under-an-
   energy-budget choice that rewards routing *well*, not just fast.

6. **LOOP closure (preserved).** Bringing the atom all the way back to where the
   loop began pays `LOOP +4 × combo` — the conserved-matter-round-a-closed-loop
   reward kept from the original.

7. **Stall, don't game-over.** Energy `≤ 0` ⇒ **STALLED**: combo resets, energy
   floors to `0.34`, an orange "find the sun" callout flashes. The host clock
   keeps running — fail-and-recover, never a hard stop.

8. **Procedural variety.** Each cycle entry **re-lays-out the ring** (random
   rotation) and **starts the atom on a random reservoir**, and the demand is
   random — so mastery is routing under the energy budget, not memorising three
   fixed spatial maps.

9. **Climax — FINAL BLOOM.** In the last **12 s** the energy leak escalates
   (×1.5), points score **×2**, cycles flip after a single loop instead of two,
   and an alarm vignette pulses. The round ends on a **CYCLE SUSTAINED**
   (charged) or **CYCLE COLLAPSED** flourish.

10. **Session length:** 60 s (`MiniGameSpec.durationSeconds`). The host owns the
    clock, countdown, score HUD, opponents and results. Highest score wins.
