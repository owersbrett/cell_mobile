# Hilbert's Hotel v2 — MAKE ROOM

> Scale: **infinities** · Duration: **55s** · Score unit: **check-ins**
> Self-contained module. One `Ticker` → one `CustomPainter`. No fail state.

## The pitch
A hotel with a room for every counting number 1, 2, 3, … is **already full** —
yet new guests keep arriving. You don't pick a rule from a menu; you **swipe the
guests** and watch the corridor make room.

## How to play (the rules)
The corridor is full before every arrival. Read the arrival, then **swipe**:

| Arrival | Swipe | Bijection enacted | What you see |
|---|---|---|---|
| **1 GUEST** | **→ right** | `n → n+1` (shift up) | everyone slides up one, **room 1 opens**, the guest checks in |
| **A BUS · ℵ₀** | **↑ up** | `n → 2n` (double) | everyone moves to double their room, **every odd room opens**, the bus fills the odds |
| **ℵ₀ BUSES** | **↓ down** | **prime powers** | residents pack the powers of two, the rest of the rooms **flood open** for the buses |
| *(wrong)* | **← left** | `n → n−1` (shift down) | **ILLEGAL** — guest 1 is evicted to room 0; red flash, streak lost |

- A pulsing **gold chevron** on the corridor always points the legal direction —
  the read is glanceable, no symbol-parsing.
- Drag distance on a **→ shift** opens more rooms — a long shift houses more of a
  stream (partial credit for seats legally fit).
- **No feedback gate.** The slide animates, the score ticks live, and the next
  arrival fires immediately. The last ~11s become a **flood of buses** — the
  climax — where you swipe as fast as you can read.

## Scoring (fair, host-owned clock)
- **+points per guest actually checked in** (per-seat value scaled by arrival size
  so a perfect guest and a perfect bus stay comparable).
- **Matched-read bonus** ×1.25 when your swipe is the canonical move for the arrival.
- **Streak multiplier** 1× → 4× (capped — no runaway leader), +1× every 4 legal
  moves; an eviction resets it. Best streak is reported for the mastery award.
- `humanMax 3000`, `starThresholds [800, 1600, 2400]`.

## How to win
Most **check-ins** when the 55s clock ends. Reads in pass-and-play / party mode:
a watcher sees the corridor slide and rooms light up.

## Perf guardrail
One `Ticker` drives `setState`; one `_HotelPainter` draws the corridor, residents,
arrivals, chevron, sparks and the inline toast. No nested animation controllers.
