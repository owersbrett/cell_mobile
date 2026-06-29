# Converge — EDUCATION.md

**Concept:** limits, convergent vs divergent infinite series, Zeno's paradox.
**Scale:** Infinities. The lesson is *in the mechanic* — you read the fate of a
series from its partial sums, which is exactly what a mathematician does.

## The big idea: a limit is where the partial sums settle
An infinite series `a₁ + a₂ + a₃ + ⋯` is judged by its **partial sums**:
`Sₙ = a₁ + a₂ + ⋯ + aₙ`. The series **converges** if the sequence `S₁, S₂, S₃, …`
approaches a single finite value `L` (the **limit / sum**); it **diverges** if the
partial sums grow without bound or never settle. The chart in Converge *is* the
sequence of partial sums — the dashed line on reveal is `L`.

## Zeno's paradox, resolved
To cross a room you first go ½, then ¼, then ⅛, … infinitely many steps. Zeno
said you could never finish. But `½ + ¼ + ⅛ + ¹⁄₁₆ + ⋯ = 1`: infinitely many
terms add to a **finite** distance. You arrive. Converge makes you watch that
sum close on 1 — an infinite process with a finite limit.

## The families you'll judge
- **Geometric** `a·rⁿ`: **converges iff |r| < 1**, to `a/(1−r)`. Halves (`r=½`)
  converge; doubling (`r=2`) explodes; `r=−½` converges while alternating.
- **Harmonic** `1 + ½ + ⅓ + ¼ + ⋯`: **diverges** — the headline counter-intuition.
  Terms shrink to 0, yet the sum is infinite (it just grows ever more slowly).
- **p-series** `Σ 1/nᵖ`: **converges iff p > 1.** So `1/n²` converges (Euler's
  `π²/6`) but `1/√n` (p=½) and `1/n` (p=1) diverge.
- **Alternating** (signs flip): the alternating harmonic `1 − ½ + ⅓ − ⋯ = ln 2`
  converges even though the plain harmonic does not — cancellation tames it.
- **Telescoping** `Σ 1/(n(n+1)) = 1`: terms collapse pairwise to a clean limit.
- **Oscillating** (Grandi `1 − 1 + 1 − ⋯`): partial sums bounce 1,0,1,0 and never
  settle → **diverges** (no limit), even though it stays bounded.

## The key trap the game teaches
**Terms going to zero is necessary but NOT sufficient for convergence.** The
harmonic series has `aₙ → 0` and still diverges. That's why a slow climb on the
chart can fool you — Converge rewards learning to tell "leveling off" from
"slowing down but never stopping."

## What "accelerate" teaches
Early rounds are obvious; late rounds are subtle and fast, forcing you to read
convergence from the *shape and rate* of the partial sums rather than waiting for
a verdict — the intuition behind comparison and ratio tests.
