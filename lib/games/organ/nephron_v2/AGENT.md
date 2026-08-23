# Nephron v2 — AGENT.md

**Owner agent:** the Nephron v2 maintainer. Self-contained module under
`lib/games/organ/nephron_v2/`. May depend only on `mini_game.dart`, `fx.dart`,
`theme/potatuhs.dart`, and Flutter/dart:math. Must not import another game.

## Charter
Keep the kidney-filtration lesson intact while holding the Fun-Multiplayer UX
bar. This is the UX-passed alternative to `organ/nephron` (v1); both coexist for
the A/B judge.

## What changed vs the original (the teardown's two required fixes + polish)
1. **AFFORDANCE (required).** v1's rules said "FLICK" but `_onTapDown` routed by
   a static tap x-position with no gesture detection at all. v2 implements a
   **real drag/flick**: `onPanStart` grabs the nearest molecule, `onPanUpdate`
   moves it under the finger (direct manipulation), `onPanEnd` commits by flick
   **velocity** (`_kFlickV`) or by the side it was **released** on
   (`_kCommitZone`). A centred release with no flick releases the molecule — it
   keeps falling. Left/right gestures now genuinely sort.
2. **FAIRNESS (required).** v1 called `session.endEarly()` when purity hit zero —
   struggling players got a *shorter clock*, a fairness inversion. v2 **removes
   the early-out entirely**. Every player rides the full 60 s. Purity is now a
   tension gauge + a gentle catch-up (low purity slows the flow and dims the
   blood vessel), and it recovers on correct calls.
3. **SCAFFOLD.** Early levels (1–2) tag nutrients (pulsing green REABSORB ring)
   vs waste (red hazard ✕) pre-attentively; the tell is **stripped from level 3
   up**, ending on the read-the-label Na⁺·EXCESS twist.
4. **READABLE SCORE.** The live score reads from the host's top bar
   ("N molecules") — there is NO in-canvas score stamp (it congested the tube
   entry, overlapping the GLOMERULUS label + emitter rings; removed 2026-07-12).
   In-canvas juice is transient **+N pops** at scoring events plus the streak
   multiplier + purity gauge along the bottom band. Scoring is **non-negative**
   (wrong calls cost streak + purity, not points).
5. **CLIMAX.** Final 10 s → red FINAL FLUSH surge (×1.5) + one big final nutrient
   (×2). The accelerate now climbs to the buzzer instead of clogging out.

## Invariants (do not regress)
- ONE `Ticker` → ONE `CustomPainter` via `_RepaintNotifier`. No per-frame
  setState. `shouldRepaint => false`.
- Gate all scoring on `session.isRunning`; report via `session.addScore` /
  `session.noteStreak`. Never call `endEarly()`.
- The default-to-urine rule is the lesson — keep it. Keep the Na⁺·EXCESS call as
  the top of the ramp. Round length is owned by the host (60 s), < 80 s.
- Haptics are fire-and-forget (no-op on web).

## Tuning knobs
Spawn/fall curves, `_kFlickV`, `_kCommitZone`, purity deltas, `_kMaxMult`,
star/humanMax in the registry spec. Tune by playtest.
