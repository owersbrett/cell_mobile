# EDUCATION.md — Orbit Catch

> The E in GAMES. What a player actually learns, why the mechanic teaches it,
> and the real science behind it.

## The lesson: gravity bends trajectories — and you can aim with it

**Nothing in space travels in a straight line near mass.** A thrown object's
path is a curve set by every gravity source it passes: the heavier the body
and the closer the pass, the harder the turn. Orbit Catch makes that the whole
game — you cannot hit Earth by aiming at Earth. You aim into the field,
predict the bend, and let gravity finish the throw.

## Why the mechanic teaches it (not just decorates it)

- **Mass sets pull, visibly.** Wells are drawn bigger when they're heavier and
  labelled GIANT / MID / SMALL; their influence rings scale with mass. After a
  few shots the player is *reading* gravitational strength off a body's size —
  exactly the mass term in the force law, as intuition.
- **Distance sets pull, in the hands.** A shot that grazes a giant whips
  violently; the same shot 100px wider barely bends. The falloff-with-distance
  half of the law becomes muscle memory. (The game uses a softened `r^1.5`
  falloff instead of true `1/r²` so the effect stays dramatic at screen scale
  — the *shape* of the lesson, closer = much stronger, is preserved.)
- **Prediction is the skill.** The live trajectory preview is a real
  integration of the equations of motion — the same job as a mission
  navigation team plotting a transfer. The player practices "propagate the
  trajectory, then commit," not trial-and-error spam (4 shots per level makes
  each prediction matter).
- **Slingshots emerge on their own.** Level 2 ("Slingshot") places the target
  BEHIND the player relative to the giant: the only solution is to fly past
  the well and let its pull whip the potato back around — a gravity-assist
  flyby, discovered by necessity. (The sibling game Orbit Slingshot then
  builds a whole variant on chaining these.)
- **Crash vs. catch = capture vs. impact.** Touching a well's surface destroys
  the potato; reaching Earth's zone lands it. The player learns the difference
  between a trajectory that intersects a body and one that arrives at the
  destination — the core distinction in any mission plan.

## The real science

- **Newton's law of universal gravitation.** Every mass pulls every other with
  `F = G·m₁·m₂ / r²` — proportional to mass, falling off with the square of
  distance. That is why the GIANTs dominate the board and why close passes
  turn so hard.
- **Newton's cannonball.** The game is Newton's own thought experiment: throw
  something sideways fast enough and gravity's curve becomes an orbit; too
  slow and it falls in; too fast and it escapes. Every shot in Orbit Catch
  lives on that spectrum — fall in (crash), thread the curve (catch), or fly
  out (miss).
- **Trajectories, not lines.** Real spacecraft never point at their target.
  A Mars transfer aims at where Mars *will be*, along a curve the Sun's
  gravity bends the whole way — the same reason the drifting-Earth levels make
  you lead the target.
- **The gravity assist.** Voyager, Cassini and New Horizons all used close
  planetary flybys to bend (and gain) velocity without fuel. Level 2's whip
  around the giant is a one-body version of exactly that maneuver.
- **Softening, honestly.** Real simulations also modify the force law near
  singularities ("gravitational softening" in N-body codes) — the game's 22px
  softening radius and `r^1.5` falloff are the same kind of principled
  adjustment, tuned for legibility.

## What a player should be able to say afterward

- "Heavier things pull harder, and getting closer makes the pull much
  stronger."
- "In a gravity field you aim where the curve goes, not where the target is."
- "A close flyby can whip you around a planet — that's how probes slingshot."
- "Predicting the path before you commit is the actual skill of spaceflight."

## Stretch / discussion

- Why does aiming *straight at* Earth usually fail in this game?
- The game uses `r^1.5` instead of `1/r²`. What would change if it used the
  real law at this screen size? (Hint: how strong would a well feel two well-
  widths away?)
- On the drifting-Earth levels you have to lead the target. How is that like
  launching a probe to Mars?
- What's the difference between a trajectory that *hits* a planet and one that
  *orbits* it? Which shots in the game come closest to orbiting?
