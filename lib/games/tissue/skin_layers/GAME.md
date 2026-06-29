# Skin Layers — GAME.md

**id:** `skin_layers` · **scale:** `BioScale.tissue` · **duration:** 60s · **score unit:** layers

## One line
Rebuild a slice of skin by stacking its layers in the correct depth order —
surface on top, deep at the bottom.

## The mechanic (the lesson IS the mechanic)
A vertical stack of empty depth-bands sits in the middle of the screen, surface
at the very top and the deepest layer at the very bottom. Below it is a tray of
shuffled layer tiles. Drag each tile into the band at its correct depth.

- **Correct placement** snaps the tile into its band; the boundary with a
  correct neighbour reads healthy (teal).
- **Wrong order** flags: when two filled neighbouring bands are out of depth
  order, the boundary between them turns **red** — you see exactly where the
  stack breaks.
- **Tap any tile** (in the tray or placed) to read its one-line role: what that
  layer holds and what it does.
- **Complete a section** (every band filled, all correct) and the skin
  **comes alive** — it pulses, sweat beads and sparks rise — you bank a
  cross-section bonus, then a new, deeper section appears.

## Difficulty ramp
- **Section 0 (primer):** the three major layers — Epidermis → Dermis →
  Hypodermis.
- **Section 1+:** the epidermis splits into its strata (Corneum, Granulosum,
  Spinosum, Basale) and dermal structures weave in (Papillary, Sebaceous gland,
  Hair follicle, Nerve, Reticular, Sweat gland, Blood vessel) above the deep
  Hypodermis. Sections grow from 4 up to 7 bands as you clear them, so the
  game accelerates by adding sub-structures.

## Scoring
- Correct placement: **+15 + streak×2** (first time a band is correctly filled).
- Wrong placement: streak resets, red flash.
- Completed section: **+40 + section×12 + speed bonus** (faster = more), and the
  streak grows.

## How to win
Stack the most skin layers correctly before the 60-second clock runs out — most
layers placed wins.

## Host contract
The host (`MiniGameHost`) owns the clock, the 3-2-1 countdown, the score HUD and
the results screen. This widget renders ONLY the play area, auto-starts on
`session.isRunning`, shows a calm ready state before the run, and reports points
via `session.addScore` / `session.noteStreak`.

## Tuning
- `humanMax`: 900 · `starThresholds`: [300, 550, 800] — tune by playtest.
