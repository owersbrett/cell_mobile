# EDUCATION.md — Lensing

> The educational component (the **E** in GAMES). What the player actually learns,
> why the mechanic teaches it, and the facts behind the fantasy.

---

## One-sentence takeaway

**Mass bends light** — so a clump of matter between us and a distant galaxy acts
like a lens, smearing the galaxy into arcs and rings, and we use that bending to
**map matter we can't otherwise see**, including invisible dark matter.

---

## The core idea: gravity curves spacetime, light follows the curve

In Einstein's general relativity, mass and energy **curve spacetime**, and light
always travels the straightest available path through it (a *geodesic*). Near a
massive object that "straightest path" is itself curved, so a passing light ray is
**deflected** toward the mass. The Sun bends starlight passing its edge by about
**1.75 arcseconds** — a tiny angle famously measured during the **1919 solar
eclipse**, the first confirmation of general relativity.

The deflection angle for light grazing a mass `M` at closest distance (impact
parameter) `b` is:

```
α  =  4·G·M / (c²·b)
```

Two things to read off this, and **both are the game's two controls**:

- **More mass → more bending** (`α ∝ M`). → the **MASS bar**.
- **Closer pass → more bending** (`α ∝ 1/b`). → the **halo position** (impact
  parameter). Slide the halo nearer the beam and the rays bend harder.

The game's ray sim is this law in miniature: each ray's direction curves toward the
halo with strength `∝ mass / distance²` and is renormalised every step (light keeps
its speed and only changes direction). Get mass and position right and the rays
**focus** onto the detector. Wrong on either — too little, too much, or off to the
side — and they miss. That under-bend / over-bend feel is the equation made playable.

---

## Gravitational lensing: arcs, rings, and multiple images

When a massive object (a galaxy or a whole galaxy cluster — the **lens**) sits
almost directly between us and a more distant galaxy (the **source**), its gravity
bends the source's light around it. Depending on the alignment we see:

- **Arcs** — the source smeared into curved streaks.
- **Multiple images** — the same galaxy appearing in two, four, or more places.
- **An Einstein ring** — with near-perfect alignment, the light is bent around
  *every* side and we see the source smeared into a **complete ring**.

The characteristic size of that ring is the **Einstein radius**, which depends on
the lens mass and the distances involved — so measuring the ring **weighs the
lens**. The game's two-galaxy round is exactly this: two background sources placed
symmetrically about the detector, focused by **one** halo into a ring-like
convergence — a hand-built Einstein ring.

Strong lensing (rings, arcs, multiple images) needs tight alignment; **weak
lensing** is the far more common subtle stretching of millions of background
galaxies, averaged statistically to map the lens's mass across the sky.

---

## Why this maps the invisible: dark matter

Here's the payoff. Lensing responds to **all** mass — it doesn't care whether the
mass emits light. When astronomers map the mass of a galaxy cluster from how much it
lenses background galaxies, they find **far more mass than the visible stars and gas
can account for** — typically about **five to six times** more. That unseen mass is
**dark matter**: it neither emits nor absorbs light, and we know it's there largely
*because of how it bends light*.

The famous example is the **Bullet Cluster**: two clusters that collided. The hot
gas (most of the *visible* mass) was slowed and left in the middle, but the lensing
map shows the **bulk of the mass sailed straight through, separated from the gas** —
the cleanest evidence that most of the matter is dark and collisionless. Lensing is
the tool that drew that map.

So in the game the thing you control is **invisible** on purpose — you see only its
warp and its effect on the light. That's not a stylistic choice; it's the actual
scientific situation. You are doing, in cartoon form, what cosmologists do for real:
**inferring an unseen mass from the way it bends light.**

---

## Fact check (the load-bearing claims)

- Light deflection by the Sun ≈ **1.75 arcsec**; confirmed at the **1919** eclipse
  (Eddington). ✔
- Light-bending angle `α = 4GM/(c²b)` — twice the value Newtonian "corpuscle"
  gravity would give; the factor-of-2 is the general-relativistic signature. ✔
- Strong lensing produces **arcs, multiple images, and Einstein rings**; ring size
  (Einstein radius) measures the lens mass. ✔
- Dark matter is **~5–6×** the mass of ordinary (baryonic) matter; lensing is a
  primary way it's mapped, with the **Bullet Cluster** the canonical demonstration. ✔

---

## What the player should walk away saying

> "Heavy stuff bends light, so if I put the right amount of invisible mass in the
> right spot, I can curve a galaxy's light onto my telescope — and that's literally
> how astronomers find dark matter: by the way it warps the light behind it."
