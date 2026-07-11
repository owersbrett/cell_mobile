# GAME.md — Trace the Constellations

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Rebuilt 2026-07-08 (Brett, cyummu→yumutsu) from the old "Cosmic Web" — which
> made you *guess* hidden dark-matter filaments (void-reading). The pattern is now
> **shown**; the skill is **speed + reaction**. Internal id stays `cosmic_web`
> (only the player-facing name changes); module:
> `lib/games/cosmic_structures/cosmic_web/cosmic_web_game.dart`.

- **Scale:** cosmicStructures
- **Game id:** cosmic_web  ·  **Display name:** Trace the Constellations
- **One-line concept:** A field of stars, one **target constellation** shown as a
  faint ghost figure. **Race to trace it** — drag star → star along the right
  connections before the clock runs — while the sky throws **reaction events**
  (shooting stars, a flaring supernova, a meteor shower) you tap for bonus.
- **Role:** solo high-score (also a party-mode round)
- **Duration:** 60 s (host-owned clock)
- **Lineage:** the on-theme evolution of the drag-to-connect "Cosmic Web" trace —
  same connect-the-nodes core, flipped from *guess the hidden link* to *race the
  shown figure*, plus a reactive bonus layer.

---

## Lore
Humans have drawn pictures in the stars for as long as they have looked up — the
hunter, the bear, the cross. A **constellation** is a pattern our eyes trace across
scattered suns. You are the sky-tracer: connect the stars into the figure before
the night moves on, and catch what streaks past while you work.

---

## Rules (canonical)

1. **A round shows one target constellation:** a set of **star nodes** plus the
   **edges** that form the figure, drawn as a faint ghost outline so you know what
   to draw. Early rounds are **real, recognizable constellations** (Orion, the Big
   Dipper, Cassiopeia, the Southern Cross, Leo…); once those are exhausted / at
   higher difficulty, **procedurally generated** star-figures keep it scaling.
2. **Drag star → star along a ghost edge.** A correct trace **ignites** the edge
   (warm gold), banks points, and grows your chain combo.
3. **A wrong drag** (two stars with no edge between them) **fizzles** — no score,
   chain combo resets, a soft "not a line" cue. Never a game-over.
4. **The rubber-band previews validity:** gold while it would land on a real ghost
   edge, white otherwise — so a misdraw is readable before you commit.
5. **Light every edge to COMPLETE the constellation:** it flares into the finished
   figure (a one-shot reveal — the hunter/bear/etc.), banks a **completion bonus +
   speed bonus** for a fast trace, and the next figure fades in denser & fainter.
6. **Reaction events** cross the sky on a tape-drawn schedule while you trace —
   pure bonus, never required, never a fail:
   - **Shooting star** — a streak across the field; **tap it** before it leaves
     frame for a small bonus.
   - **Supernova** — a star **flares bright then fades** over ~1.2 s; **tap it
     while lit** for a big bonus (small window — the "react fast" beat).
   - **Meteor shower** — a short burst of several quick streaks; rapid taps, each
     a small bonus.
   Events use the game's OWN local RNG (mini-games are network-agnostic — each
   player runs their own instance and only the final score flows back; there is
   no cross-client determinism to honor). They layer *over* tracing — catching
   them without dropping your trace is the mastery.

---

## Controls
**Drag** star → star to trace an edge; **tap** a reaction event to catch it. That
is the whole input. All rendering is a single `CustomPainter` on one ticker — no
raster assets (procedural stars, glow beams, streaks, flares).

Visual language:
- **Star node** — a layered orb (`GameFx.orb`); dim white until all its edges are
  lit, warm gold once fully traced.
- **Ghost edge** — a faint thread showing where a line belongs (the figure to draw).
- **Lit edge** — a bright warm-gold glow beam (`GameFx.glowLine`).
- **Completed figure** — a one-shot bright flare of the whole constellation + its
  name label ("ORION").
- **Reaction events** — shooting star: a fading streak; supernova: a pulsing
  bright flare with a shrinking ring (the tap window); meteor shower: several
  quick streaks.
- **Rubber-band** — gold = lands on a real edge, white = not a line.

---

## Scoring

| Event | Score |
|---|---|
| Trace an edge | `+ (10 + 0.6·figure#)` base, `+ min(combo·2, 20)` chain bonus |
| Wrong drag | 0 — chain combo resets |
| Complete a figure | `+ (25 + speedBonus)`, speedBonus up to **+45** for a fast trace |
| Catch a shooting star | **+15** |
| Catch a supernova (while lit) | **+40** (small window) |
| Catch a meteor (shower) | **+8** each |
| Chain | consecutive correct edges → `session.noteStreak` high-water |

Score = total banked in 60 s. No hard fail; a misdraw only costs the combo and a
moment. Reaction bonuses are the ceiling-raiser a skilled player chases.

- `humanMax`: **2200** (traces figures fast AND catches most reaction events).
- `starThresholds`: **[750, 1500, 2200]** — 1★ trace a few figures, 2★ chain
  cleanly, 3★ trace fast while catching the sky.

---

## Win / end condition
Highest score when the host buzzer ends the 60 s. No sudden death.

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Star count | real figures as authored; procedural `min(14, 6 + figure#)` |
| Edge count | the figure's own edges (procedural: a traceable tree + a few loops) |
| Ghost edge alpha | `0.50 → 0.13` as figure# rises (fainter guide) |
| Completion par | `edges · 1.15 s` (faster traces score the speed bonus) |
| Reaction cadence | events get slightly more frequent as figure# rises |

The scaffold for procedural figures is a **Euclidean Minimum Spanning Tree** plus a
few short loop edges — always fully traceable, echoing how we actually draw
figures across scattered stars.

---

## Session / resume (the S)
Host-driven. The widget watches `session.isRunning`; on the rising edge it calls
`_resetRun()` (clock 0, figure 0, fresh first constellation, no pending events).
When the host ends the run and a new session starts (`phase` → `intro`), the
rising-edge guard clears so the next run replays cleanly. Nothing in the widget
owns the clock, countdown, or results — the host does. A session closes and a
fresh one re-enters with no residual state.

---

## Education (the E — see EDUCATION.md)
Real constellations are the teaching hook: the figures humans drew, the stars that
anchor them, and the truth that a constellation is a **line-of-sight pattern**, not
a physical cluster — its stars can be wildly different distances away. Reaction
events teach transient sky phenomena (meteors = debris burning up; a supernova =
a dying star briefly outshining a galaxy).
