# POTATUHS — Hilbert's Hotel

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Hilbert's Hotel ("A full ∞ hotel, yet always room for more") — the infinities-scale
  logic puzzle that teaches countable infinity and bijections by making you *fit guests into a full
  infinite hotel*. Self-contained module (`lib/games/infinities/hilberts_hotel/hilberts_hotel_game.dart`,
  `HilbertsHotelGame`); on `BioScale.infinities`. The verb is **APPLY-THE-RULE**.
- **O — Objectives:** post the highest score at the 50 s buzzer (reported via `session.addScore`).
  Sub-goals: read the arrival's *cardinality*, pick the matching reassignment rule **fast** (the speed
  bonus decays over 4.5 s), and chain correct calls to climb the streak multiplier (×2 at 3, ×3 at 6 …).
- **T — Tasks (the play to-do list):** read the arrival banner (1 guest · ℵ₀ bus · ℵ₀ buses) · scan the
  rule cards · **tap the bijection that makes room** (`n→n+1`, `n→2n`, or prime powers) · avoid the
  traps (dump-in-room-1 double-books, `n→n−1` evicts guest 1, "add a room" has no end) · watch the rooms
  shift, bank the bonus, keep the streak alive.
- **A — Automations (firing in the background):** the host-owned 50 s clock (sim gates on
  `session.isRunning`) · one `Ticker` driving every room shift, drop-in, idle bob, failure flash and
  spark burst on a single `CustomPainter` · grade by `rule.solves.contains(arrival)` over **curated
  per-arrival distractor pools** so wrong options always genuinely fail · escalation driven by
  `progress = 1 − remaining/duration` (harder arrivals unlock and get weighted, options grow 3→4, the
  speed window pressures the read) · corridor resets to full each round so the paradox restarts clean.
- **T — Testing (experimental / in-flight):** arrivals and rules are pure **data** (`_Arrival`, `_Rule`,
  `_Shift`, `_kCorrect`, `_kDistractors`) decoupled from the renderer — a new rule (e.g. a Cantor-diagonal
  "rationals are countable" arrival) drops in by adding a `_Rule` + a `_Shift` case, no renderer surgery.
  The seam for harder banks or an "explain-the-failure" sandbox mode.
- **U — UX:** a warm marquee-lit corridor of numbered doors fading into `→ ∞`, every room holding a
  bobbing potato resident · an arrival banner with a cool-blue icon up top · big rule cards in the bottom
  panel · on a correct tap the residents slide to their new rooms (some off into ∞), freed doors glow gold
  and blue arrivals drop in with a green burst · on a wrong tap the failure animates (a pile-up, an
  eviction, a dead-end) with a red flash · a one-line card says exactly why it fit or failed · a calm
  marquee GET-READY state before the countdown.
- **H — Heuristics (how you actually win):** match the *size* of the arrival to the rule — one guest →
  shift up one; a whole bus → double everyone; infinitely many buses → prime powers · answer
  **immediately** (the bonus bleeds away in 4.5 s) · protect the streak: a single wrong rule zeroes the
  multiplier, so when unsure, eliminate the obvious traps first · remember "full" ≠ "no room" — the move
  is always to *rearrange*, never to evict or to build past the end.
- **S — Systems (what makes the world feel alive):** doors that visibly shift, freed rooms that light up
  and new guests that drop in turn an abstract bijection into something you watch happen · the same full
  hotel taking in one guest, then a bus, then infinitely many buses makes the paradox escalate before
  your eyes — the lesson is the mechanic, and the mechanic is the world.
