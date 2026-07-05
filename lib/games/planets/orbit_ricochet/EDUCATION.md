# EDUCATION.md — Ricochet (the E in GAMES)

> The educational component for the planets-scale bank-shot game. Topic: **specular reflection —
> angle of incidence = angle of reflection — on flat and convex surfaces**, plus **restitution as an
> energy budget**. Flight in this game is pure billiards (straight lines between bounces); the
> gravity-well visuals are dressing. Gravitational path bending is deliberately its sibling's lesson
> (Orbit Catch). Every claim below is something the *mechanics themselves* demonstrate; the player
> learns it by feel before they could name it.

---

## 1. The one-sentence takeaway

**A moving object that hits a surface leaves at the same angle it arrived — measured from the line
perpendicular to the surface — and between bounces it travels in a straight line.**

Master that one law on flat walls and curved bodies and you can put a ball anywhere on the field,
even places you can't see a straight line to. That is a bank shot.

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

## 3. The cue preview — why the game can promise you the truth

While you aim, Ricochet draws a **straight line to the first surface your shot will hit, a ring at
the exact impact point, and a short stub showing the reflected direction**. That preview isn't a
simulation or an estimate — it's a **ray cast**, the same geometry a pool player does by eye.

It can only be exactly truthful because the physics is pure billiards: with no force acting
mid-flight, the path between bounces IS a straight line, so predicting the first contact is solving
one line-vs-circle (or line-vs-wall) intersection. The stub after the impact is the law of
reflection applied once. This is the same reason light-ray diagrams in optics use straight lines and
one reflection rule — reflection is *local*: everything about the bounce is decided at the contact
point.

(Compare Orbit Catch, this game's sibling: there gravity curves the flight continuously, so no
straight-line preview could ever be honest. One force, and the whole geometry changes.)

---

## 4. Restitution — why a bounce loses energy

Real collisions aren't perfect mirrors; some energy goes into heat and deformation. We model that with
a **coefficient of restitution** (here `0.90` off bodies, `0.94` off walls): the outgoing speed is the
incoming speed times that factor. So each bounce is a little slower than the last. This is why a shot
**can't pinball forever** and why long multi-bank plans have to *land soon* — a lesson in energy budget,
not just geometry.

---

## 5. Flat vs convex — why bodies pay more and cost more

The game prices its surfaces: **bodies pay (+30 per carom), walls cost (−15)**. That's not
arbitrary — it mirrors the geometry:

- A **flat wall** is the forgiving surface. The normal is the same everywhere along it, so a small
  aiming error stays a small error after the bounce. Easy, reliable — and therefore cheap. The game
  charges you for taking the easy rail.
- A **convex body** amplifies error. Shift the contact point a few pixels and the normal swings,
  so the outgoing direction swings *more*. Precision on a curved surface is genuinely harder — this
  is **sensitivity to initial conditions**, the same effect that makes convex mirrors "wide-angle"
  and makes pinball chaotic. Harder skill, bigger reward.

So the scoring is the lesson wearing a costume: the game pays you in proportion to the difficulty of
the reflection geometry you just executed.

---

## 6. Why this is hard (and worth practicing)

- A round surface turns a **small aiming error into a large direction error** after the bounce.
  Precision matters most on convex surfaces.
- Energy decays, so a multi-bank plan must be *efficient*; you can't dawdle.
- The preview tells you the truth only up to the **first** contact — after that, every additional
  bounce compounds your aiming error. Plan the first carom exactly; hold the rest in your head, like
  a pool player calling a two-rail shot.

---

## 7. Quick glossary

| Term | Meaning in the game |
|---|---|
| **Normal** | The line perpendicular to a surface at the contact point; the axis a bounce mirrors across. |
| **Angle of incidence** | Angle between the incoming path and the normal. |
| **Angle of reflection** | Angle between the outgoing path and the normal — equal to incidence. |
| **Specular reflection** | Mirror-like reflection: one incoming direction → one outgoing direction. |
| **Ray cast** | Finding the first surface a straight ray hits — the aim preview, and how a pool player reads a shot. |
| **Restitution** | Fraction of speed kept after a bounce (0.90–0.94 here). |
| **Convex surface** | Curves away from you (planets, asteroids); amplifies aiming error after the bounce. |
| **Bank shot** | A shot aimed at a surface so its reflection — not its direct path — reaches the goal. |

---

## 8. One thing to try

Pick a level where the catcher hides behind a giant. Aim at the giant's **edge**, not its center, and
watch the cue preview: as you sweep your aim across the face of the planet, the reflected stub swings
wildly — that's the changing normal of a convex surface, live. Find the aim where the stub points at
the pocket and fire. The straight line, the ring, the stub — you just solved angle-of-incidence =
angle-of-reflection on a curved mirror, and it paid you +30 for the contact and a "1-BANK" at the
catch. Then notice what the wall route would have cost you.
