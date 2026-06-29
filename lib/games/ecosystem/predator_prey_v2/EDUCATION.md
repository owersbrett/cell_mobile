# Predator & Prey v2 — Education (E)

## The lesson (unchanged from v1, made visceral)
This game IS the **Lotka–Volterra predator–prey model** — the foundational
equations of population ecology — turned into something you can watch and feel.

### The coupled boom–bust loop
The whole teach is one cycle, and you SEE it in the herds:
1. **Hares boom** — prey grow toward carrying capacity (the field fills green).
2. **Lynx boom** — abundant food lets predators multiply (orange swarms in).
3. **Hares crash** — too many predators eat the prey down (green is hunted away).
4. **Lynx starve** — with no food, predators die back (orange dwindles).
5. **Hares recover** — freed from pressure, prey rebound — and it repeats.

The on-screen phase label names exactly which quadrant of the cycle you're in:
**BOTH RISING / PREY CRASHING / PREDATORS STARVING / PREY RECOVERING.**

### Concepts in the mechanic (not in a text wall)
- **Carrying capacity (K):** hares can't grow forever — the logistic ceiling is
  drawn as the field's "fullness" wash and a K line. The `(1 − x/K)` term is in
  the integrator.
- **Coupling:** predators have no food source of their own — cut the prey and the
  predators follow them down. You feel that dependency every round.
- **Trophic cascade:** the late **HAWKS** prey on the lynx, so protecting hawks
  indirectly protects hares (fewer lynx) — a three-level food chain.
- **Carrying both:** the score rewards keeping BOTH alive AND near equilibrium —
  the real ecological goal of a stable ecosystem, not maximizing one species.
- **Stochastic shocks:** droughts, disease and blooms knock the system off
  balance — real populations never sit still at equilibrium.

### What the player internalizes
That a predator and its prey are **one coupled system**: you can't manage either
in isolation, overshoots cause crashes, and stability is a dynamic balance you
steer — not a fixed point you set once. The ECOSYSTEM HEALTH dial makes "is this
ecosystem stable right now?" a single readable signal.

## Real-world / Potatuhs tie-in
Wildlife managers face this exact coupling (the classic Canada lynx / snowshoe
hare records show the ~10-year cycle). A potato farm is the same math one level
down: a pest population and its natural predator boom and bust, and spraying one
ripples through the other.
