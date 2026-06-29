# POTATUHS — Galaxy Classifier

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Galaxy Classifier — the galactic-scale snap-classification quiz. Module at
  `lib/games/galactic/galaxy_classify/galaxy_classify_game.dart` (`GalaxyClassifyGame`); registry game
  on `BioScale.galactic`. The anti-"collect stars" game: you READ galaxies, you do not chase them.
- **O — Objectives:** post the highest 60-second score by correctly sorting drifting galaxies onto the
  Hubble tuning fork — **Spiral / Barred Spiral / Elliptical / Irregular** — faster and cleaner than
  last run. Sub-goal: ride a long correct streak for the multiplier; survive the accelerating, subtler
  late game without missing galaxies off the edge.
- **T — Tasks (the play to-do list):** watch the framed (reticled) front-most galaxy · read its shape
  (core+arms? a bar? a smooth blob? a lumpy patchwork?) · tap the matching type button before it slides
  off · call it FAST while the speed bonus is high · keep the streak alive for ×multiplier.
- **A — Automations (firing in the background):** one Ticker drives the whole field — galaxies drift
  left, slowly spin, spawn on a cadence, and resolve/fade · the `_FrameSignal` Listenable repaints the
  single `_FieldPainter` every frame without a widget rebuild · the difficulty ramp (`_playClock/45`)
  speeds the flythrough, raises the on-screen cap 4→7, and tilts `_pickType` toward bars and tight
  spirals · the focus-tracker re-frames the front-most unresolved galaxy each tick.
- **T — Testing (experimental / in-flight):** `humanMax` / `starThresholds` are first-pass and want
  real playtest tuning · an S0 (lenticular) or edge-on "advanced type" is a candidate stretch · sharper
  procedural rendering of the barred-vs-unbarred read is the main art TODO.
- **U — UX:** HUD strip (score · streak ×badge · timer) driven off the session, independent of the
  field repaint · full-field `CustomPainter` of procedural galaxies (spiral arms, central bar, smooth
  elliptical glow, lumpy irregular knots) · a pulsing four-tick reticle on the framed galaxy · a 2×2
  type-button grid, each with a tiny shape glyph · green/red button flash + on-galaxy reveal tag.
- **H — Heuristics (how you actually win):** name it the instant you recognize it — hesitation bleeds
  the speed bonus from 120 down to 20 · the bar is the ONLY thing separating barred from plain spiral,
  so look at the core first · never let the front galaxy reach the edge (a miss kills the streak) · in
  the fast late game, clear the leader and trust the next frame.
- **S — Systems (what makes the world feel alive):** a real, drifting morphology field where the same
  four Hubble classes recur and reward pattern memory · knowledge that compounds — every reveal teaches
  the shape you misread, so next round is faster · the tuning fork itself, the 1926 map astronomers and
  Galaxy Zoo volunteers still use to read the sky.
