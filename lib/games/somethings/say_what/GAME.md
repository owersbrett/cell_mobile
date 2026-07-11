# Say What? — Manual (M)

**Scale:** Somethings · **Verb:** DECODE / READ-ALOUD · **id:** `say_what`

## Premise
A common phrase, idiom, famous name, place, or movie line is shown spelled the
way it **sounds** — a "fauxnetic" respelling (`AISLE BEE BACK`), a homophone
phrase (`SEE FOOD`), or a **pig-latin** round (`ELLO-HAY ORLD-WAY`). Read it out
loud, hear the real phrase, and tap it from four options. It's read-it-out-loud
wordplay: your ear does the decoding your eye can't.

## Controls
- **Tap** one of the four option cards — the real phrase the fauxnetic spelling
  is hiding.
- **Tap the reveal card** (or wait) to advance to the next item.

## Rules
- A **correct** tap lights green, bursts particles, scores, and grows your
  streak.
- A **wrong** tap fizzles red, reveals the correct card, and resets your streak
  to 0. **No points are lost** — keep it fast and fun.
- **Faster reads score more.** A speed bonus decays from **120 → 20** over the
  read window; the window *shrinks* as the round escalates.
- A **streak multiplier** kicks in at 3 in a row (×2), 6 (×3), … applied to the
  speed bonus.
- Every **5 correct** answers triggers a **PIG LATIN!** special round — the
  chip turns blue and the item pays a **+30 variety bonus** on top.

## Scoring (`scoreUnit: "phrases"`)
- Correct: **(speed bonus 120→20) × streak multiplier**.
- Pig-latin correct: **+30 bonus**, then × streak multiplier.
- Wrong: **0** (streak resets, correct answer revealed).

## How to win
Most points when time runs out wins. Read fast, keep the streak alive, and cash
the pig-latin rounds.

## Accelerates
The round **escalates**: the item pool is bucketed easy / medium / hard, and a
"heat" value driven by round progress **and** current streak biases the draw
toward harder items over time (early → mostly easy; late/high-streak → hard
creeps in). Simultaneously the **speed-bonus decay window shrinks** (4.5s → 2.2s)
so a perfect run is humanly unreachable — scores cluster at peak reading skill,
never at a tie ceiling.

## Teach in-context
The first item shows a fading hint — *"Say it out loud — it sounds like a common
phrase."* — that fades once the player answers or a few seconds pass. The prompt
label always reads **READ IT OUT LOUD**. The reveal card always shows the
`"sounds"  →  answer` pairing so the trick is explained every time.

## Session (S)
The host (`MiniGameHost`) owns the clock, countdown, score HUD and results. This
widget renders only the play area and never calls `endEarly`. On a fresh run the
host resets the session (score 0, full clock, intro phase); the game re-inits its
shuffled difficulty pools and streak on a new mount, so a session closes and a
clean one re-enters.
