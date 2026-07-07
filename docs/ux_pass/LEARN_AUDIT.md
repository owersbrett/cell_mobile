# LEARN-experience UX Audit + Implementation

The LEARN path is the solo journey through 22 scales (nothing → infinities), each
scale holding an entity explorer and a games list. This pass audited that path and
implemented the fixes. Board/PARTY code was out of scope and untouched.

## Findings (audit)

1. **The awe of ~40 orders of magnitude was absent.** No size readout, no "you are
   here" ladder — the 22-scale carousel read as a set of themes, not a cinematic
   zoom from the sub-atomic to the infinite.
2. **The EDUCATION.md layer (116 files) was invisible in the LEARN path.** No Dart
   referenced it; the E in GAMES never surfaced to a learner.
3. **The entity explorer read as a static wiki.** No "what you'll learn" framing —
   nothing told the player this was a lesson.
4. **Typography / palette violations.** `scale_overview_page.dart`,
   `scale_explorer_page.dart`, `scale_card.dart` and `scale_indicator.dart` all
   hardcoded `fontFamily: 'Avenir'` (banned) and raw hex / `Colors.white*` instead
   of `lib/theme/potatuhs.dart`.
5. **BUG — downstream screens knew only ~11 of 22 scales.** `scale_explorer_page`
   and `scale_indicator` carried colour/label/icon maps for only the ~11 "biology"
   scales. The carousel had all 22; the explorer and indicator did not — so cosmic
   and sub-atomic scales rendered a blank indicator chip with a white fallback
   colour.

## Implemented

1. **NEW `lib/data/scales/scale_meta.dart` — the ScaleMeta SSOT for all 22 scales.**
   Each entry carries `label`, `subtitle`, `color`, `icon` (lifted verbatim from the
   carousel so nothing regresses) plus three education-forward fields: `magnitude`
   (e.g. `10⁻¹⁰ m`, `∞`, `—`), `comparison` (a human-scale line), and `learn` (the
   one-line teaching promise). Ordered list `kScaleJourney` (nothing → infinity) +
   helpers `scaleMetaFor()` (never-null lookup) and `scaleJourneyIndex()`.

2. **`scale_overview_page.dart`** — scale-tinted radial background that crossfades as
   you zoom; a `SCALE n / 22 · magnitude` readout with a ZOOMING IN / THE CELL /
   ZOOMING OUT tag; a nothing→infinity gradient **position ladder** with a
   "you-are-here" pip; carousel + index sheet now read the SSOT; all Avenir/raw hex
   purged for Potatuhs typography and palette.

3. **`scale_card.dart`** — a **magnitude chip** and a **"what you'll learn"** line
   (school icon + `learn` promise) added to every card; Potatuhs fonts/palette.

4. **`scale_explorer_page.dart` + `scale_indicator.dart`** — both now read the SSOT,
   so all 22 scales resolve to a real colour/label/icon (fixes the blank-chip bug).
   The indicator shows the journey position (`n/22`). The explorer gained a
   **"WHAT YOU'LL LEARN"** framing banner (promise + magnitude) under the header, so
   it reads as a lesson rather than a wiki. Avenir/raw hex purged.

## Constraints honoured

- Behaviour and navigation preserved exactly — this was presentation + metadata
  consolidation only.
- No edits to `lib/party/`, `mini_game_registry.dart`, `game_catalog.dart`, or
  `home_page/`.
- Files touched: `lib/data/scales/scale_meta.dart` (new), `scale_overview_page.dart`,
  `scale_card.dart`, `scale_explorer_page.dart`, `scale_indicator.dart`, this doc.

## Follow-ups (not done here)

- The `comparison` field is authored in the SSOT but not yet surfaced in the UI — a
  natural next touch is a tap-to-reveal on the magnitude chip.
- Deeper EDUCATION.md wiring (linking the explorer to the lessons app per scale)
  remains; this pass surfaces the promise, not the full lesson content.
