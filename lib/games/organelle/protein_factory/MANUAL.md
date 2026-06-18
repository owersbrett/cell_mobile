# Protein Factory — How to Play

> Player-facing. Anyone reading this should understand the game.
> This is one entry in the Manual and a source file for the deployable Manual app.
> **Status: UNBUILT — this entry is a forward spec. Rules are locked; game is not yet coded.**

**Scale:** Organelle · **Type:** Solo (survive as long as possible) · **Length:** Until queue overflows (~2–5 min)

---

## The goal

Protein orders are dropping in from the Nucleus. Your job is to keep the assembly line moving:
assign ribosomes to jobs, send finished proteins through the Golgi, and deliver them to the right
destination before the queue backs up and the line collapses.

---

## How to play

**The screen shows a living cell, top to bottom:**
- **Nucleus** (top) — generates orders that drop into a queue.
- **Rough ER** (middle ribbon) — where your ribosomes attach and do the work.
- **Smooth ER** (parallel ribbon) — runs a lipid lane on its own; keep the Golgi clear so it doesn't jam.
- **Golgi stack** (below the ER) — sorts every finished protein before it ships out.
- **Vacuole and Export exit** (bottom) — the two destinations for finished goods.

**Step 1 — Accept an order.**
Tap a protein order card at the top of the screen to select it.

**Step 2 — Assign a ribosome.**
Tap one of the ribosomes on the Rough ER to put it to work on that order. The ribosome shows
a progress arc as it assembles the protein. More complex proteins take longer.

**Step 3 — Catch the vesicle.**
When the ribosome finishes, a vesicle pinches off the ER and drifts toward the Golgi. Tap it
within 4 seconds to send it to the Golgi. Miss it and the protein is lost.

**Step 4 — Route the Golgi output.**
The Golgi processes every vesicle and labels it with a destination: VACUOLE or EXPORT (or
occasionally MODIFY, which sends it through the Golgi a second time).
- Swipe the output vesicle **down** to store it in the Vacuole.
- Swipe it **right** to send it out through the Plasma Membrane.

**Step 5 — Keep the Vacuole from filling.**
Each Vacuole has a capacity bar. When it fills up, tap the Vacuole to release its contents
(exocytosis). A full, untapped Vacuole blocks storage deliveries and slows everything down.

**Staffing the ER:**
When you see a free ribosome floating in the cytoplasm, drag it onto the Rough ER ribbon to
attach it. You can have up to 4 ribosomes on the ER at once. More staff = more throughput.

---

## How you score

- **+20** for delivering a protein to the correct destination on time.
- **+10** for a late delivery (still counts, but less).
- **−10** for a missed vesicle.
- **+15 combo bonus** for completing 3 proteins in a row without a miss.
- Game over when 6 unprocessed orders pile up in the queue.

There is no fixed time limit — the game ends when you can no longer keep up. High-score runs
are all about throughput management: keeping the ER staffed, the Golgi clear, and the Vacuole
from blocking.

---

## Tips

- Keep at least 2–3 ribosomes attached to the ER at all times. When you see a free one floating
  past, drag it on before it drifts away — it won't come back often.
- The Golgi is the bottleneck. If vesicles are piling up waiting to be sorted, stop accepting
  new orders for a moment and focus on clearing the Golgi.
- "MODIFY" outputs from the Golgi come back around for a second sort. Don't panic — just route
  them again like a normal vesicle.
- Tap the Vacuole early — don't wait until it's completely full. Releasing it early keeps the
  storage lane open.
- Orders have a complexity number (1, 2, or 3). In the late game, prioritize complexity-1 orders
  to keep the queue from overflowing while longer jobs are running.

---

## What it teaches

How proteins actually get made and delivered inside a living cell — and why ribosomes, for all
their obscurity, are the most important workers in biology. Every enzyme, every transporter, every
structural protein in a potato is built by a ribosome running the same assembly line you're
managing right now.

The proteins in the game's order queue are real potato proteins: Patatin (the tuber's primary
storage protein), Starch Synthase (the enzyme that builds starch chains), and RuBisCO (the
world's most abundant protein, which drives photosynthesis in potato leaves). When you deliver
a Patatin order to the Vacuole, you've built the thing that makes a potato nutritious.

Nobody talks about ribosomes. The potato doesn't get a lot of press either. Both quietly make
everything else possible.
