# EDUCATION.md — Decay Chain

> The E in GAMES. The teaching is **in the mechanic** — you cannot score well without reading the
> decay equation and the charge colours. Difficulty accelerates the same lesson, it doesn't bolt a
> quiz on the side.

## The big idea
Unstable particles **decay** into lighter particles, and every real decay obeys **conservation
laws** — most visibly **conservation of electric charge**: the charges of the products add up to the
charge of the parent. The game makes you *use* that fact: the impostor is exactly the particle that
would make the charges fail to balance, and refusing it is how you win.

## What the player actually learns
1. **Decay products.** Each parent shows its real decay as an equation at the top of the screen:
   - Free neutron (β⁻ decay): `n⁰ → p⁺ + e⁻ + ν̄`
   - Muon: `μ⁻ → e⁻ + ν + ν̄`
   - Negative pion: `π⁻ → μ⁻ + ν̄`
2. **Conservation of charge.** Orbs are coloured by charge — **blue = −1, orange = +1, grey = 0**.
   Add the product charges and you get the parent's charge every time:
   - `n⁰`(0) → `p⁺`(+1) + `e⁻`(−1) + `ν̄`(0)  →  +1 − 1 + 0 = **0** ✓
   - `μ⁻`(−1) → `e⁻`(−1) + `ν`(0) + `ν̄`(0)  →  −1 + 0 + 0 = **−1** ✓
   - `π⁻`(−1) → `μ⁻`(−1) + `ν̄`(0)  →  −1 + 0 = **−1** ✓
   The **impostor** is a particle that is not in the equation; catching it would add a charge that
   doesn't belong — a conservation violation — so it costs you.
3. **Multi-step decay chains.** A pion's muon is *itself* unstable, so catching it triggers a second
   decay in place: `π⁻ → μ⁻ → e⁻`. This is how real cascades work — one decay feeds the next.
4. **Neutrinos are real, faint, and chargeless.** They appear (`ν`, `ν̄`) as neutral grey products
   that carry away energy and momentum — the reason beta decay needed a neutrino to balance the books.

## Why it's honest
- The decays shown are real Standard-Model decays; the charges are real; the chain `π → μ → e` is a
  textbook example.
- Nothing is invented to make the game work — the mechanic is a thin, playable shell around the
  actual conservation rule.

## Acceleration
As the run progresses, decays fire faster and impostors get more frequent — so the player has to read
charge faster and trust the conservation check under pressure. Same lesson, higher tempo.
