# EDUCATION.md — Ricochet (the E in GAMES)

> The educational component for the planets-scale bank-shot game. Topic: **reflection (angle of
> incidence = angle of reflection) layered on gravitational path bending** — i.e. bank shots and
> gravity assists. Every claim below is something the *mechanics themselves* demonstrate; the player
> learns it by feel before they could name it.

---

## 1. The one-sentence takeaway

**A moving object that hits a surface leaves at the same angle it arrived — measured from the line
perpendicular to the surface — and gravity keeps curving its path the whole time in between.**

Master those two facts together and you can put a ball anywhere on the field, even places you can't
see a straight line to. That is a bank shot.

---

## 2. Angle of incidence = angle of reflection

When the planetlet strikes a wall, a planet, or an asteroid, it reflects. The rule that governs the
bounce is the **law of reflection**:

> The angle the incoming path makes with the surface **normal** (the line perpendicular to the surface
> at the contact point) equals the angle the outgoing path makes with that same normal. The incoming
> path, the outgoing path, and the normal all lie in the same plane.

- On a **flat wall**, the normal points straight in from the wall, so a shot coming in at 30° leaves
  at 30° on the other side — like light off a mirror, or a cue ball off the rail.
- On a **round planet or asteroid**, the normal points from the center of the body straight out
  through the contact point. Because the normal direction *changes* depending on **where** on the
  curve you hit, a round body can fling the shot in a huge range of directions. Hit it dead-center and
  it comes straight back; clip the edge and it barely deflects. **Choosing the contact point is the
  whole game.**

In the code this is one line of vector math:

```
v' = v − 2 (v · n) n      // reflect velocity v about the unit surface normal n
```

`(v · n)` is how much of your velocity points into the surface; subtracting twice that flips exactly
the perpendicular component and leaves the parallel component untouched — which is precisely "angle in
= angle out."

---

## 3. Restitution — why a bounce loses energy

Real collisions aren't perfect mirrors; some energy goes into heat and deformation. We model that with
a **coefficient of restitution** (here `0.90` off bodies, `0.94` off walls): the outgoing speed is the
incoming speed times that factor. So each bounce is a little slower than the last. This is why a shot
**can't pinball forever** and why long multi-bank plans have to *land soon* — a lesson in energy budget,
not just geometry.

---

## 4. Gravity bending the path between bounces

Reflection handles the instant of contact. **Gravity handles everything in between.** Each gravity
well pulls the planetlet with a force that grows as you get closer (`a = G·mass / r²` — the inverse
square law). So between two bounces the path is never a straight line; it's a **curve**. A real bank
shot in this game is therefore *two* skills stacked:

1. Pick a launch direction whose **curved** path arrives at a surface at the right contact point.
2. Trust that the **reflected** path, itself curved again by the next well, drops into the catcher.

This is genuinely how trajectory design works in the real world — you never get to think about
straight lines.

---

## 5. The gravity assist (the "slingshot")

When a spacecraft flies close past a planet, the planet's gravity bends its path and — because the
planet is itself moving — the craft can leave with **more speed**, stolen from the planet's orbital
motion, and pointed in a new direction. Voyager, Cassini, and every outer-planets mission used this.

In Ricochet you feel the directional half of a gravity assist on every shot: aim *near* a giant and it
whips your planetlet around onto a new heading you could never have launched directly. Combine that
bend with a wall or asteroid carom and you've built, by hand, the exact maneuver mission planners spend
months optimizing.

---

## 6. Why this is hard (and worth practicing)

- A round surface turns a **small aiming error into a large direction error** after the bounce —
  sensitivity to initial conditions. Precision matters most on convex surfaces.
- Energy decays, so a 3-bank plan must be *efficient*; you can't dawdle.
- Gravity is strongest exactly where you most want to skim (close to a body), so the curve fights your
  intuition near every well.

The trajectory preview teaches this honestly: it shows your predicted path **bright up to the first
carom** and **faint afterward**, because every additional bounce compounds uncertainty. Aim with the
bright part; treat the faint part as a hint, not a promise.

---

## 7. Quick glossary

| Term | Meaning in the game |
|---|---|
| **Normal** | The line perpendicular to a surface at the contact point; the axis a bounce mirrors across. |
| **Angle of incidence** | Angle between the incoming path and the normal. |
| **Angle of reflection** | Angle between the outgoing path and the normal — equal to incidence. |
| **Restitution** | Fraction of speed kept after a bounce (0.90–0.94 here). |
| **Inverse-square gravity** | Pull strength ∝ 1/distance²; doubling the distance quarters the pull. |
| **Gravity assist / slingshot** | Using a body's gravity (and motion) to redirect and speed up a passing object. |
| **Bank shot** | A shot aimed at a surface so its reflection — not its direct path — reaches the goal. |

---

## 8. One thing to try

Pick a level where the catcher sits in a corner behind a giant. Don't aim at the catcher — aim at the
**wall** beside it, a touch above the line you think you need, and let the giant's pull tighten the
incoming angle. Watch the bright preview hit the wall, then read the faint forecast curl into the
pocket. When it drops in after the bounce, you just did angle-of-reflection + gravity assist in one
motion. That's the whole lesson, and it scores a "1-BANK."
