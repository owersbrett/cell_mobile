# Superposition v2 — Education (E)

## The lesson (preserved from v1)
1. **Superposition.** Before measurement a qubit is not "secretly up or down" —
   it is genuinely in a blend of both states |↑⟩ and |↓⟩. The blend evolves in
   time; here the probability of measuring the target sweeps
   `P(target) = ½ + ½·sin(phase)` between 0 and 1. The oscillating state vector
   on the sphere *is* that evolving wavefunction.
2. **Measurement collapses it.** Tapping MEASURE forces the qubit to pick one
   definite outcome. The chance of each outcome equals its current probability
   (the **Born rule**) — that is why measuring when the wave favors your target
   (P near 1) lands it, and measuring at the 50/50 equator is a true coin-flip.
3. **Uncertainty is real.** The tip cloud is sized by the variance `P(1−P)`: it
   is largest at the equator (maximum uncertainty) and collapses to a point at
   the poles (a near-certain state). You can *see* certainty grow as the vector
   climbs.
4. **Joint amplitudes multiply.** With two qubits the chance of landing *both*
   targets is the **product** of their probabilities (`joint = P₀ · P₁`). That is
   why a coincidence — both waves cresting at once — is rare and precious.

## What the v2 design teaches better
- The **lock zone** dramatizes the Born rule's edge case: near P=1 the outcome is
  effectively certain, so the game *guarantees* it. This keeps the physics honest
  (high probability ⇒ reliable) while removing the unfair feeling of losing a 95%
  read to a bad roll. The gamble below the zone preserves the genuine randomness
  of mid-superposition measurement for anyone who chooses it.
- The **uncertainty cloud** (variance P(1−P)) makes an abstract idea visible:
  superposition is most "fuzzy" in the middle and sharpest at the poles.
- The **coincidence cascade** makes the multiplication of amplitudes felt — two
  independent waves rarely align, so joint certainty is hard-won.

## One-sentence takeaway
A quantum state is a wave of possibilities; measuring snaps it to one outcome with
the probability the wave is showing — so to win you wait for the wave to crest.
