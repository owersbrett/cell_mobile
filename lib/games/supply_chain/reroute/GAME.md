# GAME.md — Reroute!

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** supplyChain
- **Game id:** reroute
- **One-line concept:** Several source farms/ports feed your factory along routes; disruptions
  knock routes and sources offline live — tap a healthy alternate to **reroute** and keep the
  factory fed.
- **Role:** solo high-score (also party-mode round)
- **Six-in-one?** no
- **Duration:** 60 s (host-owned clock)

---

## Lore

You run a potato factory that turns spuds into fries and chips. Four suppliers feed it: a cheap
**Backyard Farm** right next door, a **River Port**, a **Highland Farm**, and a slow but dependable
**Overseas Port**. Goods travel one active route into the factory's input **silo**; the factory
eats from that silo to produce. Storms close routes. Droughts empty farms. The factory never stops
eating — so when your supply line breaks, the silo runs down and production **starves** until you
switch to a healthy source. The cheap, close suppliers are exactly the ones that fail most, so
leaning on a single fast farm is fragile. Keeping diverse backups ready is the whole game.

---

## Rules (canonical)

1. **Four sources sit on the left, the factory on the right.** Each source has its own route (edge)
   to the factory. Exactly **one** source is *active* at a time — it feeds the silo.
2. **The active route refills the silo; the factory always consumes it.** A healthy active source
   delivers faster than the factory eats, so the silo fills. The silo (`_buffer`, 0..1) is shown as
   a vertical gauge beside the factory.
3. **The factory produces — and scores — proportionally to how full the silo is.** A topped silo
   produces fast; a nearly-empty silo trickles; an **empty silo produces nothing** (STARVING).
   Each whole unit produced = `session.addScore(1)`.
4. **Disruptions strike on a shrinking timer:**
   - **Storm (route closure):** a route goes DOWN for a few seconds — drawn broken/dashed red.
   - **Drought (depletion):** a source's stock empties to 0 — it regrows slowly over time.
5. **Tap a source to reroute supply to it.** Only **usable** sources (route up AND stock > 0) can
   become active. Tapping a down/empty source flashes a warning and does nothing.
6. **Sources regrow stock over time**; the active source slowly draws its own stock down, nudging
   you to spread the load rather than ride one farm forever.
7. **Escalation:** disruptions get more frequent (≈5.2 s → 2.2 s interval) and, after 35 s, can hit
   **two routes at once**. Targeting is weighted by `failBias` — the **cheapest/closest** routes
   (Backyard Farm highest) fail most; the Overseas Port rarely fails.
8. **Fairness guard:** a disruption never leaves zero usable sources — there is always at least one
   route you can reroute to.

---

## Controls

**Tap** a source node to make it the active supply line. That is the only input. All rendering is
`CustomPainter` on one ticker — no raster assets.

Visual language:
- **Objective strip** — a persistent one-line band along the very top naming the score driver:
  *"REROUTE around the blockage — keep the SILO full · fuller silo = points faster."* Always visible
  in play (cached static painter, drawn once — not per frame).
- **How-to hint** — a green pointer line at the bottom, *"◀ TAP a healthy source (blue = READY) to
  reroute the line,"* that eases to invisible after the player's **first successful reroute**.
- **Sources** — orbs on the left; teal = feeding, blue-grey = ready backup, red = down/empty. A
  ring arc shows each source's remaining **stock**; a label reads FEEDING / READY / DOWN / EMPTY.
- **Active route** — bright teal flowing beam with travelling goods dots.
- **Idle route** — dim line (a backup standing ready).
- **Down route** — dashed red with a ✕ break and a storm spark.
- **Factory** — orange orb on the right with a **SILO** gauge (green → sienna → red as it drains) AND
  an **OUTPUT meter** below it — a horizontal bar + live `+N.N/s` readout that rises green as the silo
  fills, so the score-driver ("full silo → faster points") is directly observable. Factory turns red
  and shows STARVING when the silo empties.
- **Score pops** — floating `+N` rises off the factory each production tick; a `LINE OPEN` pop +
  a spray of delivery particles travel the newly-live route on every successful reroute.
- **Banner** — transient line near the top ("Storm closes River Port!", "Rerouted to Highland Farm").

---

## Scoring

| Event | Score |
|---|---|
| Each unit produced (silo non-empty) | +1, at a rate of `4.0 × buffer` units/sec |
| Silo empty (starved) | 0 — production stops until a route is restored |
| Streak | consecutive units produced with no starve → `session.noteStreak` high-water |

Score = total units produced in 60 s. There is no hard fail/game-over; starvation simply costs you
production time. Keeping the silo topped (a strong source) AND surviving shocks (diverse backups)
is what maximises the count.

- `humanMax`: **150** (a skilled player keeping near-continuous, well-fed production).
- `starThresholds`: **[60, 110, 150]** — 1★ survive, 2★ stay fed through the shocks, 3★ near-optimal.

---

## Win / end condition

Highest units produced when the host buzzer ends the 60 s. No sudden death.

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Disruption interval | 5.2 s → 2.2 s by t = 50 s (+ up to 1.4 s jitter) |
| Simultaneous hits | 1 until 35 s; then 50% chance of 2 at once |
| Closure length | 5.0 s → 3.0 s by t = 50 s (shorter but more frequent late) |
| Target weighting | `failBias` — Backyard 4.0, River 2.0, Highland 1.6, Overseas 0.6 |

---

## Tunables (in `reroute_game.dart`)

| Constant | Value | Purpose |
|---|---|---|
| `_consumption` | 0.16 /s | Factory silo drain (the hunger). |
| `_baseProd` | 4.0 /s | Production at a full silo. |
| `_activeDrain` | 0.06 /s | Stock the active source loses. |
| `_regen` | 0.05 /s | Stock every source regrows. |
| Source yields | 0.42 / 0.34 / 0.30 / 0.24 | Net positive vs consumption; cheap = fast, overseas = slow. |

---

## Session / resume (the S)

Host-driven. The widget watches `session.isRunning`; on the rising edge it calls `_resetSim()`
(fresh silo, full sources, active = Backyard Farm, first disruption scheduled). When the host ends
the run and a new session starts (`phase` returns to `intro`), the rising-edge guard clears so the
next run replays cleanly. Nothing in the widget owns the clock, countdown, or results — the host
does. A session can close and a fresh one re-enter with no residual sim state.
