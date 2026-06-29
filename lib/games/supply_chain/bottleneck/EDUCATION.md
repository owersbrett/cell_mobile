# EDUCATION.md — Bottleneck

> The E in GAMES. Bottleneck teaches **flow, throughput, and the Theory of Constraints** — and it does
> so *in the mechanic*, not in a popup. You learn it by feeling what happens when you boost the wrong
> stage and watch potatoes rot anyway.

---

## The one idea: a chain is only as fast as its slowest stage

A production line is a series of steps, each with its own speed. Intuitively you might think the line's
output is some kind of average of all the steps. **It isn't.** Output is set by the **single slowest
step** — the **bottleneck** (or **constraint**).

- The Farm can harvest 2.7 potatoes/sec, Wash can do 2.2, but if **Process** only handles 1.8/sec, then
  **the whole line ships at most 1.8/sec** — no matter how fast everything else runs.
- Speeding up the Farm just makes potatoes pile up *in front of* Process. They don't ship any faster.
  They just wait — and if they wait too long, they rot.

This is **Eliyahu Goldratt's Theory of Constraints (TOC)**, popularised in the 1984 business novel
*The Goal*. The core claim: **in any chain, one constraint governs the throughput of the entire
system.** Improving anything that *isn't* the constraint produces no system-level gain.

---

## Three things you can watch happen in the game

### 1. Pile-up (the bottleneck fills)
Upstream stages keep handing product to the slow stage faster than it can move it, so the slow stage's
**input bin fills up**. In the game that bin glows orange, then red, then flashes `BOTTLENECK`. In a
real factory it's a wall of pallets in front of one machine; in a kitchen it's a backlog of tickets at
one station; on a highway it's the traffic jam *behind* the lane closure.

### 2. Starvation (everything downstream goes idle)
Because the bottleneck under-feeds the steps after it, those steps **run out of work** — their bins
empty and they sit idle (marked `idle`). A starving downstream stage is a dead giveaway that the real
problem is **upstream** of it. The expensive, fast Ship station is worthless if Process never feeds it.

### 3. Waste (overflow = rot)
Buffers are finite. When the pile exceeds the bin, product spills and is **lost**. This is the cost of
ignoring the constraint: you don't just go slow, you actively **destroy value** (spoilage, scrap,
expired inventory, abandoned carts).

---

## Why "local optimization ≠ global optimization"

The most common mistake — and the trap the game sets — is **improving a station that feels slow or
busy but isn't the constraint.** Boosting the Farm when *Process* is the bottleneck makes the Farm look
great (high local output!) while the system ships exactly the same number of potatoes and wastes more
of them. **A local win at a non-constraint is a global loss.** The only boost that raises throughput is
the one applied **to the current bottleneck.**

This is why TOC says: **manage the constraint, not the parts.** Goldratt's "Five Focusing Steps":
1. **Identify** the constraint (find the stage that's filling up).
2. **Exploit** it (get the most out of it — never let it sit idle or starved).
3. **Subordinate** everything else to it (don't overproduce upstream and drown it).
4. **Elevate** it (add capacity to the constraint — in the game, your boost).
5. **Repeat** — once you fix one constraint, a *different* stage becomes the new one. (The game's
   drifting rates make the bottleneck move, so step 5 never ends.)

---

## The moving bottleneck

In a real line the constraint isn't fixed forever — demand shifts, a machine slows, a worker tires. The
game models this with **drifting rates**: the slowest stage wanders down the line, and late in the round
**two stages can choke at once**, forcing you to triage with a limited number of boosts (cooldowns).
The skill that transfers to the real world: **continuously re-find the constraint** instead of
optimising last week's bottleneck.

---

## Where this shows up in real life

- **Manufacturing / Lean:** the constraint machine; *takt time*; just-in-time to avoid drowning the
  bottleneck in WIP (work-in-process) inventory.
- **Software & DevOps:** a slow build or review step gates the whole release pipeline; adding more
  developers upstream of it just grows the queue (this is why *flow* metrics beat *utilization*).
- **Logistics / supply chains:** one congested port or warehouse caps delivery for everything behind it.
- **Computing:** a program is bound by its slowest resource (CPU-, memory-, or I/O-bound); optimising a
  non-bottleneck instruction gives zero speedup — **Amdahl's Law** is the same idea in math form.
- **Everyday:** the checkout line, the one slow toll booth, the single overloaded teammate.

**The takeaway, in one line:** find the slowest step, pour your effort *there*, and don't waste energy
making the fast parts faster.
