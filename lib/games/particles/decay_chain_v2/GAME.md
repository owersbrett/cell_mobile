# GAME.md — Decay Chain v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> A UX-refinement-pass rebuild of `decay_chain` (see `docs/ux_pass/teardowns/decay_chain.md`).

- **Scale (cell):** particles
- **Game id:** decay_chain_v2
- **One-line concept:** An unstable particle sits in the detector with a shrinking fuse. When it
  decays it bursts into product particles that fly outward — **tap the real products before they
  escape, refuse the ✗ impostor that would violate conservation of charge.**
- **Role:** solo high-score (timed)
- **Six-in-one?** no

## Lore (learn the decays)
Unstable particles don't last. A free neutron β⁻-decays to `p⁺ + e⁻ + ν̄`; a muon decays to
`e⁻ + ν + ν̄`; a negative pion decays to `μ⁻ + ν̄` — and that muon then decays again, a real
multi-step chain (`π⁻ → μ⁻ → e⁻`). Every genuine decay **conserves charge**: the product charges
sum to the parent's. The detector occasionally throws in an impostor product that does NOT belong;
catching it breaks conservation and costs you. The catching game is the toy; reading the equation
and the charges is the teaching.

## What v2 changed (the UX pass)
1. **Impostor tell is readable under motion.** The old faint 12 Hz flicker ring is replaced by a
   **bold slow-pulsing segmented red ring + a red ✗ "violates charge" badge**. Refusing it is now a
   skill (read it fast under load), not a guess.
2. **Charge legibility + tell-fade.** Every product carries a big **+/−/0 charge badge** early — the
   novice aid — that **fades over the first 45 %** of the run, leaving the bare physics symbol. The
   late game is the knowledge test; the opening is approachable. Real products also wear a soft green
   "belongs" halo early that fades the same way.
3. **Equation HUD chips.** The decay equation renders as charge-coloured chips; a product chip
   **lights** when a live real product of that kind is in flight — tying the flying orb to the
   equation.
4. **MELTDOWN climax.** The final window (`_prog ≥ 0.76`) fires the **fastest fuses**, the fastest
   respawns, a pulsing red edge-vignette, and a **catch-combo multiplier** (bounded ≤ ×2) — the ramp
   resolves into a read-from-across-the-room finish beat.
5. **Spectator standing.** Big centred milestone flashes (`CLEAN ×N`, `⚠ MELTDOWN`) and a live
   `COMBO ×N` readout during meltdown.

## Rules (canonical — as implemented in `DecayChainV2Game`)
1. A parent particle sits in the centre with a decay fuse arc winding down (lime → red).
2. On decay it **bursts into products** that fly out radially. The decay equation is shown up top.
3. **Tap a real product** before it escapes the detector: **+10** (more in meltdown via combo).
4. **Tap the ✗ impostor** (a particle not in the equation): **−12**, streak + combo reset.
5. **Let a real product escape:** **−4**, the decay can no longer be clean.
6. **Catch every real product with no impostor and no escape → CLEAN DECAY:** **+20 and up** (rises
   with streak), and the streak counter ticks up.
7. **Multi-step chain:** catching an unstable product (a muon or pion) makes it **decay again** where
   you caught it — more products, more points.
8. **Meltdown (final window):** fuses/respawns at their fastest; consecutive catches build a combo
   that multiplies catch points up to **×2**.

## Controls
Tap the flying products. Canvas-drawn only — detector ring, fuse arcs, charge-coloured orbs
(blue −1 / orange +1 / grey 0), charge badges, segmented ✗ impostor rings, motion trails, decay
bursts, score pops, meltdown vignette. No raster assets.

## Scoring
- Real product caught: **+10** (×1→×2 during meltdown combo). Clean decay: **+20 + min(streak,8)×4**.
- Impostor caught: **−12** (streak + combo reset). Real product escaped: **−4**.
- `scoreUnit` = "particles". Score counts the matter you caught.

## Win / end condition
Timed score attack (~52 s). Most particles caught when the reactor melts down wins.

## Difficulty curve
Ramps on play-time: shorter fuses (1.5 → 0.8 s, ×0.7 in meltdown), shorter gaps between decays
(1.6 → 0.75 s, ×0.66 in meltdown), faster products (×70 → ×150), a higher impostor rate (22 % →
65 %, second impostor past halfway), and the **fading novice aid** (charge badges + belongs halo).
Multi-step chains add their own bursts on top; the meltdown window is the crescendo.

## Educational blocks engaged
- Particle decay, decay products, and **conservation of charge** — taught *in the mechanic*: you
  read the equation and the charge colours/badges to decide what to catch. Multi-step decay
  (`π → μ → e`) is shown by the chain. See `EDUCATION.md`.

## Potato angle
Light — the subatomic churn that ultimately settles into the atoms of a potato. Don't force it.

## Session / resume
Stateless across runs by design: the host owns the clock; `_started` re-arms on intro/countdown and
a fresh run reseeds the reactor (clearing meltdown/streak/combo). Persist only final score
(host-side). A session can close and a clean fresh one re-enter — the S in GAMES.

## Implementation
- `lib/games/particles/decay_chain_v2/decay_chain_v2_game.dart` (`DecayChainV2Game`).
- One `Ticker` → one `CustomPainter`; play state in `_Pending` / `_Product` / `_Batch` data objects.
- Imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, flutter (per EXTRACTION_RECIPE).
