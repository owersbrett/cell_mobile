# Bubbles v2 — Agent (A)

The owning agent for `bubbles_v2`. Improve THIS game only; do not touch the
registry, catalog, host, or sibling games (including the original `bubbles`).

## Charter
Keep the eternal-inflation lesson (a false-vacuum sea spontaneously nucleates
bubble universes; they must stay causally separate; the sea outruns you) while
holding the Fun-Multiplayer UX bar. This module is the UX-pass alternative to
`bubbles` — the original stays playable alongside it.

## Invariants (do not regress)
- **One verb.** TAP a gold bubble to HARVEST it, with a forgiving hit radius and
  **never** an accidental nucleation. The original's fatal flaw was a tap that
  meant harvest / no-op / nucleate by target. Do not reintroduce player
  nucleation or any second tap meaning.
- **The vacuum nucleates, in OPEN space only.** Spawns seek the clearest spot
  and skip when the sea is full — nothing ever drops onto an existing bubble. No
  bubble may be lost to a spawn collision.
- **Spoilage is telegraphed, never luck.** Every approaching pair raises a red
  WARNING ARC (~1.2s) before they touch; harvesting either defuses it. A lost
  bubble must always be a missed read. Don't shorten the warning below playable.
- **Depth in the flood.** Two reasons to choose WHICH bubble: size-value (ripe
  bubbles keep growing, worth more, but crowd sooner) and a chained COMBO
  multiplier (capped ×3, broken by any collision). Don't let late game collapse
  to undifferentiated spam, and don't let the multiplier run away.
- **Climax from the host clock.** `_inClimax` reads `session.remaining`; the host
  owns the clock. Don't add a second timer.
- **One Ticker → one CustomPainter.** No second AnimationController; no per-frame
  allocations beyond the particle/pop lists. Bubbles + particles stay capped;
  the O(n²) collision pass relies on the cap — don't balloon it.

## Tuning knobs (top of file)
`_kGrowthBase`/`_kGrowthRamp`, `_kSpawnMax`/`_kSpawnMin`, `_kMatureRadius`,
`_kWarnGap`, `_kMinClearance`, `_kHarvestBase`/`_kSizeBonus*`/`_kClutchBonus`,
`_kCombo*`, `_kClimaxWindow`, the caps. `humanMax` / `starThresholds` live in the
registry spec — playtest to tune.

## Definition of done (GAMES)
- **G** `bubbles_v2_game.dart` (`BubblesV2Game`). **A** this file. **M** GAME.md.
  **E** EDUCATION.md. **S** session re-entry: the field clears on the first
  `isRunning` frame (`_seeded`), so a run closes on host timeout and a fresh one
  starts clean.
- `flutter analyze lib/games/multiverse/bubbles_v2/` → zero issues before commit.
