# Half-Life v2 — Education (E)

## The lesson
**Radioactive decay is exponential, and the half-life is a constant time.**

- Start with a full sample (100% radioactive).
- After one half-life, **half** remains (50%).
- After two, half of that (25%). After three, 12.5%. The amount keeps halving;
  it never reaches zero on a fixed schedule.
- Crucially: **each halving takes the same amount of time.** Going 100→50%
  takes exactly as long as 50→25% and 25→12.5%. That constant interval *is* the
  half-life.

## How the mechanic teaches it
- **You estimate, you don't read.** The sample is a fuzzy glow cloud with no
  counter, so you have to *feel* "half the glow is gone" — building real
  intuition for the fraction instead of reading an integer (the original's
  flaw). The true % is revealed only after you commit a tap.
- **The rhythm is the curve.** Because every halving is the same time apart,
  once you nail the first measurement the next two fall on a steady beat. Players
  physically feel that half-life = a fixed tempo, not a fixed *amount* lost.
- **Randomness vs. statistics, shown at once.** Under the hood each atom decays
  at its own random threshold — *which* atom goes dark is unpredictable — yet the
  whole cloud's brightness tracks `100% · 2^(−t/t½)` precisely. Individual chaos,
  population order.
- **The curve makes it explicit.** The on-screen `2^−n` curve with rings at
  50/25/12.5% is the textbook decay graph; your frozen tap markers land on it so
  you see how close your feel was to the math.

## Real-world hook
This is carbon-14 dating, medical isotope dosing, and nuclear-waste timelines:
predicting "how much is left after N half-lives" is the same skill the game
drills. Half-life is why "it'll be safe in a few half-lives" is a real sentence.
