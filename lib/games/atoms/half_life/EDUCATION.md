# EDUCATION.md — Half-Life

> The educational component (the **E** in GAMES). What the game teaches and how the *mechanic itself*
> carries the lesson — not a quiz bolted on, but learning the player can't help absorbing by playing.

**Scale:** Atoms · **Topic:** radioactive decay, half-life, exponential curves

---

## The one idea

**Half-life is the time for half of a radioactive sample to decay — and it's constant.** Start with
any amount; after one half-life, half is left; after another, a quarter; then an eighth. The amount
remaining follows a pure exponential, `N(t) = N₀ · 2^(−t / t½)`, that halves forever and never quite
hits zero.

Two truths sit on top of each other:
- **Which** atom decays next is genuinely, irreducibly random.
- **How many** have decayed by a given time is almost perfectly predictable.

Most learners hold only one of these. The game makes you hold both.

---

## How the mechanic teaches it

The lesson is not narrated — it's the win condition.

1. **You wait for "half gone."** To score, you must internalize what one half-life *looks like*: the
   glow grid thinned to about 18 of 36. You are literally rewarded for correctly estimating the 50%
   point — that's the definition of half-life, practiced as a reflex.

2. **The ladder makes the exponential physical.** Later rounds ask for 25% (two half-lives) and
   12.5% (three). The player discovers, by doing, that each extra half-life *halves again* — not
   "subtracts the same amount." The most common misconception about decay (that it's linear) is
   impossible to hold while playing, because the second half-life visibly removes only half as many
   atoms as the first.

3. **Random flicker, lawful count.** Which atoms go dark is random every round, but the count always
   lands on the curve. The live `STILL RADIOACTIVE: k / 36` readout and the drawn `2^−n` curve sit
   side by side, so the player sees order emerging from randomness.

4. **The curve is the feedback.** On every measurement the cursor freezes on the exponential curve
   next to the target ring — "you read 41%, target 50%." Error is taught geometrically, on the exact
   shape being learned.

5. **Acceleration deepens it.** Shorter half-lives prove the *shape* is invariant even as the
   *timescale* changes — a fast isotope and a slow one trace the same curve, just at different speeds.

---

## Real-world anchors (the WOW)

The half-lives in the game are abstract seconds, but they map to real isotopes spanning 18 orders of
magnitude:

| Isotope | Half-life | Why it matters |
|---|---|---|
| **Carbon-14** | 5,730 years | Radiocarbon dating — how we date ancient organic matter (incl. a charred potato) |
| **Iodine-131** | 8 days | Medical — thyroid imaging and treatment; short enough to clear the body |
| **Cobalt-60** | 5.27 years | Cancer radiotherapy and food irradiation |
| **Uranium-238** | 4.5 billion years | Dating the age of the Earth itself |
| **Polonium-214** | 0.16 milliseconds | Some nuclei decay almost the instant they form |

Same law, same curve — only the clock speed changes. That's the point the acceleration ramp drives
home.

---

## Misconceptions corrected

- ❌ "Decay is linear — the same number decay each second." → The 25% and 12.5% rounds make the
  halving visible: the second half-life removes half as many as the first.
- ❌ "After two half-lives it's all gone." → It's a quarter left, not zero. Exponentials never reach
  zero.
- ❌ "You can predict which atom decays." → You can't; the flicker is random. You can only predict the
  count.
- ❌ "Bigger samples last longer." → Half-life is independent of sample size; half of *any* amount
  goes in one half-life.

---

## Potato tie-in

A potato is mostly carbon, and a fixed fraction of that carbon is radioactive Carbon-14, ticking down
on a 5,730-year half-life. Char a potato in an ancient hearth and that clock is how archaeologists
date it. Same exponential the player just raced — slowed to millennia.

---

## One-sentence takeaway

*Half of a radioactive sample is gone after one half-life, a quarter after two, an eighth after
three — the shape is always the same exponential, no matter the isotope or how big the pile.*
