# Converge v2 — GAME.md (the Manual)

**Scale:** Infinities · **Verb:** JUDGE-THE-LIMIT · **Duration:** 55s · **Score unit:** points

UX-passed sibling of `converge`. Same lesson, same standout chart — the lift is a
**gentler on-ramp** so the call reads in a party, not only for calculus students.

## Premise
An infinite **series** streams its terms one at a time. The running partial sum
**Sₙ** is plotted, climbing the screen — sometimes leveling onto a hidden line
(it **converges**), sometimes running away forever (it **diverges**). Judge its
fate before it's obvious.

## The two modes (mixed each round)
1. **CONVERGE OR DIVERGE** — tap **CONVERGES** or **DIVERGES** as the curve unfolds.
   - `½ + ¼ + ⅛ + ⋯` flattens → **converges**.
   - `1 + ½ + ⅓ + ¼ + ⋯` (harmonic) crawls but never stops → **diverges**.
2. **WHAT'S THE LIMIT** — for a convergent series, tap which value it approaches.
   - Zeno: `½ + ¼ + ⅛ + ⋯ = 1`.

## What v2 adds (the on-ramp — preserves the lesson)
- **Fading coach cue.** Early in a run a faint on-chart cue names the heuristic
  for that series — "terms HALVE each step" (settles) vs "terms shrink TOO
  SLOWLY" (runs away). It teaches the exact trap (terms→0 is *necessary but not
  sufficient*), then **fades out by mid-round and is gone at the climax** — a
  reasoned call for newcomers, never a hand-hold for skilled players.
- **Honest trend readout.** A dashed reference line marks where the sum sat a few
  terms back; the newest point is tagged **↑ rising** / **≈ leveling** from the
  real recent slope — so a crawling divergent sum can't *look* flat and the
  early call stays fair.
- **Chained streaks.** A correct call auto-advances fast; only a **wrong** call
  holds the full teaching reveal.
- **Final burst.** The last stretch forces short, decisive series streamed faster.

## Rules
- A new term arrives every fraction of a second; the header shows the expression,
  the running sum `Sₙ`, and how many terms `n` you've seen.
- Tap your call. **Right = speed bonus × streak multiplier** (multiplier capped
  so a leader stays catchable). Faster (earlier, fewer terms) scores more.
- **Wrong** reveals the true behavior — convergent sums snap a dashed **limit**
  asymptote onto the chart — and resets your streak.

## Scoring
- Correct call: `speedBonus (130 → 25 over 5s) × multiplier`.
- Multiplier: `1 + floor(streak / 3)`, **capped at ×3** — no runaway.
- Wrong calls cost no points, only the streak.

## How to win
**Highest score when the 55s clock ends.** (Host owns the clock and results.)

## GAMES rubric
- **G** — `converge_v2_game.dart` (`ConvergeV2Game`).
- **A** — `AGENT.md`.
- **M** — this file.
- **E** — `EDUCATION.md`.
- **S** — host-driven `MiniGameSession`; closes to results and re-enters cleanly.
