# EDUCATION.md — Pursuit

> The educational component (the **E** in GAMES). What the game teaches and how the mechanic *is* the
> lesson — not a fact pasted on top, but the thing your hands learn by playing.

## The core idea: you aim where it *will be*, not where it *is*

Pursuit teaches **lead / intercept prediction** — the single most important idea in hitting (or
meeting) a moving thing. You never aim at a moving target's current position, because by the time
your projectile arrives, the target has moved on. You aim at the **future position**: the spot where
the target and your projectile will be at the *same place at the same time*.

Two things stretch the gap between "where it is" and "where it will be," and the game makes you feel
both at once:

1. **Travel time.** Your planetlet is not instantaneous. The farther/slower the shot, the longer it's
   in flight, and the more the target moves while it travels. A faster shot (`_kMaxLaunchSpeed`)
   shortens the flight and the lead; a gentle lob lengthens both.
2. **The curve.** Gravity bends the shot, so its path isn't a straight line you can eyeball. You have
   to predict where the *bent* path ends up *and* where the orbiting target will have drifted to. The
   trajectory preview solves half the problem (where the shot lands); the orbit path + ghost dots
   solve the other half (where the target will be). Lining the two up is the whole skill.

## Why this is real: orbital rendezvous

This is not a toy version of an abstract idea — it is exactly how spacecraft meet in orbit, and how
any guided interception works:

- **Rendezvous.** A capsule docking with the ISS does not thrust toward where the station *is*. It
  targets a future point along the station's orbit and arrives there as the station does. Mission
  planners compute a **lead angle** from the station's orbital speed and the transfer time — the same
  quantity your eyes estimate from the spacing of the ghost dots.
- **Lambert's problem.** "Given two positions and a travel time, what launch velocity connects them?"
  is a classic of orbital mechanics (the Lambert problem). Every shot in Pursuit is you solving a
  rough Lambert problem by hand: pick a launch direction + power so the curved path meets the target
  at the right moment.
- **Lead in general.** A quarterback throwing to a running receiver, a goalkeeper, anti-air gunnery,
  even a cat pouncing — all solve the same equation: future target position = current position +
  velocity × time-of-flight. Pursuit isolates that intuition and drills it.

## How the mechanics encode the lesson

| Mechanic | What it teaches |
|---|---|
| Target orbits / drifts; intercept uses its LIVE position | You *must* lead; aiming at "now" misses by the distance it travels during flight. |
| Future **ghost dots** spaced by a fixed time step | A visual ruler for lead: more spacing between dots = faster target = bigger lead needed. |
| Direction arrow + pro/retrograde levels | Lead direction flips with motion direction — you learn to read *which way* to lead, not just how far. |
| Eccentric "comet" orbits (race at the turns) | Target speed isn't constant; lead must grow and shrink along the path (Kepler's 2nd law in feel — faster near the focus). |
| Faster shots shorten the required lead | Travel time is a variable you control; trading power for lead is a real tactic. |
| Fewer ghost dots at higher levels | Scaffolding fades — you internalize the prediction instead of reading it off the screen. |

## The takeaways a player leaves with

1. To hit a moving target, aim at its **future** position, not its current one.
2. The faster the target (or the slower your shot), the **more** you lead.
3. Lead has a **direction** as well as a size — it follows the target's motion.
4. This is the exact reasoning behind **orbital rendezvous**: meet a moving body by targeting where it
   will be when you arrive.

## Potato angle

Russ would call it "throwing the spud to where the conveyor *will* be." The Hot Potato Games supply
line never stops moving; you don't toss the potato at the bin that's in front of you — you toss it at
the bin that'll be in front of you when the potato lands. Same math, smaller scale, more gravy.
