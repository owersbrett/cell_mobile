# GAME.md — Cosmic Timeline (universe_all)

> Self-contained module. Depends only on `MiniGameSession` + `fx.dart` + `theme/potatuhs.dart` + Flutter.
> Edit ONLY this folder.

- **Scale:** universeAll · **Game id:** `cosmic_timeline` · **Verb:** ORDER-THE-EPOCHS
- **Module:** `lib/games/universe_all/cosmic_timeline/cosmic_timeline_game.dart`
- **Builder:** `CosmicTimelineGame(session:)`

## Concept
Shuffled cards of cosmic events (Big Bang, Inflation, Quark Soup, First Nuclei, CMB/Recombination, Dark
Ages, First Stars, First Galaxies, Our Sun, Life on Earth, Now) must be dragged into chronological ORDER
on a row of slots (earliest → latest). A correctly placed card locks, turns teal, and reveals its WHEN
(e.g. `380,000 yrs`, `13.8 Gyr`). A wrong-order adjacency flags: the arrow into the out-of-place card
turns red so you see exactly where the sequence snaps. Fill every slot in order → the timeline LOCKS and
the cards plot onto a LOGARITHMIC deep-time ribbon along the top (early epochs spread, recent eons cram
the right). Then a new, longer/finer timeline appears.

## Rules
- Drag a card into a slot: right slot → teal flow + reveals its "when"; wrong order → red snap arrow.
- Tap a placed card to pull it back and rearrange; tap a tray card to read its fact.
- Complete the whole order in sequence to LOCK the timeline and bank the bonus.

## How to win
Most points when the host clock runs out. Score = correct placements (`+15 +2/streak`) + locked timelines
(`+50 +12/level +speed bonus`). Streak across clean placements and clean timelines = the mastery award.

## Accelerate
`_composeTimeline(level)` grows the order from a 4-card primer (level 0) up to all 11 epochs, folding in the
finer early epochs as levels rise. Par time per timeline tightens via the speed bonus. The log ribbon is the
constant teaching point: the universe's first second occupies as much timeline as the billions of years since.

## Structure (all private to the module)
- `CosmicTimelineGame` / `_CosmicTimelineGameState` — loop, gates on `session.isRunning`, scores via
  `session.addScore` / `session.noteStreak`; the host owns the clock/countdown/results.
- `_EpochId` + `_Epoch` + `_kEpochs` — the 11 epochs (rank, name, emoji, color, `when`, `tSec`, fact).
- `_logFrac(tSec)` — log10(seconds-since-Big-Bang) → 0..1 ribbon position (Big Bang pinned left).
- `_Card` — a draggable card (tray home / placed slot). `_TimelinePainter` — single Ticker-driven painter.

## For future agents
- Tune feel via the constants at the top (`_kLogLo/_kLogHi`, `_accent`) and `_composeTimeline`.
- One Ticker → one CustomPainter; drag mutates card positions only — no per-frame setState over big trees.
