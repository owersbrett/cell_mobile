# GAME.md — Decay Chain

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** particles
- **Game id:** decay_chain
- **One-line concept:** An unstable particle sits in the detector with a shrinking fuse. When it
  decays it bursts into product particles that fly outward — **tap the real products before they
  escape, refuse the impostor that would violate conservation of charge.**
- **Role:** solo high-score (timed)
- **Six-in-one?** no

## Lore (learn the decays)
Unstable particles don't last. A free neutron β⁻-decays to `p⁺ + e⁻ + ν̄`; a muon decays to
`e⁻ + ν + ν̄`; a negative pion decays to `μ⁻ + ν̄` — and that muon then decays again, a real
multi-step chain (`π⁻ → μ⁻ → e⁻`). Every genuine decay **conserves charge**: the product charges
sum to the parent's. The detector occasionally throws in an impostor product that does NOT belong;
catching it breaks conservation and costs you. The catching game is the toy; reading the equation
and the charges is the teaching.

## Rules (canonical — as implemented in `DecayChainGame`)
1. A parent particle sits in the centre with a decay fuse arc winding down (lime → red).
2. On decay it **bursts into products** that fly out radially. The decay equation is shown up top.
3. **Tap a real product** before it escapes the detector: **+10**.
4. **Tap the impostor** (a particle not in the equation): **−12**, streak reset.
5. **Let a real product escape:** **−5**, the decay can no longer be clean.
6. **Catch every real product with no impostor and no escape → CLEAN DECAY:** **+25 and up** (rises
   with streak), and the streak counter ticks up.
7. **Multi-step chain:** catching an unstable product (a muon or pion) makes it **decay again** where
   you caught it — more products, more points.

## Controls
Tap the flying products. Canvas-drawn only — detector ring, fuse arcs, charge-coloured orbs
(blue −1 / orange +1 / grey 0), motion trails, decay bursts, score pops. No raster assets.

## Scoring
- Real product caught: **+10**. Clean decay: **+25 + min(streak,10)×3**.
- Impostor caught: **−12** (streak reset). Real product escaped: **−5**.
- `scoreUnit` = "particles". Score counts the matter you caught.

## Win / end condition
Timed score attack (~50 s). Most particles caught when the reactor cools wins.

## Difficulty curve
Ramps on play-time: shorter fuses (1.5 → 0.8 s), shorter gaps between decays (1.6 → 0.7 s), faster
products (×72 → ×150), and a higher impostor rate (25% → 70%, with a chance of a second impostor
past the halfway mark). Multi-step chains add their own bursts on top.

## Educational blocks engaged
- Particle decay, decay products, and **conservation of charge** — taught *in the mechanic*: you
  read the equation and the charge colours to decide what to catch. Multi-step decay (`π → μ → e`)
  is shown by the chain. See `EDUCATION.md`.

## Potato angle
Light — the subatomic churn that ultimately settles into the atoms of a potato. Don't force it.

## Session / resume
Stateless across runs by design: the host owns the clock; `_started` re-arms on intro/countdown and
a fresh run reseeds the reactor. Persist only final score (host-side). A session can close and a
clean fresh one re-enter — the S in GAMES.

## Implementation
- `lib/games/particles/decay_chain/decay_chain_game.dart` (`DecayChainGame`).
- One `Ticker` → one `CustomPainter`; play state in `_Pending` / `_Product` / `_Batch` data objects.
- Imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, flutter (per EXTRACTION_RECIPE).
