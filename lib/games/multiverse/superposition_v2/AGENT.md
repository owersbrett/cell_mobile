# Superposition v2 — Agent (A)

**Owner agent:** the multiverse-scale games agent.
**Module:** `lib/games/multiverse/superposition_v2/superposition_v2_game.dart`
**Spec id:** `superposition_v2` (registry `mini_game_registry.dart`, catalog
`game_catalog.dart`).

## Charter
Keep `superposition_v2` clearing the Fun-Multiplayer UX bar while preserving the
quantum-measurement lesson. This is the UX-passed sibling of `superposition`;
the original stays untouched for A/B comparison.

## Invariants (do not break)
- **Fairness:** measuring inside the LOCK zone (`P(target) ≥ _kGuarantee`) must
  stay GUARANTEED — never reintroduce an RNG roll on a perfect read. The honest
  weighted collapse is allowed ONLY below the lock zone (the opt-in gamble).
- **Score the probability, not a coin-flip:** points scale continuously with the
  P (and joint P) you achieved. No flat binary lucky/unlucky payout.
- **The sphere carries the read:** vector tip height = P(target); uncertainty
  cloud sized by variance P(1−P); lock zone drawn on the sphere. If you add UI,
  the sphere must remain the primary signal, the meter a secondary confirm.
- **Climax:** the two-qubit coincidence cascade fires off the host clock
  (`session.remaining ≤ _kClimaxMs`). The host owns the clock — read it, never
  run a second timer.
- **Perf:** one `Ticker` → one `CustomPainter`. No per-frame allocations beyond
  the existing snapshot lists. All geometry guarded finite.
- **Self-contained:** depends only on `mini_game.dart`, `fx.dart`,
  `theme/potatuhs.dart`, Flutter, `dart:math`. Never import another game.

## Safe tuning knobs
`_kGuarantee` (lock-zone width), `_kBaseOmega`/`_kOmegaStep`/`_kOmegaCap`
(window tightening), `_kClimaxOmegaBoost`, `_kClimaxMs`, `_kCollapseHold`, the
score bases/exponents, and `humanMax`/`starThresholds` in the spec.

## Verify
`flutter analyze lib/games/multiverse/superposition_v2/` → zero issues.
`flutter test test/games`.
