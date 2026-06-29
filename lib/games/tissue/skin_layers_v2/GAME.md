# Skin Layers v2 — GAME.md

**id:** `skin_layers_v2` · **scale:** `BioScale.tissue` · **duration:** 60s · **score unit:** layers

## One line
Rebuild a slice of skin in real time — drag each incoming layer to its correct
depth before the tempo runs out, and beat an accelerating cadence to the finish.

## The mechanic (the lesson IS the mechanic)
A vertical column of empty depth-bands sits in the middle — surface at the top,
deepest at the bottom, each numbered. One layer tile "docks" at the bottom on a
draining **tempo bar**. Drag it up into the band at its correct depth.

- **Correct placement** locks the tile into its band; the boundary with a
  correct neighbour reads healthy (teal). You bank the layer and the next tile
  docks **immediately** — the flow never stops.
- **Wrong band** flashes a **red break** at the band you aimed at, resets your
  streak, and bounces the tile back to the dock to retry.
- **Tempo runs out** → the layer is requeued (so the column can still finish),
  the streak resets, a red wash flashes, and the next tile docks.
- **Live hint:** the correct band glows. The glow is strong for a beginner and
  **fades as your streak climbs** — past streak 6 you fly blind on pure recall.
- **Tap the docked tile** (or its ⓘ badge) to read that layer's one-line role.
  Tap is a dedicated info gesture — it never removes anything.
- **Complete a column** (every band filled correctly) → the skin **comes alive**
  (pulse + rising sweat beads) as a quick, **non-blocking** flash, and a deeper
  column seeds instantly. No 1.6s freeze.

## The accelerating arc
Every correct placement shrinks the next tile's dock time
(`2.6s → floor 0.85s`). The more skin you rebuild, the faster tiles arrive — the
round climbs from calm to frantic, a self-paced climax driven by your own skill.

## Difficulty ramp
- **Section 1 (primer):** the three major layers — Epidermis → Dermis →
  Hypodermis.
- **Section 2+:** the epidermis splits into its strata (Corneum, Granulosum,
  Spinosum, Basale) and dermal structures weave in (Papillary, Sebaceous, Hair
  follicle, Nerve, Reticular, Sweat gland, Blood vessel) above the deep
  Hypodermis. Columns grow 4 → 7 bands.

## Scoring (honest "layers")
- Correct placement: **+1 layer** (banked skin), **+2 on a hot streak** (≥5).
- Completed column: **+columnSize** bonus layers.
- Wrong band / timeout: streak resets — **no points lost** (never negative).

The score reads as "layers of skin rebuilt." Spread between players comes from
**speed + recall**, not pre-existing histology knowledge — the fading hint floors
the novice, and the accelerating tempo caps the expert.

## How to win
Rebuild the most layers of skin before the 60-second clock runs out.

## Host contract
The host (`MiniGameHost`) owns the clock, the 3-2-1 countdown, the score HUD and
the results screen. This widget renders ONLY the play area, gates all progress on
`session.isRunning`, and reports points via `session.addScore` /
`session.noteStreak`.

## Tuning
- `humanMax`: 70 · `starThresholds`: [25, 45, 65] — tune by playtest.
- Tempo ramp: `_dockNext` (`2.6 - placed*0.045`, floor 0.85s).
- Hint fade: `_drawHint` (`1 - streak/6`).
