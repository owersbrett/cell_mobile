# POTATUHS — Delivery

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Delivery ("Shortest Route") — the supply-chain-scale routing game. Shipped build
  in `lib/games/supply_chain/delivery/delivery_game.dart` (`DeliveryGame`) draws delivery stops and
  asks for the shortest route; the GAME.md spec aims this at a perishable potato-empire rework.
- **O — Objectives:** bank the most points by connecting every stop into one route. Two scoring
  levers: **shortness** (how close your total length is to the Held-Karp optimum) and **speed**
  (faster solves bank a time bonus and keep a combo alive). Each solve grows the next route by a stop.
- **T — Tasks (the play to-do list):** drag dot→dot to lay route segments · connect all stops into
  one continuous path · keep it valid (no closed loops, ≤2 lines per stop) · solve fast to hold the
  combo · take the next, larger route (3 → 4 → 5 …).
- **A — Automations (firing in the background):** the **Held-Karp solver** computing each puzzle's
  optimal length to score against · auto-detection that all stops sit on one connected path (instant
  solve) · the solve-flash / flash-text feedback decay · combo tracking across solves · MiniGameHost
  host-owned timer, 3-2-1 countdown, results and wind-down.
- **T — Testing (experimental / in-flight):** the shipped game is the **pure Hamiltonian-path
  version**; the next pass adds **hub stops that take a branch** (the "1 to 1 to 2 to 1 to 1"
  levels). Separately, the GAME.md spec describes a larger reworked direction — a 7-node perishable
  empire (spoilage clocks, yield investment, market events, the "Spud Baron" rival) — the designed
  but not-yet-built future of this scale.
- **U — UX:** a normalized 0..1 board of dot stops · drag-to-connect segment drawing with a live
  finger line · supply-chain orange accent · a solve flash + text + combo readout on each completed
  route. Canvas-drawn board, no raster assets.
- **H — Heuristics (how you actually win):** chase the **optimum** — read the geometry and connect
  nearest neighbors to approach the Held-Karp shortest path · solve **fast** to bank the time bonus
  and keep the combo compounding · avoid dead-ends that force a backtrack on bigger boards · accept a
  slightly-longer fast solve over a perfect slow one when the combo is hot.
- **S — Systems (what makes the world feel alive):** the escalating route that grows one stop per
  solve, a chain that always wants to keep moving · the optimization theme (every route measured
  against the mathematically best) · the supply-chain framing — and, in the spec's future, a living
  **potato empire** of farms, cold chains, saturating markets, and a rival keeping product on the move.
