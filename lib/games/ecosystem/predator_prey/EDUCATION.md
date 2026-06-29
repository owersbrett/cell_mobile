# EDUCATION.md — Predator & Prey (ecosystem)

> The educational payload of this game and how the mechanic *is* the lesson.
> Scale: ecosystem. The learning arc: organism → **populations of organisms interacting** → the
> dynamics that keep (or fail to keep) a food web alive.

- **Scale (cell):** ecosystem
- **Game:** `predator_prey` — canonical ecosystem-dynamics game, strong edu tie.

---

## The core idea — you cannot learn this from a static diagram

A textbook draws predator/prey balance as a tidy pair of sine waves. The thing that does NOT survive
the diagram is the *feel*: that the predators always peak AFTER the prey, that a balanced system is
balanced on a knife edge, and that "just add more of the thing that's low" often makes it worse a
cycle later. This game teaches by **putting your hands on the levers** of a live Lotka–Volterra system.

---

## Blocks

| Block | Title | Taught by the mechanic | Strength |
|---|---|---|---|
| Lotka–Volterra cycle | The coupled boom-bust | The sim runs the actual ODEs; the phase label names each quadrant as you watch | ✅ |
| Carrying capacity (K) | The land's limit | Hares grow toward K=170, the labelled gold line; they physically can't run away | ✅ |
| Predator lag | Predators peak after prey | Visible on the two-line graph — the orange peak always trails the green peak | ✅ |
| Trophic cascade | Tiers ripple | Hawks→lynx→hares; cull one tier and the others move a cycle later | ✅ |
| Perturbation & resilience | Shocks vs. recovery | Drought/disease/bloom knock the system; you feel whether it bounces back or spirals | ✅ |

### Strength notes

**Lotka–Volterra cycle ✅** — The two equations are not decoration; they ARE the game state. Prey
grow logistically and are eaten (`−β·H·L`); predators grow only by eating (`+δ·β·H·L`) and otherwise
die (`−γ·L`). The four-quadrant phase label (`BOTH RISING → PREY CRASHING → PREDATORS STARVING →
PREY RECOVERING`) is read straight off the sign of each derivative, so the player literally watches
the cycle turn.

**Carrying capacity ✅** — The logistic `(1 − H/K)` term is made visible as the labelled K line.
Players learn that prey don't grow without bound: a hare bloom flattens against the ceiling, which is
*why* a predator boom that follows can crash it so hard.

**Predator lag ✅** — The single most counter-intuitive fact in the topic — predators peak after prey
— is unmissable on the graph: the orange line's crest always sits to the right of the green line's.

**Trophic cascade ✅** — Once hawks arrive, removing lynx (to save hares) starves the hawks; letting
lynx boom (to feed hawks) crashes the hares. Three coupled tiers make "you can't optimise one in
isolation" a felt constraint, not a slogan.

---

## How the education *accelerates* (it's in the difficulty curve)

The brief requires the learning to ride the difficulty ramp, not sit beside it:

- **Faster cycles** (time-scale 1.0×→2.3×) compress the boom-bust loop so the player internalises the
  *shape* by repetition.
- **Sharper predation** (β up to +50%) turns gentle waves into near-extinction crashes — the same
  lesson at higher stakes.
- **Accelerating shocks** teach resilience: a system near equilibrium shrugs off a drought; one already
  swinging wildly gets tipped into collapse by the same shock.
- **The third species** (hawks) is a genuine new concept delivered late — the trophic cascade — once
  the two-body cycle is intuitive.

So the player who lasts longest has, by necessity, learned to read the cycle, respect carrying capacity,
and damp the oscillation instead of chasing it.

---

## Potato angle

A potato field is the producer at the bottom of this exact web. Herbivores (the "hares" here) eat the
crop; predators (lynx, hawks) hold the herbivores down. Wipe out the predators and you get a herbivore
boom that eats the harvest; that is why monoculture pest-spraying so often backfires, and why
predator/prey balance — not eradication — is the heart of integrated pest management. Playing the
warden of a balanced web is rehearsing the instinct that keeps a real field productive.

---

## Association verdict

**KEEP — the definitive ecosystem-scale game.** No static screen can teach predator lag, carrying
capacity, and trophic cascade the way a hands-on Lotka–Volterra sandbox does. The mechanic and the
curriculum are the same object.
