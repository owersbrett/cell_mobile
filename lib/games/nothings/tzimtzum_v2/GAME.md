# GAME.md — Tzimtzum v2 (trace the steady withdrawal)

> Canonical spec for the UX-pass alternative to Tzimtzum. The lesson is unchanged — a steady,
> constant-rate self-contraction that withdraws to make space — but the **input is a single pointer** and
> the **arc accelerates to a climax**. You press and drag the light's edge inward, keeping it on a guide
> ring that contracts at a perfectly constant rate. The verb: **trace a steady inward contraction**.

- **Scale (cell):** nothings (shares the scale with Big Bang and Bit Memory — a scale may host more than one game).
- **Game id:** tzimtzum_v2 (widget `TzimtzumV2Game` in `lib/games/nothings/tzimtzum_v2/tzimtzum_v2_game.dart`).
- **Role:** host-integrated mini-game. Score is pushed to the host via `session.addScore`. The host
  (`MiniGameHost`) owns the ~50s clock, countdown, score HUD and results screen — the widget renders
  ONLY the play area.

## Why a v2 (what the teardown demanded)

The original (`tzimtzum`) scored **16/35**. Its three named failures:

1. **Two-finger pinch only** (`onScaleUpdate`, `pointerCount >= 2`) — *unplayable with a mouse* on the web
   deploy target, and no visible thing to grab. **v2 fix:** a **single-pointer press-and-drag** — the
   light's edge follows your pointer's distance from center. Works with one finger or a mouse. A visible
   **grab knob** sits on the light edge as the affordance.
2. **Abstract, instrument-heavy goal** — a RATE gauge + STEADINESS meter + hold arc had to be read before
   the verb made sense. **v2 fix:** a single **guide ring** (the pace ghost) contracts at the ideal rate;
   "steady = keep your edge on the ring" is a **<3s read with no gauge**. The light rim turns green when
   aligned.
3. **Decelerating arc** — holds *lengthened* (2s→5s) as tolerance tightened, so the run sagged. **v2 fix:**
   each successive withdrawal comes **faster** (`_dur` 5.6s→2.6s) with a **tighter** band — the arc
   accelerates to a tense climax, with a flagged **FINAL WITHDRAWAL** beat in the closing seconds.

Kept intact (per the teardown's "Keep"): the void-grows-as-light-withdraws visualization, and the
**alignment × completion** scoring that honestly encodes "constant, restrained contraction."

## The verb (single pointer)

Press anywhere and **drag toward the center** to pull the light's edge inward (withdraw), or out toward
the rim to release it. Drag distance from center = how withdrawn the light is. One pointer, mouse-friendly.
The edge **chases** your pointer smoothly (`_kFollow`) so a flick can't teleport onto the guide — you must
*track* continuously.

## The loop

1. **VESSEL BEGINS.** A dashed **guide ring** starts at the rim and contracts inward at a constant rate
   over `_dur` seconds. The callout reads `WITHDRAW`.
2. **THE TRACE.** Drag the light's edge inward to keep it **on the guide ring** the whole way down.
   - **Ahead of the guide** → you collapsed too hard (**TOO FAST**): alignment drops.
   - **Behind the guide** → you barely contracted (**TOO TIMID**): alignment drops.
   - **On the guide** → a steady, constant contraction: the rim glows green, max alignment.
3. **BLOOM.** When the guide reaches the center the vessel resolves: space blooms, a burst fires sized by
   how well it was traced, a `+points` pop rises, and a verdict flashes — `PERFECT` / `STEADY` /
   `A TOUCH FAST` / `A TOUCH TIMID` / `TOO FAST` / `TOO TIMID` (and `CREATION` for a perfect final vessel).
4. **NEXT, FASTER.** The next vessel starts with a **shorter** duration and **tighter** tolerance.

## Live feedback (on-canvas, no gauges)

- **Guide ring** — a dashed, slowly-spinning ring that contracts at the ideal rate. Glows green + thickens
  when your edge matches it. A soft **tolerance halo** shows the band you must stay inside.
- **Light rim** — your control edge; lerps violet→green with live alignment and blooms brighter on contact.
- **Grab knob** — at 12 o'clock on the light edge: the "drag me inward" affordance.
- **SPACE CREATED bar** — a public, cumulative fill bar at the bottom (legible for pass-and-play
  spectators), gradient violet→green.

## Scoring

Per vessel: `score = round(110 × avgAlignment)`, capped at 110 — **no runaway**.
- **avgAlignment** = `∫ alignment dt ÷ ∫ dt`, where `alignment = clamp(1 − |edge − guide| / tol, 0, 1)`.
- A **clean** withdrawal (`avgAlignment ≥ 0.8`) increments the streak, reported via `session.noteStreak`
  for the results-screen streak award. Any non-clean withdrawal resets the streak.
- Both **too fast** and **too timid** drive alignment toward zero — the band is symmetric, exactly as in v1.

## How to win

Bank the most space before the ~50s buzzer. A smooth, even trace that stays parked on the ring beats a
jerky one — exactly the v1 lesson, now with a single legible target instead of a gauge. Clean back-to-back
withdrawals build a streak (mastery award), and because later vessels are faster and tighter, the climax
rewards control under pressure rather than dragging into longer holds.

## Acceleration (difficulty ramp)

| Vessel index | Withdrawal duration | Alignment tolerance |
|---|---|---|
| 0 | 5.6s | ±0.24 |
| 4 | 3.9s | ±0.17 |
| 8+ | 2.6s (floor) | ±0.095 (floor) |

Later vessels contract **faster** at a **tighter** band — the run **accelerates** instead of decelerating.

## Tuning (in `tzimtzum_v2_game.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `_kTravel` | `0.84` | Fraction of field radius a full withdrawal contracts across. |
| `_kFollow` | `16.0` | How fast the edge chases the pointer (prevents teleport-to-guide cheese). |
| `_kBaseDur` / `_kDurStep` / `_kMinDur` | `5.6` / `0.42` / `2.6` | Withdrawal-duration ramp (accelerating). |
| `_kBaseTol` / `_kTolStep` / `_kMinTol` | `0.24` / `0.017` / `0.095` | Alignment band ramp (tightening). |
| `_kScorePerVessel` | `110` | Points for a perfectly traced withdrawal (the cap). |
| `_kCleanAlign` | `0.8` | Streak-qualifying average alignment. |
| `_kSpaceFull` | `900` | Cumulative score that fills the SPACE CREATED bar. |
| `_kBloomTime` | `0.85` | Bloom/result beat duration between vessels. |

**Registry calibration:** `humanMax = 950`, `starThresholds = [350, 600, 850]`. Reasoning: over ~50s a
skilled player traces ~10–11 vessels averaging ~85–95 pts (max 110/vessel), so ~900–950 is a strong human
ceiling; one star rewards a few steady traces, three stars demands a near-clean run that holds the edge on
the ring through the fast, tight late vessels.

## Implementation notes

- Self-contained in `TzimtzumV2Game`. Constructor is `TzimtzumV2Game({super.key, required MiniGameSession session})`.
- One `Ticker` → one `CustomPainter` (`_TzimtzumV2Painter`) inside a `RepaintBoundary`. No per-frame
  `setState` over a large widget tree; the whole play area is a single `CustomPaint`.
- Input is a `Listener` (`onPointerDown/Move/Up/Cancel`) — **single pointer**, so it works with a mouse on
  the web build. Geometry (center, max radius) is recomputed each build from the laid-out size.
- The game only acts while `session.isRunning`; it auto-starts the first vessel when the host flips into
  play and renders a calm ready state before then (the host overlays its own countdown on top).
- Education is **in the mechanic**: the light physically withdraws to make space, and the constant-rate
  trace *is* the lesson of measured, restrained contraction. Full write-up in `EDUCATION.md`.
