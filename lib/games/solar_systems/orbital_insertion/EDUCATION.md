# EDUCATION.md — Orbital Insertion

> The **E** in GAMES. What the player actually learns, and how the mechanic teaches it.

## The one idea: an orbit is *falling around* a body

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

Key facts the rounds drive home:
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

## How the mechanic teaches it (not just states it)

- **The live preview classifies the shot — CRASH / ORBIT / ESCAPE — before you release.** You watch
  the predicted conic bend with the gravity well as you change power and angle, so you build a
  physical model of the speed/angle window by experiment, not by being told a formula.
- **Captured orbits are drawn as their true ellipse**, glowing brighter the rounder they are — you
  literally see eccentricity as shape.
- **Harder planets vary the gravity (`mu`) and shrink**, so the "right speed" changes from world to
  world. The player learns that the balance isn't a fixed number — it depends on the body and your
  distance. Drifting planets add **leading a target**, the real problem of inserting around a moving
  body.

## Real-world hook

This is the actual job of an **orbital insertion burn**: a spacecraft arriving at a planet must shed
*exactly* the right amount of speed at the right moment so it's captured into orbit instead of
crashing through or sailing past. Get the burn wrong by a little and you either lithobrake (crash) or
fly off into deep space. Every probe at Mars, Jupiter, or Saturn solved the puzzle in this game.

## Takeaways (what a player should be able to say after)

1. An orbit is *falling sideways fast enough to keep missing the ground.*
2. Too slow → crash; too fast → escape; in between → orbit.
3. A circle needs one specific speed, aimed sideways; that speed is `√(mu/r)`.
4. Escape happens at `√2 ×` the circular speed.
5. Closer/heavier bodies pull harder, so the "right speed" changes per planet.
