# Branch v2 — Potatuhs notes

Part of the **GAMES** rubric pass (Summer · hotpotatogames · cycle 1/3). This is
the UX-refinement alternative to `branch`, built to the Fun-Multiplayer UX bar
in `docs/UX_REFINEMENT_PASS.md` against the teardown in
`docs/ux_pass/teardowns/branch.md`.

## GAMES coverage
- **G** — `branch_v2_game.dart` (`BranchV2Game`), a playable mini-game widget.
- **A** — `AGENT.md` (owning agent + invariants).
- **M** — `GAME.md` (rules manual).
- **E** — `EDUCATION.md` (many-worlds: branching, amplitude/Born weight,
  decoherence, the coherence/resonance tradeoff).
- **S** — Session: host owns the clock; the tree only advances while
  `session.isRunning`, so a run closes and a fresh one re-enters cleanly.

## Teardown → fix map
1. *Decision was "tap the bigger number"* → heavy-keeps-coherence vs
   dive-for-resonance, plus a one-step lookahead so resonance can be routed onto
   a heavy world. A real risk/reward with a ceiling.
2. *Passive play still scored* → no default selection; missing the commit
   DECOHERES (keep only the smaller amplitude, halved, streak reset).
3. *Ghost fractals out-painted the live fork* → recursion removed; the wake and
   lookahead are a dim background layer, the live fork is the only bright thing.
4. *No climax* → last-12s RESONANCE CASCADE: gap collapses toward 50/50, the
   front spikes, resonance bonuses bloom.

## Brand
Electric timeline cyan worldline, brand-gold resonance, ink/atmosphere
background — on-palette with `theme/potatuhs.dart`. One Ticker, one painter,
finite-guarded geometry, <80s.
