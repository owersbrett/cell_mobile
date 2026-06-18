# GAME.md — Powerhouse & Skeleton

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **Status: UNBUILT — forward build-spec. Build from this document.**

- **Scale (cell):** organelle
- **Game id:** powerhouse_skeleton
- **One-line concept:** Glucose feeds into the mitochondria and ATP tokens are minted and spent —
  while microtubules grow and centrioles anchor the cytoskeleton — in a dual-track tapper that
  teaches cellular energy production and the structural backbone of the cell.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

The mitochondrion is the only organelle that schoolchildren can name. "Powerhouse of the cell" is
a meme precisely because it is memorable. This game earns that title honestly: glucose goes in,
ATP comes out, and the player gets to feel the conversion. But energy production alone is only
half the story — the microtubule scaffold and the centrioles are the machinery that divides and
positions everything. Without the skeleton, the powerhouse has nowhere to deliver its ATP.

Peroxisomes complete the trio: they catch the free radicals that mitochondria emit as metabolic
byproducts and neutralize them. The cleanup crew runs beside the furnace.

---

## Rules (canonical)

### Track A — The Powerhouse (mitochondria + ATP)

1. **Glucose units drift down the left side of the screen.** Each is drawn as an orange-brown
   hexagon labeled `C₆H₁₂O₆`. Tap to feed it into the mitochondrion at the bottom-left.

2. **The mitochondrion processes glucose over time.** A "processing meter" on the organelle fills
   for 1.5 s after a glucose unit is fed. While processing, a new glucose unit cannot be fed.

3. **When processing completes, 2 ATP tokens are ejected.** ATP tokens (drawn as triple-ring
   phosphate structures, labeled `ATP`) fly upward into a central ATP pool at the top of the
   canvas. The pool count increments.

4. **ATP is spent automatically.** Every 3 s, a "cellular demand" event fires: an organelle
   silhouette label ("RIBOSOME NEEDS ATP," "SPINDLE NEEDS ATP," etc.) appears and drains 1 ATP
   from the pool. If the pool reaches 0 and a demand fires, −10 points and a "CELL STALLED" flash.

5. **Keep the ATP pool between 2 and 8.** Below 2 = vulnerable (any demand stalls the cell).
   Above 8 = overflow (ATP degrades to ADP; excess units vanish and score +0). Sweet spot is
   the game's tension.

### Track B — The Skeleton (microtubules + centrioles)

6. **Microtubule segments appear at the right side.** They are small rectangular bars, teal,
   labeled `TUBULIN`. Tap to snap them onto the growing microtubule lattice drawn in the right
   half of the canvas.

7. **The lattice has 4 anchor points (centrioles)** — drawn as two pairs of perpendicular
   cylinders at the top-right and bottom-right. Each anchor can support one radiating microtubule
   arm. An arm grows by snapping in segments; each snap = +5 points.

8. **Complete an arm (5 segments) to score +20 bonus** ("SPINDLE FIBER COMPLETE"). The arm glows
   and, after a brief celebration, fades back to allow rebuilding (microtubules are dynamic — they
   grow and shrink in real cells).

9. **Peroxisome intercept (both tracks).** Every 10–14 s, a free-radical spark streaks across the
   center of the canvas. Tap it to neutralize it (the peroxisome flashes and absorbs it, +8
   points). Miss it and it damages a microtubule arm, degrading 2 segments (−2 progress on the
   nearest active arm).

### Combined scoring

10. **Combo trigger.** If the player completes a microtubule arm at the same time the ATP pool is
    at 5 or above, a "POWERED SKELETON" combo fires: +30 bonus and a brief synchronized glow across
    both tracks. This rewards managing both tracks simultaneously — the game's skill ceiling.

---

## Controls

Tap anywhere to interact — the nearest valid target within 40 px is selected:
- Left side: glucose units drifting down → tap to feed into mitochondrion.
- Right side: tubulin segments → tap to snap onto nearest incomplete arm.
- Center: free-radical sparks → tap to intercept.

Canvas-drawn only. No raster assets.

Visual language:
- **Mitochondrion** — bean-shaped organelle with inner cristae folds, drawn at bottom-left.
  Processing meter fills the interior cyan/amber while processing.
- **ATP token** — triple stacked rings (adenine ring + two phosphate rings), orange-amber, labeled
  `ATP`. Pool shown as a row of tokens across the top center.
- **Glucose unit** — hexagon labeled `C₆H₁₂O₆`, orange-brown, drifting downward.
- **Microtubule lattice** — right half canvas, teal segmented arms radiating from centriole anchors.
- **Centrioles** — two pairs of nine-triplet cylinder rings (simplified: two small rectangles at
  right angles), anchoring microtubule arms.
- **Tubulin segment** — small teal rectangle, floating rightward, labeled `α/β TUBULIN`.
- **Peroxisome** — small maroon oval, visible in the center-lower region; flashes and glows green
  on a successful radical intercept.
- **Free-radical spark** — jagged star shape, bright white with red tinge, moves in a straight
  line across the canvas.

---

## Scoring

| Event | Score |
|---|---|
| Glucose fed into mitochondrion | +5 |
| ATP token produced (automatic on processing complete) | +3 per token (×2 = +6 per glucose) |
| Cellular demand met (ATP pool ≥ 1 when demand fires) | +5 |
| Cellular demand stalled (ATP pool = 0) | −10 |
| Tubulin segment snapped onto arm | +5 |
| Microtubule arm completed (5 segments) | +20 |
| Powered Skeleton combo (arm complete + ATP ≥ 5) | +30 |
| Free-radical spark intercepted by peroxisome | +8 |
| Free-radical spark missed (arm degraded) | −arm loses 2 segments |

---

## Win / end condition

Timed score attack. Session duration set by the host. Highest score at time-up wins.

---

## Difficulty curve

Three levers:
1. **Glucose drift speed** — increases from 1.0× to 2.2× over the session. Faster = harder to
   time the feed into the mitochondrion.
2. **Cellular demand rate** — demand interval decreases from 5 s to 2.5 s, increasing ATP drain
   pressure. Requires feeding glucose faster to maintain the pool.
3. **Free-radical frequency** — sparks begin at 14 s intervals, tighten to 8 s by end of session.
   At high speed, managing both tracks while intercepting sparks is challenging.

Key tunables:
- `_kProcessingTime` = 1.5 s — mitochondrion processing duration
- `_kATPPerGlucose` = 2 — ATP tokens produced per glucose (biologically simplified from 36)
- `_kATPDemandIntervalMax` = 5.0 s, `_kATPDemandIntervalMin` = 2.5 s
- `_kATPPoolMin` = 2, `_kATPPoolMax` = 8 — sweet-spot range
- `_kATPStallPenalty` = 10
- `_kTubulinArmLength` = 5 segments
- `_kArmCompleteBonus` = 20
- `_kPoweredSkeletonBonus` = 30
- `_kRadicalIntervalMin` = 8 s, `_kRadicalIntervalMax` = 14 s
- `_kRadicalInterceptScore` = 8
- `_kHitRadius` = 40 px

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Mitochondria | The primary game machine — glucose in, ATP out. The cristae structure is drawn. Teaches the function by making it the mechanic | ✅ |
| Microtubules | Building the cytoskeleton lattice IS the second track. Tubulin = the building block is explicitly labeled. Dynamic instability (growth/shrink cycle) is represented | ✅ |
| Centrioles | Drawn as anchor points for the microtubule arms; labeled as the organizers of the spindle during division. The "great divider" role is surfaced in a demand event ("SPINDLE NEEDS ATP") | ✅ |
| Peroxisomes | Free-radical intercept mechanic — the detox function is the mechanic, not decoration | ✅ |

---

## Potato angle

The mitochondrion-to-ATP chain is the same chain referenced at the Molecular scale. The potato
plant's cells burn glucose (made by the chloroplast from sunlight) in their mitochondria to
produce ATP. That ATP powers everything else in the cell — including the amyloplast packing starch
and the ribosomes making enzymes. The WOW overlay on the first "CELL STALLED" event surfaces:
"When a potato plant wilts from heat stress, it's because its cells can't make ATP fast enough to
keep the cytoskeleton pressurized. The skeleton and the powerhouse are one system." The ATP
demand events named "AMYLOPLAST NEEDS ATP" and "RIBOSOME NEEDS ATP" connect directly to the other
games in this scale.

---

## Session / resume

Persist: `score`, `elapsed time`, `_atpPoolCount`, `_glucoseQueueCount` (how many glucose units
were visible on screen — approximate; reseed on resume), `_armProgress` (array of 4 integers,
segments completed per arm), `_processingTimer` (remaining processing time in mitochondrion).
Drifting glucose, tubulin, and radical sparks are ephemeral — reseed on resume from the
persisted arm and pool states.

---

## Implementation notes

**Status: UNBUILT.** Create `lib/games/organelle/powerhouse_skeleton/powerhouse_skeleton.dart` →
class `PowerhouseSkeletonGame extends StatefulWidget` implementing `MiniGame`. Register on
`BioScale.organelle` in `lib/games/mini_game_registry.dart`.

**Canvas-only. No raster assets.**

**Biological note on ATP count:** Real cellular respiration produces ~30–36 ATP per glucose.
The game uses 2 ATP per glucose for mechanical simplicity. If a WOW flare fires on the first
glucose processed, it can surface: "In reality, one glucose yields ~30 ATP — but that would make
the game trivially easy." This keeps the simplification honest.

**Dual-track layout split:** canvas split ~45% left (mitochondria/ATP track) / ~55% right
(skeleton track). A faint vertical divider (dashed line) separates them. The ATP pool row spans
the top center and bridges both tracks visually.
