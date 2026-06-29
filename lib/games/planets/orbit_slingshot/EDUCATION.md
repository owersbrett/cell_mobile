# EDUCATION.md — Slingshot

> The E in GAMES. What a player actually learns, why the mechanic teaches it, and
> the real science behind it.

## The lesson: the gravity assist (slingshot maneuver)

**A spacecraft can steal speed and direction from a planet's gravity.** Fly a
probe close behind a moving planet and the planet's gravity bends the probe's
path and—because the planet is itself moving around the Sun—hands the probe a net
gain in speed *relative to the Sun*. Chain several of these flybys and a tiny
launch can reach the outer solar system that no rocket could reach directly.

This game makes that idea **the controls**: you can't fly straight to the far
beacon. You aim so the probe grazes one well, gets whipped toward the next, grazes
that one, and rides the chain across the system. Each well it slings past is a
**gravity assist**, and the on-screen CHAIN counter is literally counting them.

## Why the mechanic teaches it (not just decorates it)

- **Curved, not straight.** Every shot bends in `a = G·mass / r²` gravity. You
  *feel* that mass and closeness set how hard a body turns you — the inverse-square
  law as muscle memory.
- **Chaining is the win.** Scoring is `50 + 26 × (assists²)`. The super-linear
  payout means the optimal play is the *longest viable chain* — the same reason
  mission planners string flybys together instead of brute-forcing fuel.
- **Read-ahead trajectory.** The live preview is a mini "trajectory optimizer":
  you're previewing a multi-body path and choosing the launch that threads it —
  the actual job of a navigation team.
- **Assist band, not collision.** You want to graze the band, not hit the core.
  Real flybys have a closest-approach altitude: too far does nothing, too close
  is a crash. The dashed ring teaches that window.

## The real science

- **Mechanism.** In the planet's frame the probe's *speed* is unchanged by a
  flyby (energy is conserved there) — only its *direction* turns. But the planet
  moves around the Sun, so in the **Sun's frame** the turned velocity adds (or
  subtracts) the planet's orbital motion. Aim the flyby "behind" the planet's
  motion and the probe speeds up; "ahead" and it slows down (useful for reaching
  the inner planets). It's an elastic "collision" with a body so massive it barely
  notices — momentum the planet loses is unmeasurable.
- **Voyager.** Voyager 2 (1977) used Jupiter → Saturn → Uranus → Neptune, each
  flyby slinging it to the next, exploiting a planetary alignment that recurs only
  ~every 175 years. Voyager 1 used Jupiter and Saturn. Both are now in interstellar
  space — reachable *only* because of chained gravity assists.
- **Others.** Cassini (Venus-Venus-Earth-Jupiter) reached Saturn; Galileo and New
  Horizons (Jupiter) likewise. Parker Solar Probe uses repeated **Venus** assists
  to *lose* speed and spiral closer to the Sun — the same trick in reverse.

## What a player should be able to say afterward

- "Gravity can bend and speed up a spacecraft without using fuel."
- "Chaining flybys lets a small launch reach far across the solar system."
- "That's how Voyager crossed from Jupiter all the way to interstellar space."
- "Heavier/closer planets turn the path harder — but get too close and you crash."

## Stretch / discussion

- Why does the assist add speed in the Sun's frame but not the planet's?
- Why are gravity-assist mission windows rare (planetary alignment)?
- Parker Solar Probe uses assists to slow down — when would you want that?
