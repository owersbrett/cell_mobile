# Superposition v2 — Manual (M)

> UX-passed alternative to `superposition`. Same quantum-measurement lesson,
> dialed-up fun. Ships as a sibling spec (`superposition_v2`) so both are
> A/B-comparable in-app.

## One-liner
A qubit oscillates between |↑⟩ and |↓⟩. Ride the wave up to the glowing pole and
**measure inside the LOCK zone** — there the favorable collapse is *guaranteed*
and your score scales with how high you dared to hold. Below the lock zone it is
an honest coin-flip you chose to gamble on.

## Scale
`BioScale.multiverseAll` · scoreUnit: `collapses` · ~55s.

## Rules
1. The qubit's probability of landing the **glowing target pole** sweeps 0→100%.
   The **state vector** on the sphere reaches toward that pole — its tip height
   *is* P(target). The fuzzy cloud at the tip is the uncertainty: fat at the
   50/50 equator, a sharp point at the crest.
2. A glowing **LOCK ZONE** caps the target pole (P(target) ≥ 86%). When the
   vector enters it the sphere flares and the prompt reads **LOCK — MEASURE!**
3. **Tap to MEASURE.** Inside the lock zone the favorable outcome is
   **GUARANTEED** — perfect timing is never robbed. Your points scale with the
   exact probability you held for, so riding to the crest (near 100%) is worth
   meaningfully more than the lip of the zone.
4. **Gamble below the zone (optional):** measure before lock and it is an honest
   weighted collapse — you might land it for reduced points, or **DECOHERE** and
   break your streak. The "measure at 50/50 = coin-flip" lesson lives here.
5. **Climax — Coincidence Cascade (last 12s):** a second qubit joins, phases
   drift apart, and the wave accelerates, so a moment where *both* vectors sit in
   their lock zones at once is rare and brief. The joint multiplier is huge.

## How to win
Most banked collapses when time runs out wins. (Pass-and-play: every player faces
the same wave physics; outcomes in the lock zone are deterministic, so the
standing reflects timing skill, not luck.)

## Scoring
- **Single qubit, locked:** `round(120 · P^1.6)` + `5·streak`. Crest ≈ 117+.
- **Coincidence (2 qubits), locked:** `round(320 · joint^1.3)` + `8·streak`,
  ×1.5 during the climax. Both near-crest ≈ 280→420.
- **Gamble that lands (below lock):** same formula at the lower P → fewer points.
- **Decohere (gamble missed):** 0, streak resets.

## Tuning
`humanMax: 3400`, `starThresholds: [1000, 2000, 3000]`.
