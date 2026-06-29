# GAME.md — Organelle Match

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** organelle (`BioScale.organelle`)
- **Game id:** organelle_match
- **One-line concept:** A function/clue appears ("...burns sugar with oxygen to make
  energy"); tap the organelle that does it, from four choices. Speed-scored, streak
  multiplier, per-answer fact card.
- **Role:** solo high-score (also drops into party rotation)
- **Six-in-one?** no

---

## Lore

A cell is a tiny city, and every organelle is a worker with one clear job. The nucleus
runs the show with the DNA blueprint. The mitochondria burn fuel for energy. Ribosomes
build proteins; the ER and Golgi finish and ship them. Lysosomes recycle; the vacuole
stores; the chloroplast (in plants) turns sunlight into food; and the cell membrane is the
gatekeeper at the edge. Learn the city by matching each job to its worker.

---

## Rules (canonical)

1. **A clue is posed.** The prompt reads "Tap the organelle that {clue}" — a verb phrase
   describing one organelle's job (e.g. "captures sunlight to make sugar").

2. **Four options.** Exactly four organelle names; one is correct. Tap to answer.

3. **Speed scoring.** A correct answer scores a speed bonus that decays linearly from
   `_kMaxPoints` (100) for an instant answer down to `_kFloorPoints` (15) for a slow one,
   across a decay window. The window TIGHTENS as the round accelerates (4.0 s → 1.8 s), so
   late answers must be quicker to earn the same points.

4. **Streak multiplier.** Each consecutive correct answer raises the multiplier by +1× per
   `_kStreakStep` (3) correct in a row: `mult = 1 + streak ~/ 3`. Final points = speed
   bonus × multiplier. The current streak is reported via `session.noteStreak(streak)` so
   the host can award a streak medal on the results screen. A wrong answer resets the streak.

5. **No wrong-answer penalty.** A wrong tap scores 0, shakes the card red, and resets the
   streak — but never subtracts. Keep it fast and forgiving; the fact card does the teaching.

6. **Fact card flare.** After every answer a card flares for ~2.3 s (tap to skip): the
   points earned (or "It's the {name}" on a miss), the organelle's name + one-line job, and
   a fun fact. Then the next clue loads.

7. **Acceleration.** Difficulty = `max(timeElapsedFraction, answered/10)`. As it climbs:
   (a) the speed-bonus window shrinks (answer faster), and (b) distractors are pulled more
   from each organelle's **confusable** set (e.g. mitochondria ↔ chloroplast, ribosome ↔
   ER), so the wrong answers get subtler.

8. **Coverage.** Organelles are cycled through a reshuffled queue so every one is asked
   before any repeats.

---

## Organelles covered (clue → answer)

| Organelle | Job taught |
|---|---|
| Nucleus | Control center — holds the DNA |
| Mitochondria | Powerhouse — makes ATP (respiration) |
| Ribosome | Builds proteins (protein synthesis) |
| Chloroplast | Photosynthesis — makes sugar |
| Golgi apparatus | Packaging & shipping |
| Lysosome | Digestion & recycling |
| Endoplasmic reticulum | Synthesis & transport |
| Vacuole | Storage |
| Cell membrane | Boundary & gatekeeper (transport) |

Each has 3 alternate clue phrasings and a fun fact (see `_kOrganelles` in the game file and
`EDUCATION.md`).

---

## Controls

Tap an option card to answer. Tap the fact card to skip to the next clue. All rendering is
`CustomPainter` (background + particle bursts) + a 4-card widget grid — no raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Correct answer | `speedBonus (15–100) × streakMultiplier` |
| Streak milestone (every 3rd correct) | gold particle burst (no extra points) |
| Wrong answer | 0 (streak resets) |

`humanMax` ≈ 1800. Star thresholds `[500, 1000, 1600]`.

---

## Win / end condition

Timed score attack. Duration is the host's `session.spec.durationSeconds` (60 s). Highest
score when time expires wins. The game never calls `endEarly`.

---

## Difficulty curve

`difficulty = max(elapsedFraction, answered/10)`, 0 → 1.
- **Decay window:** `lerp(4.0, 1.8, difficulty)` s — the speed window narrows.
- **Distractor subtlety:** near-miss target = `clamp(1 + round(2·difficulty), 0, 3)` — more
  options drawn from the answer's confusable set as the round heats up.

---

## Session / resume

Stateless across the round besides score (host-owned), streak, answered count, and the
current question. The question queue is ephemeral — on resume, rebuild the queue and pose a
fresh clue. Score persists via the host's `MiniGameSession`.

---

## Implementation notes

**File:** `lib/games/organelle/organelle_match/organelle_match_game.dart` —
`class OrganelleMatchGame extends StatefulWidget`. Registry game on `BioScale.organelle`.

**Perf:** ONE `Ticker` → ONE `CustomPainter` (background + particle field). The option cards
are a tiny 4-widget tree rebuilt per frame (cheap). Ticker is disposed in `dispose()`.

**Tunable constants:**

| Constant | Value | Effect |
|---|---|---|
| `_kMaxPoints` | 100 | Points for an instant correct answer |
| `_kFloorPoints` | 15 | Points for a slow correct answer |
| `_kDecayWindowStart` | 4.0 | Speed-bonus window at round start (s) |
| `_kDecayWindowEnd` | 1.8 | Speed-bonus window at full difficulty (s) |
| `_kStreakStep` | 3 | Correct-in-a-row per +1× multiplier |
| `_kFactFlareDuration` | 2.3 | Fact-card window (s), tap to skip |
| `_kShakeDuration` | 0.45 | Wrong-answer shake length (s) |
