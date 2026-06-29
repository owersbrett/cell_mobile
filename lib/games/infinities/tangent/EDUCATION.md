# EDUCATION.md — Tangent: the derivative as the slope of the tangent line

> The E in GAMES. The lesson is the mechanic: reading the steepness of the tangent line at a point
> **is** computing the derivative there. This file is the full write-up; the game reinforces it with a
> per-answer context card and a rise/run triangle.

## The one idea

> **The derivative of a function at a point is the slope of the tangent line at that point.**

That's the whole game. When you freeze the dot and the tangent line appears, the number you're picking
— rise over run — is the value of the derivative right there.

## Rate of change = steepness

A function `y = f(x)` answers "for this x, what is y?" The **derivative** answers a different question:
**"right here, how fast is y changing as x increases?"** That rate of change is exactly how steep the
curve is at that point — its slope.

- **Steep tangent → large slope → y is changing fast.** A small step sideways in x produces a big
  change in y.
- **Gentle tangent → small slope → y is changing slowly.**
- **Flat tangent → slope 0 → y is (instantaneously) not changing.** These are the **turning points** —
  the tops of hills and the bottoms of valleys, where the curve stops rising and starts falling (or
  vice-versa). In the game, the arch's peak, the sine's crests/troughs, and the cubic/quartic's bends
  all sit at slope 0.
- **Positive slope → curve rising** (tangent tilts up-right). **Negative slope → curve falling**
  (tangent tilts down-right).

## Slope = rise over run

The slope of any straight line is

```
slope = rise / run = (change in y) / (change in x)
```

The tangent line is just a straight line, so its slope is read the same way. The game draws a faint
**rise/run triangle** after each answer: move **1 step across** in x (the *run*), and the line goes up
or down by the *rise*. `rise ÷ 1 = rise`, so with a run of 1 the rise **is** the slope. That triangle
is the picture of the derivative.

## Tangent vs secant — why "instantaneous"

A **secant** line connects **two** points on the curve; its slope is the *average* rate of change
between them. As you slide the second point closer and closer to the first, the secant pivots and
settles onto the **tangent** — a line touching the curve at a single point. The tangent's slope is the
**limit** of the secant slopes, and that limit is the **instantaneous** rate of change: the derivative.

```
average rate of change  =  slope of a secant (two points)
instantaneous rate      =  slope of the tangent (one point)  =  the derivative
```

This is why the derivative is "instantaneous": it's the rate of change at a single instant, not over an
interval. (Under the hood the game computes the tangent slope with a tiny finite difference — a secant
across a microscopic step — which is the same limiting idea made numerical.)

## Reading the curves in the bank

| Curve | Where the slope is big | Where the slope is ~0 (turning points) |
|---|---|---|
| Parabola `0.32x² − 2.2` | far from the vertex | at the vertex (bottom) |
| Arch (downward parabola) | on the steep sides | at the peak |
| S-curve (logistic) | in the steep middle | flat tails (top and bottom) |
| Sine `2.2·sin(1.05x)` | at the zero-crossings (steepest) | at every crest and trough |
| Cubic `0.28x³ − 1.1x` | at the ends | at its two bends |
| Quartic "W" | on the rising/falling walls | at the two valleys and the central hump |
| Lemniscate (∞) | near the centre crossing (near-vertical) | at the far left/right tips |

Notice the pattern: **slope and height are different questions.** A point can be high on the curve but
flat (a peak, slope 0), or low but steep (a zero-crossing of a sine). The game keeps height and slope
deliberately uncorrelated so you have to read the *tangent*, not the *position*.

## Why this matters (beyond the game)

Derivatives are the rate-of-change engine of calculus and show up everywhere a quantity changes over
another:

- **velocity** is the derivative of position with respect to time (how fast you're moving *right now*),
- **acceleration** is the derivative of velocity,
- **marginal cost** is the derivative of total cost,
- **growth rate** is the derivative of a population.

In every case it's the same move you make in this game: find the tangent, read its slope, and you know
how fast the thing is changing at that instant. Where the slope is zero, the quantity is at a peak,
a trough, or a momentary standstill — which is exactly how derivatives find maxima and minima.

## Glossary

- **Tangent line** — a straight line touching the curve at one point with the curve's local slope.
- **Secant line** — a straight line through two points of the curve; its slope is an average rate.
- **Slope** — rise ÷ run; how steep a line is.
- **Derivative** — the slope of the tangent; the instantaneous rate of change of `y` with respect to `x`.
- **Turning point** — where the slope is 0 (a local max or min); the curve changes direction.
