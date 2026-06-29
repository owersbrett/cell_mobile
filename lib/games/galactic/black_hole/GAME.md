# GAME.md — Black-Hole Heart

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** galactic (`BioScale.galactic`)
- **Game id:** black_hole
- **One-line concept:** Fling stars into stable orbits around the galaxy's central
  supermassive black hole (Sgr A*) — closer orbits score more but ride the edge of
  the event horizon, where one slip is fatal.
- **Role:** solo high-score (also party-mode rotation)
- **Self-contained:** does NOT import any other game; the central-mass gravity
  core is implemented here. Differentiated on purpose from `planets/orbit_catch`
  and `solar_systems/orbital_mechanic` (see below).

---

## Concept

Most orbit games are gentle: a planet, a probe, a graceful arc. **Black-Hole
Heart is the EXTREME central engine.** There is ONE overwhelming mass at the
galaxy's heart — a supermassive black hole — with a lethal **event horizon**, a
glowing **accretion disk**, and a pull that grows faster-than-Newtonian as you
approach (a pseudo-relativistic correction that makes close orbits whip and
precess). You are not catching a target; you are **keeping a population of stars
alive** on the knife-edge around the singularity for as long, and as tightly, as
you can. The black hole always wins in the end — you score by how well you ride
the edge.

You **fling** a star by dragging: the drag vector is its launch velocity. Give it
too little sideways speed and it spirals across the horizon and is **swallowed**;
too much and it **escapes** off the field. The sweet spot is a real orbit. Tighter
orbits are faster (orbital velocity rises as radius shrinks), pay more per second,
and decay faster — so the best score lives in the most dangerous place.

---

## Rules (canonical)

1. **Fling to orbit.** Drag anywhere outside the horizon; the drag vector points
   where the star goes (direction = drag, speed = drag length through a power
   curve). Release to birth a star there with that velocity.

2. **One overwhelming mass.** Every star is pulled toward the center with
   `a = GM/r² · (1 + relK·horizon/r)`. The relativistic term blows up near the
   horizon — close orbits whip around and precess, exactly unlike a gentle planet.

3. **Two ways to lose a star.** Cross the **event horizon** (r ≤ horizon) → the
   star is **swallowed** (fed to the black hole). Fly past the **escape boundary**
   → the star is **lost** to the field. Either resets your revolution streak.

4. **Orbits decay (accretion drag).** Every orbit slowly bleeds energy and spirals
   inward. Inside the **ISCO** ring (innermost stable circular orbit analog) decay
   is ~3× faster — so the tightest, highest-scoring orbits are the most precarious
   and must be actively re-managed (re-fling, repopulate).

5. **Closer = more points.** Each living star earns continuous income ∝ closeness
   (`ref/r`): a star hugging the horizon out-earns a lazy wide orbit several times
   over. Completing a full **revolution** banks a bonus scaled by closeness and
   ticks the streak.

6. **Read before you fling.** A live trajectory preview runs the exact sim and
   labels the shot **ORBIT** (gold), **SWALLOWED** (violet), or **ESCAPES** (blue)
   so the orbital-velocity lesson is legible.

7. **Population cap.** Start juggling up to 4 stars; the cap grows to 7 over the
   round. You can only fling while below the cap — losing stars frees slots.

8. **Gravitational kicks (escalation).** After a grace period, periodic
   perturbation events whip every orbit with a random impulse (the screen pulses
   violet, "GRAVITATIONAL KICK") — stable orbits get knocked toward the horizon or
   out, and you must recover. The horizon also slowly grows, tightening the safe
   zone.

---

## Controls

Drag to fling a star (direction + power), release to launch. Multiple stars orbit
at once (up to the cap). All rendering is `CustomPainter` — no raster assets.

Visual language:
- **Event horizon** — pure black disk with a bright photon ring; a lensing halo;
  the ring flares white when a star is swallowed.
- **Accretion disk** — tilted, foreshortened rotating rings, violet (outer) → gold
  → orange (inner/hot), pulsing.
- **ISCO ring** — slowly rotating dashed gold ring; inside it, orbits decay fast.
- **Stars** — orbs that run hotter/whiter the closer (faster) they orbit
  (Doppler-bright), with a glowing trail.
- **Preview** — dotted curve, colored by its verdict, with an aim arrow + label.
- **HUD** — star pips (alive / cap) top-left; "fed N" (swallowed count) top-right.

---

## Scoring

| Event | Score |
|---|---|
| Living star, per second | `+44 × closeness`, `closeness = (150/r)` clamped 0.16–1.45 |
| Full revolution | `+60 × closeness` (and streak +1) |
| Swallowed / escaped | 0; the star is gone, streak resets |

`humanMax ≈ 6000` per 60s round (a skilled player keeping ~3 tight orbits alive
through the kicks). First-pass — retune after playtest.

---

## Win / end condition

Score attack. The host owns the 60s clock and results. Highest score when time
runs out wins (party mode). No game-over inside the widget; losing a star only
frees a slot, and a fresh fling always re-enters cleanly (the GAMES "S").

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Star cap | 4 → 7 (one more every ~18 s) |
| Event horizon | `32 → 44 px` over the round (safe zone tightens) |
| Gravitational kicks | First at 15 s, then every ~10 s, random impulse to all |
| Self-set risk | Tighter orbits = more income but faster decay — player-chosen |

---

## Educational tie

**Strong, structural.** The mechanic *is* the physics: a supermassive black hole's
event horizon, the inverse-square (plus relativistic) pull, why close orbits are
fast (`v = √(GM/r)`) and precarious, the ISCO, and accretion. The ORBIT /
SWALLOWED / ESCAPES preview teaches orbital velocity directly. Full write-up in
EDUCATION.md.

---

## Potato angle

Sgr A* is the still, silent heart everything in the galaxy turns around — Hot
Potato Games' "we've always been here, we always will be" energy, scaled to four
million suns. The stars you fling are spuds flung at the abyss; the disk is the
galaxy's slow boil. Don't worry about it.

---

## Session / resume

Host-driven session. State to persist for drop-and-resume: the live `_stars`
(position/velocity/accumulated angle), `_streak`, `_swallowed`, and the schedule
clocks (`_t`, `_nextKickT`). Fx/pops are ephemeral. On a fresh session the field
starts empty and the first fling re-enters cleanly.
