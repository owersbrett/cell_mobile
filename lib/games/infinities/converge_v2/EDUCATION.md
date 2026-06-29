# Converge v2 — EDUCATION.md

**Concept:** limits, convergent vs divergent infinite series, Zeno's paradox.
**Scale:** Infinities. The lesson is *in the mechanic* — you read the fate of a
series from its partial sums, which is exactly what a mathematician does. v2
preserves the entire lesson; it only **lowers the entry floor**.

## The big idea: a limit is where the partial sums settle
An infinite series `a₁ + a₂ + a₃ + ⋯` is judged by its **partial sums**:
`Sₙ = a₁ + a₂ + ⋯ + aₙ`. The series **converges** if the sequence `S₁, S₂, S₃, …`
approaches a single finite value `L` (the **limit / sum**); it **diverges** if the
partial sums grow without bound or never settle. The chart *is* the sequence of
partial sums — the dashed line on reveal is `L`.

## Zeno's paradox, resolved
To cross a room you first go ½, then ¼, then ⅛, … infinitely many steps. Zeno
said you could never finish. But `½ + ¼ + ⅛ + ⋯ = 1`: infinitely many terms add
to a **finite** distance. You arrive — an infinite process with a finite limit.

## The families you'll judge
- **Geometric** `a·rⁿ`: **converges iff |r| < 1**, to `a/(1−r)`. Halves (`r=½`)
  converge; doubling (`r=2`) explodes; `r=−½` converges while alternating.
- **Harmonic** `1 + ½ + ⅓ + ¼ + ⋯`: **diverges** — the headline counter-intuition.
  Terms shrink to 0, yet the sum is infinite (it just grows ever more slowly).
- **p-series** `Σ 1/nᵖ`: **converges iff p > 1.** `1/n²` converges (Euler's
  `π²/6`) but `1/√n` (p=½) and `1/n` (p=1) diverge.
- **Alternating**: the alternating harmonic `1 − ½ + ⅓ − ⋯ = ln 2` converges even
  though the plain harmonic does not — cancellation tames it.
- **Telescoping** `Σ 1/(n(n+1)) = 1`: terms collapse pairwise to a clean limit.
- **Oscillating** (Grandi `1 − 1 + 1 − ⋯`): partial sums bounce 1,0,1,0 and never
  settle → **diverges**, even though bounded.

## The key trap the game teaches
**Terms going to zero is necessary but NOT sufficient for convergence.** The
harmonic series has `aₙ → 0` and still diverges. That's why a slow climb on the
chart can fool you.

## How v2 teaches the read without giving the answer
- The **fading coach cue** names the *heuristic*, not the verdict: it points at
  the **rate of shrink** ("terms HALVE" vs "shrink TOO SLOWLY", "signs FLIP",
  "never reach ZERO"). The player still has to map cue → call. It is the exact
  intuition behind the comparison and ratio tests, handed over as an on-ramp and
  then withdrawn as difficulty climbs.
- The **honest trend readout** (reference line + ↑rising/≈leveling tag) trains
  the distinction the harmonic series exists to teach: *leveling off* vs *slowing
  down but never stopping*. It reads the real partial-sum slope, so the chart and
  the correct answer never fight.
- **Accelerate / final burst**: late rounds are subtle and fast, forcing you to
  read convergence from the shape and rate of the partial sums, not a verdict.
