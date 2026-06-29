# GAME.md — Half-Life

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** atoms
- **Game id:** half_life
- **One-line concept:** A sample of radioactive atoms decays in front of you — glowing atoms
  randomly flip to stable. Each round names a half-life; tap **MEASURE** at the instant the
  named fraction (½, ¼, ⅛ …) of the sample is still radioactive.
- **Role:** solo high-score (accuracy attack)
- **Verb:** TIME / ESTIMATE
- **Six-in-one?** no

---

## Lore

Radioactive decay is the one clock the universe cannot be talked out of. Every unstable nucleus
has a fixed probability of decaying per unit time, and from that single fact comes the **half-life**:
the time for half of any sample to decay — no matter how big the sample, no matter when you start
counting. After one half-life, 50% remain. After two, 25%. After three, 12.5%. The curve is a pure
exponential, `N(t) = N₀ · 2^(−t / t½)`, and it never reaches zero.

You can't predict *which* atom decays next — that's genuinely random — but you can predict, with
ruthless accuracy, *how many* will be left after a given time. Half-Life makes the player feel both
halves of that truth at once: the flicker is random, the count is law.

---

## Rules (canonical)

1. **The sample is 36 atoms** drawn as a 6×6 grid of glowing orbs. At the start of a round all 36
   are radioactive (glowing).

2. **Atoms decay over time** following the true exponential curve for the round's half-life. As the
   theoretical surviving fraction `frac = 2^(−t / t½)` drops, atoms flip from glowing → dim stable
   husks. Each atom holds a fixed random threshold, so the *visible* glowing count tracks `36 × frac`
   faithfully while *which* atoms go dark is random — exactly real decay.

3. **Each round names a half-life and a target.** The prompt reads e.g. `HALF-LIFE 3.0s · MEASURE AT
   50%`. The target is always an integer number of half-lives: 1 → 50%, 2 → 25%, 3 → 12.5%.

4. **Tap MEASURE at the target moment.** The single control is the MEASURE button. Tapping captures
   the instant; the game compares the number of half-lives elapsed at the tap (`tapN = t / t½`) to
   the target.

5. **Closer = more points.** `err = |tapN − targetN|` in half-lives.
   - `score = round(100 · (1 − err / 0.8))`, clamped to `0…100`.
   - A near-perfect tap (`err < 0.06`) earns a **+40 perfect bonus** (max 140).
   - Waiting too long (past `(targetN + 1.4) · t½`) auto-fails the round: **TOO LATE**, 0 points,
     streak reset.

6. **Streak.** A measurement within `err < 0.22` extends the streak and is reported via
   `session.noteStreak`. A worse tap (or a miss) resets it. Best streak surfaces on the host results
   screen.

7. **A live decay curve** is drawn beneath the grid: the `2^−n` exponential with the target point
   ringed and a white cursor sliding down it as time passes. On reveal the cursor freezes at the tap
   so the player *sees* how close they came on the curve. This is the teaching surface.

8. **Rounds accelerate.** Round `r` (0-based): `t½ = max(1.4, 3.4 − 0.16·r)` seconds, and
   `targetN = min(3, 1 + r ÷ 3)`. So the sample halves faster *and* the player is asked to wait
   through more halvings (50% → 25% → 12.5%) as the game goes on.

---

## Controls

One button: **MEASURE**, centered at the bottom. Active only while a round is live (disabled during
the reveal card and before the first countdown ends). Everything else is `CustomPainter` — no raster
assets.

---

## Scoring

| Event | Score |
|---|---|
| Measurement, error `err` half-lives | `round(100 · (1 − err/0.8))`, clamped 0–100 |
| Near-perfect (`err < 0.06`) | +40 bonus on top |
| Too-late auto-miss | 0, streak reset |

---

## Win / end condition

Timed accuracy attack. The host owns the clock (`session.spec.durationSeconds`, 50s). Rounds run
back-to-back until time expires; highest accumulated score wins. No in-game restart (host owns
session lifecycle).

---

## Difficulty curve

Two levers, both ramping with round index:

1. **Shorter half-lives** — `t½` falls from 3.4s toward 1.4s, so the sample decays faster and the
   cursor slides down the curve quicker, punishing reaction lag.
2. **More half-lives to wait** — `targetN` climbs 1 → 2 → 3, asking the player to hold their nerve
   through 50% → 25% → 12.5%, where small timing errors cost a larger share of the (now tiny)
   surviving fraction.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Half-life definition | The whole loop *is* the definition — wait one half-life, half remain | ✅ |
| Exponential decay | The on-screen curve + the 50→25→12.5% target ladder make `2^−n` tangible | ✅ |
| Randomness vs. statistics | Which atom decays is random; the count obeys the law — both shown at once | ✅ |
| Isotopes / dating | Named half-lives connect to real isotopes (see EDUCATION.md) | ⚠️ (named in WOW copy) |

---

## Potato angle

Carbon-14 dating: the same exponential clock that runs this game is how a charred potato from an
ancient hearth gets a date. Every potato is built from carbon forged in stars, and a tiny, steady
fraction of that carbon is radioactive C-14 ticking down on a 5,730-year half-life. Half-Life is
the player's hands on that clock.

---

## Session / resume

Persist: `score`, `_round`, `_streak`. The within-round decay state (`_roundT`, `_frac`, the atom
thresholds) is ephemeral — on resume, restart the current round cleanly from `t=0`. The host's
countdown re-arms `isRunning`; the game auto-starts round 0 on the first running tick.

---

## Implementation notes

**File:** `lib/games/atoms/half_life/half_life_game.dart` — class `HalfLifeGame`. One `Ticker` →
one `_HalfLifePainter`. Registry game on `BioScale.atoms`.

**Tunable constants (all in `half_life_game.dart`):**

| Constant | Value | Effect |
|---|---|---|
| `_kN` (`_kCols`×`_kRows`) | 36 (6×6) | Sample size / grid resolution |
| `_kBasePoints` | 100 | Points for a perfect-fraction tap |
| `_kPerfectBonus` | 40 | Extra for `err < _kPerfectErr` |
| `_kTol` | 0.8 | Error (half-lives) at which score hits zero |
| `_kGoodErr` | 0.22 | Streak-keeping threshold |
| `_kPerfectErr` | 0.06 | Perfect-bonus threshold |
| `_kRevealTime` | 1.6 | Seconds the reveal card lingers |

Round ramp lives in `_cfgFor(r)`: `t½ = max(1.4, 3.4 − 0.16r)`, `targetN = min(3, 1 + r÷3)`.

**Known TODOs:**
1. No mid-round restart (host owns lifecycle — intentional).
2. WOW/isotope flare is copy-only in EDUCATION.md; no in-game per-isotope reveal yet.
