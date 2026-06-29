# GAME.md — Stellar Evolution

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Rules-are-the-asset — build from this.

- **Scale (solar systems):** `BioScale.solarSystems`
- **Game id:** `stellar_evolution`
- **One-line concept:** Guide ONE star through its whole life, phase by phase, with a quick
  action each phase — and the star's **MASS branches its destiny**. Sun-like stars fade to a
  white dwarf; massive stars detonate as a supernova and collapse into a neutron star or a
  black hole. Run as many star lives as you can in 60 seconds.
- **Role:** solo / party score attack.
- **Duration:** 60s (host-owned clock).

---

## The core idea (why it's built this way)
A star's death is decided at its birth, by ONE number: its mass. The game makes the player
*feel* that fork. Every star starts the same way (nebula → protostar → main sequence), then the
**mass meter at the top** splits the path. Low-mass stars take the gentle road to a white dwarf;
high-mass stars take the violent road through a supernova. Reaching the dramatic endpoints pays
the most, so the player learns to *want* mass — and learns what mass buys.

You can even nudge fate: tapping fast in the nebula accretes extra gas, and a borderline star can
cross the **8 M☉** line into the supernova branch.

---

## The life cycle (the phases)

Common spine (every star):
1. **Stellar Nursery (nebula) — MASH.** Tap fast to collapse the gas cloud and ignite a core.
   Each tap also **accretes mass**.
2. **Protostar — TIMED TAP.** A marker sweeps a track; tap inside the ignition window to light
   fusion. Dead-centre = timing bonus.
3. **Main Sequence — BALANCE.** Gravity constantly drags the needle toward collapse; **tap to add
   fusion pressure** and push it back. Keep the needle in the green band long enough to live out a
   stable life. This is gravity vs fusion equilibrium, made physical.

The fork (decided by mass, ≥ 8 M☉ = high):
4. **Giant — MASH.** Tap to swell into a **red giant** (low mass) or **red supergiant** (high mass).

Low-mass tail:
5L. **Planetary Nebula — MASH.** Tap to puff off the outer shells and expose the core.
6L. **WHITE DWARF** — modest payoff.

High-mass tail:
5H. **Supernova — TIGHT TIMED TAP.** A fast marker, a narrow window. Nail it to detonate. Big payoff.
6H. **NEUTRON STAR** (8–20 M☉) or **BLACK HOLE** (> 20 M☉) — large / largest payoff.

After the endpoint, a new star is born and the difficulty ticks up.

---

## Scoring (tuned, adjust by playtest)
- Per phase cleared: a base value + a **speed bonus** (more leftover phase time = more points).
- Timed taps add a **timing bonus** for accuracy.
- Endpoints: white dwarf 50 · neutron star 130 · black hole 220.
- A **clean-clear combo** adds a small per-phase bonus; a 5+ combo **doubles the endpoint payoff**.
- A missed timed-tap or an unstable main sequence breaks the combo. A phase timeout gives token
  credit and moves on (the star's life always progresses).

## Win / end condition
Most points when the 60s host clock runs out. (Host owns the timer, score and results.)

## Difficulty curve
Each completed star life raises the difficulty: phase timers shrink, timed windows tighten, the
sweep is faster, gravity pulls harder, and mash targets grow. Early lives are gentle; late lives
demand clean, fast play.

## Session / resume (the S in GAMES)
The host owns session lifecycle: the round closes at 0s, the results screen shows, and a fresh
round re-enters cleanly. The widget gates all simulation on `session.isRunning`, auto-starts its
first star on the first running frame, and shows a calm idle star when not running.

## Canvas-only rule
All rendering is one `CustomPainter` driven by a single `Ticker`. No raster assets. The star,
nebula, shells, supernova flash, pulsar beams, accretion ring, action UI, HUD, particles and
floating text are all drawn.
