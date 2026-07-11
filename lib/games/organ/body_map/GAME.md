# GAME.md — Body Map

> The canonical rules for this game. If behaviour and this file disagree, this file wins —
> change the spec here first, then the code.

## One line
Drag each organ that flies up from the tray onto its correct spot in a human silhouette.

## Scale
`BioScale.organ` — the organ scale. (This is the *placement* counterpart to **Organ Rush**,
which is a multiple-choice quiz at the same scale. Body Map teaches spatial position, not naming.)

## The loop
1. A human silhouette fills the field (head → pelvis, with arms and legs for orientation).
2. Organs arrive **one at a time**, flying up from off-screen into a staging slot at the bottom.
   The active organ is drawn as a colored token with its name (e.g. "Heart", "Left Lung").
3. The player **drags** the active organ onto the body and releases.
   - **Correct** (released within the organ's snap zone): it snaps into place, is named on the body,
     and scores. The next organ flies in.
   - **Wrong** (released anywhere else): it **bounces back** to the staging slot. Streak resets.
4. Placing **every** organ in the current set clears the "body" → a round bonus, then a new round
   starts with **more organs, faster arrivals, and tighter zones**.

## Scoring
Per correct placement:
- **Base** — 30.
- **Speed bonus** — up to +30, scaled by how quickly you placed it after it arrived
  (window shrinks with the tier: 3.5 s → 1.5 s).
- **Accuracy bonus** — up to +20, scaled by how close to the exact center of the zone you dropped.
- **Streak bonus** — +5 per consecutive correct placement (`(streak − 1) × 5`).

Per wrong placement: **−5** (floored at 0), streak resets, red flash.

Per cleared body (round): **+40 + roundIndex × 20**, plus **+40** if the whole round was flawless.

`scoreUnit` = **points**. The host owns the 60-second clock, the live score, the countdown,
the results screen, and the streak award (fed via `session.noteStreak`).

## How to win
Most points when the 60 seconds run out.

## The climb (acceleration)
Difficulty `tier = min(roundIndex, 8)` drives every knob:

| Knob | Round 1 (tier 0) | Late (tier 8) |
|---|---|---|
| Organs in the round | 4 | up to 12 |
| Fly-in duration | 1.10 s | 0.45 s |
| Snap-zone radius | 0.15 × bodyW | 0.075 × bodyW |
| Speed-bonus window | 3.5 s | 1.5 s |
| Ghost target ring | shown | hidden |

Rounds 1–2 show a faint pulsing **ghost ring** at the correct spot (learn the anatomy).
From round 3 the ring vanishes — pure recall.

## Organ set (landmark-first introduction order)
Brain · Heart · Left Lung · Right Lung · Stomach · Liver · Intestines · Bladder ·
Left Kidney · Right Kidney · Spleen · Pancreas.

Each round uses the first `4 + roundIndex × 2` organs of this list (capped at 12), shuffled.
Early rounds drill the big landmarks; later rounds add the small, easily-confused organs.

## Presentation & legibility (visual pass)
- **The figure is a stylized anatomy body**, not a pale ghost: warm skin
  gradient (lit top-left, shaded edge), a body-glow halo, a rim light, and a
  clipped **torso cavity** with faint rib-cage arcs + a spine seam, so placed
  organs read as sitting *inside* the body. Organs are layered orbs (glow →
  radial gradient → rim → specular highlight), never flat stickers.
- **Always-visible OBJECTIVE** at top-centre: "DROP EACH ORGAN WHERE IT LIVES".
- **Fading how-to hint** over the first ~4.5 s of a run: "Drag the organ from
  the tray onto the body".
- **Target beacon while dragging**: whenever the player holds the organ, a
  pulsing colored crosshair + the organ's name marks its home region — so the
  destination is legible even after the training ghost ring turns off.

## Session / re-entry (the S in GAMES)
- Auto-starts when the host sets `isRunning`; until then it shows a calm silhouette and the
  prompt "Drag each organ to where it lives". No self-owned clock or game-over screen.
- All progress gates on `session.isRunning`; the host's countdown / results / exit own the
  session boundary. A run ends when the host's clock hits zero; a fresh run rebuilds from
  round 1 on the next mount. Verified: a session closes and a new one re-enters cleanly.
