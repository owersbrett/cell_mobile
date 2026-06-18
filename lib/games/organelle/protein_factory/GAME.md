# GAME.md — Protein Factory

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **Status: UNBUILT — this is a forward build-spec.**

- **Scale (cell):** organelle
- **Game id:** protein_factory
- **One-line concept:** Manage a living protein assembly line — route mRNA to ribosomes,
  keep the Rough ER studded and fed, sort finished proteins through the Golgi, and stock the
  vacuoles — before the queue collapses.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore — the unsung heroes

> "You know the potato. The farmer plants it, the sun grows it, the chef cooks it. Everyone
> gets a name. Nobody thinks about the ribosomes.
>
> Ribosomes don't get a jersey. They don't get a documentary. They are the smallest workers
> in the smallest room in the smallest structure in the world. And they build every single
> thing. Every enzyme. Every transporter. Every structural fiber. Every defense compound.
> If the ribosome stops, the potato stops. The farmer stops. Everything stops.
>
> This is their game."

The lore spine is: **ribosomes are the unsung heroes of every living thing**, in the same way
the **potato is the unsung staple that quietly feeds the world**. Both do the essential, unglamorous
work. Neither gets the credit. The potato is not the flashy grain; the ribosome is not the
glamorous organelle. And yet both are what everything else depends on.

This parallel is the game's emotional core. Surface it in the intro card and in the ORGANELLE_REVEAL
flare for Ribosomes.

---

## The assembly line (game board)

The game Canvas shows a simplified cross-section of the protein secretion pathway:

```
  [Nucleus]                                  (top center, generates mRNA orders)
       |
  [Rough ER ribbon] ←── Ribosomes stud the ER surface here
       |
  [Golgi stack]          (receives ER vesicles; sorts and modifies)
       |           \
  [Vacuole]    [Plasma Membrane exit]      (storage vs. export destinations)
```

This is not a menu screen — it is the live game board. All five organelles are visibly present
and active simultaneously. The player manages the flow between them.

---

## Rules (canonical)

### The order queue

1. **Protein orders drop from the Nucleus** (top of screen) at regular intervals. Each order is a
   card showing: `protein name` · `destination` (Vacuole or Export) · `complexity level` (1–3).
   Orders stack in a queue at the top. Too many unprocessed orders = queue overflow = game over.
   The queue holds a maximum of 5 orders at a time.

2. **Orders are filled by routing mRNA to a Ribosome.** Tap an order card to activate it, then
   tap an available Ribosome on the Rough ER ribbon to assign the job. The Ribosome begins
   assembling (a progress arc fills; duration = `complexity × 4 seconds`).

3. **Ribosomes need to be on the Rough ER.** Free ribosomes float in the cytoplasm periodically.
   Drag a free ribosome onto the Rough ER ribbon to attach it. Attached ribosomes produce proteins;
   unattached ribosomes can't accept orders. Maximum 4 ribosomes on the ER at once.

4. **Finished proteins become vesicles** that pinch off the Rough ER and drift toward the Golgi
   stack. The player must tap the vesicle to "send" it to the Golgi before it drifts too far
   (the vesicle has a 4 s window).

5. **The Golgi sorts.** Vesicles arrive at the Golgi stack (animation: they flatten into a
   Golgi cisterna). The Golgi then emits a sorted vesicle with a destination label:
   - "VACUOLE" → player swipes vesicle down to the Vacuole.
   - "EXPORT" → player swipes vesicle right to the Plasma Membrane exit.
   - "MODIFY" → vesicle re-enters the Golgi for a second pass (adds 2 s to the delivery timer).

6. **Delivery earns points.** A vesicle that reaches its destination on time = full score. A
   vesicle that is late (delivery timer ran out) = half score. A vesicle dropped (missed) = −10.

7. **The Smooth ER is a parallel lipid lane.** Separate from the protein orders, the Smooth ER
   periodically emits lipid vesicles (no player assignment needed — they generate automatically).
   However, if the Golgi is blocked (too many protein vesicles queued there), lipid vesicles pile
   up on the Smooth ER and slow its output. Managing Golgi throughput indirectly keeps the Smooth
   ER healthy.

8. **Vacuoles fill up.** Each vacuole has a capacity bar. When full, it must be "released" by the
   player (tap to trigger exocytosis animation). A full, unreleased vacuole blocks further storage
   deliveries.

---

## Controls

All gesture-based, Canvas-drawn:
- **Tap** an order card → activates it (highlight).
- **Tap** a Ribosome on the ER → assigns the active order to it.
- **Drag** a free ribosome → attach to the Rough ER ribbon.
- **Tap** a vesicle drifting from the ER → sends it to the Golgi (must tap within the 4 s window).
- **Swipe** a Golgi output vesicle → routes to Vacuole (down) or Export (right).
- **Tap** a full Vacuole → triggers release (clears its capacity bar).

---

## Scoring

| Event | Score |
|---|---|
| Protein delivered to correct destination on time | +20 |
| Protein delivered late | +10 |
| Vesicle missed (drifted out of Golgi without routing) | −10 |
| Queue overflow (6th order arrives before one is processed) | Game over |
| Vacuole correctly released before blocking | +5 |
| Vacuole blocked too long (3 s over capacity) | −8 per second until released |
| Smooth ER lipid throughput maintained (no pile-up) | +2 per 10 s |
| Ribosome combo — 3 proteins completed without any miss | +15 combo bonus |

Target score range for a solid run: 500–900. Score attack — play continues until queue overflow.

---

## Win / end condition

Session ends when the Nucleus order queue overflows (6 unprocessed orders) OR when the host
timer expires (whichever comes first). Final score is tallied. Higher throughput = more orders
processed = more points. The game is a throughput management game — the better you manage the
assembly line, the longer you survive and the higher you score.

---

## Difficulty curve

**Early game (0–30 s):** 2 ribosomes on the ER at start, orders arrive every 8 s, all complexity-1.
**Mid game (30–90 s):** Complexity-2 orders start appearing; spawn rate increases to every 6 s;
free ribosomes become less frequent (harder to staff the ER).
**Late game (90 s+):** Complexity-3 orders appear; spawn rate climbs to every 4 s; "MODIFY"
routing from the Golgi becomes more common (adds back-pressure); Vacuoles fill faster.

Tunable constants control every ramp threshold. See Tunable constants in AGENT.md.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Ribosomes | **The star.** Assigned to orders, assembled on ER, track complexity. The player's primary management target. | ✅ |
| Rough E.R. | The scaffold where ribosomes attach and proteins are assembled. Ribosome attachment is a core mechanic. | ✅ |
| Smooth E.R. | Parallel lipid lane; automatically generates lipid vesicles; back-pressure if Golgi is clogged. | ✅ |
| Golgi Apparatus | Sorting gateway; all vesicles pass through; "MODIFY" adds a second pass; destination routing is a player action. | ✅ |
| Vacuoles | Storage destination; capacity management is a player action; full vacuole blocks the line. | ✅ |

All five blocks in the Protein Assembly group are engaged mechanically, not cosmetically. Each
block's real biological function IS its role in the game:
- Ribosomes make proteins → they are the workers assigned to orders.
- Rough ER is where ribosomes work → attachment is a mechanic.
- Golgi sorts and modifies → sorting IS the player's action at the Golgi.
- Vacuoles store → capacity management IS a player action.
- Smooth ER makes lipids → parallel lipid lane, showing the ER's dual role.

---

## Potato angle

The intro card surfaces the lore explicitly:

> *"Inside every potato cell, right now, ribosomes are assembling the enzymes that make starch.
> Nobody thinks about the ribosomes. The potato doesn't get glamorous press either. Both are
> the quiet workers that make everything else possible. This is their game."*

In-game, the proteins being ordered can be named after real potato proteins:
- **Patatin** — the potato's primary storage protein (abundance: ~40% of tuber protein)
- **Starch Synthase** — the enzyme that adds glucose units to the amylose chain
- **RuBisCO** — the most abundant protein on Earth; drives the Calvin cycle in potato leaves
- **Invertase** — converts sucrose into glucose+fructose in the tuber

Using real protein names in the order cards connects the abstract assembly line to the actual
biochemistry of the potato. Players who see "PATATIN — VACUOLE — COMPLEXITY 2" and successfully
deliver it have, in a real sense, manufactured the potato's dominant storage protein.

The unsung-heroes parallel is revisited in the ORGANELLE_REVEAL flare for Ribosomes (entry #8
in `ORGANELLE_REVEAL.md`): "The ribosomes in potato parenchyma cells are working right now
synthesizing the enzymes that convert glucose into amylose — the chain that is starch."

---

## Session / resume

Persist:
- `score` (running total)
- `elapsed_time`
- `queue_orders` (the list of active order cards, with their assignments and progress)
- `er_ribosomes` (which ribosome slots are occupied and their current job progress)
- `vacuole_capacity` (current fill level of each vacuole)

Ephemeral (do not persist — recreate on resume):
- Vesicles in-flight from ER to Golgi
- Vesicles in-flight from Golgi to destination
- Free floating ribosomes in cytoplasm

On resume: restore the persisted state and spawn fresh free ribosomes if none were attached.
The in-flight vesicles are ephemeral — on resume, any protein whose job was completed but vesicle
was not yet delivered scores automatically at the on-time rate (give the player the benefit of
the doubt on the drop).
