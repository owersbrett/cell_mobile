# EDUCATION.md — Area Under (the definite integral)

> What this game teaches: the **definite integral** — the area under a curve — built up the way it is
> actually *defined*, as the limit of a **Riemann sum** of infinitely many rectangles. The mechanic
> IS the lesson: every time you drag the slider and watch the rectangles tighten onto the curve while
> your estimate locks onto the true value, you are performing the limit `n → ∞` with your own hand.

- **Scale:** `BioScale.infinities` — the integral is, quite literally, an **infinite sum**.
- **Game:** `area_under` (this game).
- **Source data:** `area_under_data.dart` (12 curves across three difficulty tiers).

---

## 1. The question: how much area is under a curve?

Finding the area of a rectangle is easy: base × height. A triangle, a circle — also solved long ago.
But the area under a **curved** graph — say `f(x) = x²` from `x = 0` to `x = 3` — has no
elementary "base × height" because the height is *changing continuously*. This is one of the two
central problems of calculus (the other being the slope of a curve, the derivative). The answer is
the **definite integral**, written:

```
        ⌠ b
        ⎮   f(x) dx
        ⌡ a
```

read as "the integral of `f(x)` from `a` to `b`." It is the (signed) area between the curve and the
x-axis over the interval `[a, b]`.

---

## 2. The trick: approximate with rectangles (Riemann sums)

We cannot measure the curved region directly, so we **approximate it with shapes we can measure —
rectangles** — and then make the approximation better and better.

Slice `[a, b]` into `n` equal strips, each of width:

```
Δx = (b − a) / n
```

On each strip, build a rectangle whose **height is the value of the function** somewhere on that
strip. The total area of all the rectangles is the **Riemann sum**:

```
Sₙ  =  f(x₁)·Δx  +  f(x₂)·Δx  +  …  +  f(xₙ)·Δx
    =  Σ  f(xᵢ)·Δx        (i = 1 … n)
```

Where you take the height — the choice of `xᵢ` — gives the three classic rules:

- **Left rule:** height = `f` at the **left** edge of each strip.
- **Right rule:** height = `f` at the **right** edge of each strip.
- **Midpoint rule:** height = `f` at the **middle** of each strip. *(This game uses the midpoint rule
  — it hugs the curve best and converges fastest.)*

For a curve that is increasing, the left rule **under**estimates (rectangles sit below the curve) and
the right rule **over**estimates; the midpoint rule splits the difference and is far more accurate.
A few rectangles give a rough answer; the staircase of rectangle-tops only loosely follows the curve.

---

## 3. The payoff: let n → ∞ (this is the integral)

Here is the whole idea, and the felt core of the game. As you **add more rectangles** (increase `n`),
each strip gets thinner, the staircase of rectangle-tops smooths into the curve, and the Riemann sum
gets closer and closer to the true area. The definite integral is **defined** as the limit of this
process:

```
        ⌠ b
        ⎮   f(x) dx   =   lim   Σ  f(xᵢ)·Δx
        ⌡ a              n → ∞
```

That is the punchline of the **infinities** scale: the integral is an **infinite sum** — infinitely
many rectangles, each of infinitesimal width `dx`, added together. The elongated "S" of the integral
sign `∫` is literally a stretched **S for "sum."** When the game shows `n = 76 → ∞`, that arrow is
the limit doing its work: no finite `n` is exactly right, but the *limit* is exactly the area.

In the game your **estimate** is `Sₙ`, the MATCH meter measures how close `Sₙ` is to the true
integral, and dragging n upward is you taking the limit by hand. You never reach `∞`, but you get as
close as the tolerance demands — which is exactly how a limit works.

---

## 4. Signed area — when the curve dips below the axis

So far we assumed `f(x) ≥ 0`, so "area under the curve" and "the integral" are the same positive
number. But the integral tracks **signed area**:

- Where the curve is **above** the x-axis, area counts as **positive**.
- Where the curve is **below** the x-axis, area counts as **negative**.

So `∫ₐᵇ f(x) dx` is the area above the axis **minus** the area below it — the **net** signed area. In
the game's later (tier-2) rounds, rectangles that fall below the axis turn **rose** and **subtract**
from your estimate. Two consequences worth feeling:

- For `f(x) = sin x` over a **full** period `[0, 2π]`, the bump above the axis and the dip below are
  equal, so the net integral is **0** — even though plenty of "area" is enclosed. (The game avoids
  exactly-zero targets, but it uses partial periods so you watch positive and negative areas fight.)
- "Total area enclosed" (which would take the absolute value on each piece) and "the integral" (which
  keeps the signs) are **different questions**. The integral is the signed one.

This is also why integrals model **accumulated change**, not just geometric area: a velocity that
goes negative (moving backward) subtracts from displacement, exactly as below-axis area subtracts
from the integral.

---

## 5. The integral as accumulated total

The deepest reading: **the integral accumulates a rate into a total.** If `f(x)` is a *rate* —
speed (distance per time), flow (litres per second), power (energy per second) — then `∫ₐᵇ f(x) dx`
is the **total amount accumulated** from `a` to `b`:

| If `f(x)` is… | …then the area under it is… |
|---|---|
| velocity vs. time | distance travelled |
| flow rate vs. time | total volume |
| power vs. time | total energy |
| population growth rate vs. time | total change in population |
| force vs. distance | work done |

Each thin rectangle `f(xᵢ)·Δx` is a tiny "rate × interval = small amount," and summing infinitely
many of them gives the grand total. "Area under the curve" is just the geometric face of this single,
enormously useful idea — adding up a continuously changing quantity.

---

## 6. The shortcut you graduate to: the Fundamental Theorem

This game computes areas the **honest** way — by summing rectangles (a fine Riemann sum under the
hood). In a calculus course you eventually learn the spectacular shortcut, the **Fundamental Theorem
of Calculus**: to get the exact area, find an **antiderivative** `F` (a function whose derivative is
`f`) and just subtract its endpoint values:

```
        ⌠ b
        ⎮   f(x) dx   =   F(b) − F(a)
        ⌡ a
```

For example, an antiderivative of `f(x) = x²` is `F(x) = x³/3`, so the area from 0 to 3 is
`F(3) − F(0) = 27/3 − 0 = 9` — and indeed, crank n high enough in the game and your estimate of
`x²` on `[0, 3]` settles on **9**. The theorem ties the two halves of calculus together: it says
**integration (accumulating area) and differentiation (measuring rate) are inverse operations.** But
the *definition* — and the intuition this game is built to give — is always the limit of the
rectangles. The shortcut is a gift; the rectangles are the truth.

---

## Association verdict

**Strong tie to the infinities scale.** The infinities scale is about quantities that only make sense
*in the limit* — the unbounded, the infinitely-divided, the infinite sum. The definite integral is
the canonical infinite sum: take a region, slice it into infinitely many infinitesimal pieces, and
add them all up. The game makes that abstraction physical — you literally drive `n` toward infinity
with your thumb and watch a finite, rough guess become an exact area. There is no better embodiment
of "infinity, made useful" on this scale.
