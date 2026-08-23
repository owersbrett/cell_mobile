# EDUCATION.md — Orbital Insertion

> The **E** in GAMES. What the player actually learns, and how the mechanic teaches it.
> v2 (CONSTELLATION rules) teaches TWO ideas: the classic one — an orbit is *falling around* a
> body — and a new one the multi-moon loop makes visceral — *why crowded orbits collide, and why
> phasing is the answer*.

## Idea one: an orbit is *falling around* a body

The intuitive picture of a moon "hovering" near a planet is wrong. A moon in orbit is **constantly
falling** toward the planet — gravity pulls it inward every instant — but it is also moving
**sideways** fast enough that the planet's surface curves away beneath it just as fast as it falls.
It keeps missing the planet. That perpetual "falling and missing" *is* an orbit.

Newton's cannonball is the canonical thought experiment, and it is exactly this game:
- Fire too **slowly** and the sideways motion can't keep up with the fall — the path curves into the
  ground. **You crash.** (In the game: periapsis dips below the planet's surface.)
- Fire too **fast** and you outrun gravity's ability to bend your path back around — you climb away
  and never return. **You escape.** (Specific orbital energy `E ≥ 0`: an unbound hyperbola.)
- Fire at the **right speed**, roughly **sideways (tangential)** to the planet, and the fall and the
  sideways motion balance into a closed loop. **You orbit.**

## The balance you feel in your thumb

Two quantities fight each other, and the game makes both visible:

1. **Gravity** — pulls the moon toward the planet, strength ∝ `mu / r²` (mu = G·M). Bigger or closer
   planet ⇒ stronger pull. Shown as the glowing gravity-well rings.
2. **Tangential speed** — how fast you're moving *across* the pull. This is set by your drag power and
   angle.

Key facts the run drives home:
- **Circular orbital speed:** `v_circ = √(mu / r)`. There is exactly *one* speed (at a given radius,
  aimed tangentially) that gives a perfect circle. Too slow → ellipse that dips toward the planet
  (and may crash); too fast → ellipse that bulges outward (and beyond `√2·v_circ`, escapes).
- **Escape speed:** `v_esc = √(2·mu / r) = √2 × v_circ`. Cross it and the orbit opens into an
  unbound path. So the entire capture window is the band **between the crash speed and ~1.41×
  circular speed** — narrow, and the preview lets you find it.
- **Direction matters as much as speed.** A fast shot aimed *straight at* the planet still crashes —
  it has speed but almost no sideways (angular) momentum. Orbits want **tangential** velocity. This
  is why aiming to the *side* of the planet, not at it, is the winning instinct.
- **Eccentricity = how circular.** `e = 0` is a circle; `0 < e < 1` is an ellipse (egg-shaped);
  `e ≥ 1` escapes. The game rewards low `e` because a circular orbit is the cleanest balance of fall
  and sideways motion — and is harder to hit, since it demands the exact speed *and* angle.
- **The "right speed" is not a constant.** The planet accretes mass late in the run (`mu` swells),
  so the insertion speed that captured cleanly at 10 seconds crashes at 50. Orbital speeds depend
  on the body, not on your controller muscle memory. (One honest game abstraction: moons already
  in orbit keep their locked ellipse while the mass swells — real orbits would slowly tighten.)

## Idea two (new in v2): why crowded orbits collide — and what phasing is

The constellation loop teaches the core logic of **space traffic**:

- **Every orbit you launch passes back through where you launched it.** An orbit is a closed curve
  through its insertion point, so *all* your moons' paths thread the same region near the pad. Two
  orbits crossing in space is the norm, not the exception.
- **Crossing paths ≠ collision. Crossing paths *at the same time* = collision.** Whether two moons
  on intersecting orbits ever meet is a question of **phase** — where each one is along its path
  when the other reaches the crossing. This is exactly how real constellations (GPS, Starlink)
  share shells and crossing planes safely: the geometry intersects; the *timing* never does.
- **Orbital period sets the rhythm:** `T = 2π√(a³/mu)` (Kepler's third law). Two moons with the
  same semi-major axis lap in lockstep — launch them half a period apart and they can share a
  crossing forever without meeting. Different `a` means different periods, so their relative phase
  *drifts*: safe today, colliding in three laps. The near-miss you watched develop over several
  revolutions IS resonance-like phase drift, felt directly.
- **More moons, more risk, more reward** — the game's score tension is the real trade-off of
  constellation design, and the collision penalty is a tiny taste of the **Kessler problem**: in
  crowded orbital space, every collision makes the sky worse.

**What the player practices without being told:** launching the next moon when the pad's crossing
region is clear — i.e., *phasing insertions against the existing constellation*. That is a genuine
rendezvous/stationkeeping instinct.

## How the mechanic teaches it (not just states it)

- **The live preview classifies the shot — CRASH / ORBIT / ESCAPE — before you release.** You watch
  the predicted conic bend with the gravity well as you change power and angle, so you build a
  physical model of the speed/angle window by experiment, not by being told a formula.
- **Captured orbits are drawn as their true ellipse**, glowing brighter the rounder they are — you
  literally see eccentricity as shape.
- **Every completed revolution pays, with a ring-pulse on the moon** — the lap payout is the
  visible definition of "stable orbit": it came back around. No lap, no stability, no points.
- **Collisions are earned, never random.** You watched both orbits get drawn; you chose to launch
  into a crowded sky. The −60 and the double burst close the loop on the phasing lesson.
- **The late-round mass swell** moves the capture band under your feet — proving the balance
  depends on the body, not a memorized drag length. **Drift** adds leading a moving target, the
  real problem of inserting around a moving body.

## Real-world hook

This is the actual job of an **orbital insertion burn** — a spacecraft arriving at a planet must
shed *exactly* the right speed at the right moment or it lithobrakes (crash) or sails past
(escape) — **plus** the actual job of a **constellation operator**: putting many satellites into
compatible, phased orbits so they never occupy a crossing at the same instant, because every
collision (Iridium–Kosmos, 2009) litters the shell for everyone. Every probe at Mars solved the
first puzzle; everyone flying Starlink solves the second one daily.

## Takeaways (what a player should be able to say after)

1. An orbit is *falling sideways fast enough to keep missing the ground.*
2. Too slow → crash; too fast → escape; in between → orbit.
3. A circle needs one specific speed, aimed sideways; that speed is `√(mu/r)` — and it changes if
   the planet's mass changes.
4. Escape happens at `√2 ×` the circular speed.
5. Every orbit passes back through its launch point, so crowded orbits *cross*; whether they
   *collide* is about timing (phase), not geometry.
6. Same-period orbits keep their spacing; different periods drift in phase — safe now can mean
   colliding later.
