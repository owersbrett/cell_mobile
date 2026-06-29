# GAME.md — Osmosis

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** cell
- **Game id:** osmosis
- **One-line concept:** Keep a single cell alive by controlling the TONICITY of the solution
  around it — pump water or solute to hold the cell at isotonic turgor while the environment
  keeps drifting hypertonic or hypotonic.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

A lone cell sits in a fluid environment. Water crosses its membrane **toward the higher solute
concentration** (osmosis) — the cell cannot pump water directly, it can only respond to the
balance outside. The environment is unstable: it keeps drifting saltier (hypertonic) or more
dilute (hypotonic). Left alone, the cell either **shrivels (crenates)** as water rushes out, or
**swells until it bursts (lyses)** as water floods in. The player is the lab tech holding the cell
at life by titrating the solution.

---

## Rules (canonical — as implemented in `OsmosisGame`)

1. **The cell's volume is the gauge.** It lives in `0..1`; the **safe isotonic band is
   `0.38–0.62`**, centred on `0.50`. The vertical CELL SIZE gauge (right) shows it with the safe
   band marked green and danger zones red.

2. **Osmosis drives volume.** Net tonicity `T = drift + inject`:
   `dVolume/dt = -_kFlux × T` (`_kFlux = 0.20`). When `T > 0` (**hypertonic**, saltier outside)
   water leaves and the cell **shrinks**; when `T < 0` (**hypotonic**) water enters and the cell
   **swells**; at `T ≈ 0` (**isotonic**) flux stops and volume holds.

3. **The environment drifts on its own.** An autonomous `drift` re-rolls a random target tonicity
   on an interval and eases toward it. As the round progresses, both the **swing range grows**
   (`0.35 → 0.90`) and the **swings get faster** (re-roll `2.4 s → 0.7 s`, ease rate climbs) — the
   accelerate-over-time pressure.

4. **Control = a whole-screen horizontal slider.** Tap or drag anywhere: left half pumps
   **WATER** (pushes the solution hypotonic, `inject < 0`), right half pumps **SOLUTE** (pushes it
   hypertonic, `inject > 0`), centre is neutral. **Let go and the pump eases back to isotonic** —
   the environment then takes over. The top TONICITY meter is the read-out: keep the needle
   centred (green) to stop flux, then over-correct briefly to steer volume back to the band.

5. **Score = time healthy + recoveries.**
   - **`+6 / sec`** while the cell is inside the safe band.
   - **`+35`** each time you bring the cell **back into the band** after it had drifted out
     (a "RECOVERED" callout fires).

6. **Fail-and-recover, not game over.** If volume reaches **`≥ 0.96`** the cell **LYSES**
   ("too hypotonic"); if it reaches **`≤ 0.04`** it **CRENATES** ("too hypertonic"). Either way the
   cell re-forms at healthy turgor `0.50`, the healthy-streak and recovery count reset, and a red
   burst flashes. The 60 s host clock keeps running.

7. **Session length:** 60 s (set by `MiniGameSpec.durationSeconds`). The host owns the clock,
   countdown, score and results. Highest score wins.

---

## Controls

Tap or drag horizontally anywhere — the screen IS the injection slider (handle drawn at the
bottom: ◀ ADD WATER … ADD SOLUTE ▶). Release to ease back to neutral. All rendering is a single
`CustomPainter`. No raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Each second the cell is in the safe band | +6 |
| Recover the cell back into the band after drifting out | +35 |
| Lyse (burst) / crenate (shrivel) | no points; resets streak & recoveries |

`humanMax` ≈ **700**, star thresholds **[220, 450, 700]**.

---

## Win / end condition

60 s timed score attack. The host (`MiniGameHost`) owns the timer, countdown and results.
`OsmosisGame` reports via `widget.session.addScore` / `noteStreak` and gates its loop on
`widget.session.isRunning`. It implements no results screen or restart.

---

## Difficulty curve

A single progress ramp (`progress = 1 − remaining/duration`):
- Drift swing **range** `0.35 → 0.90`.
- Re-roll **interval** `2.4 s → 0.7 s` (faster swings).
- Drift **ease rate** `1.4 → 4.0` (sharper moves).

Early on the solution barely wanders; by the final third it lurches across the full tonicity
range every second, forcing constant counter-titration.

---

## Educational blocks engaged

Osmosis is taught **in the mechanic** (see `EDUCATION.md`): osmosis as water moving toward higher
solute, the **hypotonic / isotonic / hypertonic** trichotomy, **turgor**, and **why cells burst
(lysis) or shrivel (crenation)** — each named on screen exactly as it happens.

---

## Potato angle

Medium. Turgor pressure is why a fresh potato is firm and a dehydrated one goes limp; a potato
slice in salt water visibly shrivels (hypertonic) and one in pure water stiffens (hypotonic) —
the classic osmosis demo. Keep references light; the mechanic carries the lesson.

---

## Session / resume

Uses `MiniGameSession`; fully host-aware. On `isRunning == false` (intro/countdown/finished) the
game sits in a **calm ready state**: drift eases to isotonic and the cell rests at healthy turgor —
auto-starts the instant the host flips `isRunning`. Drop-and-resume of mid-round state
(`_volume`, `_drift`, `_inject`, recoveries) is not persisted; the world re-initialises on mount.
