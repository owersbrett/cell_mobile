# GAME.md — Count Forever (Infinities)

> Canonical spec for the Infinities-scale game. **Self-contained module** — the whole game lives in
> `count_forever.dart` and depends only on the framework session (`lib/games/mini_game.dart`). An agent
> can rebuild this game by editing only this folder; no other game shares its code.

- **Scale (cell):** infinities
- **Game id:** `infinity_counter` (registry spec) · widget `CountForeverGame`
- **Module:** `lib/games/infinities/count_forever/count_forever.dart`
- **One-line concept:** Tap to count, *forever*. The count escalates through deterministic upgrade
  tiers, and the shared **world direction** can be flipped so everyone's taps count *down*.
- **Role:** multiplayer (disrupt). Solo now; built to extend to AI-disruption and real online play.

## Core loop — orchestrated escalation (NO random penalties)

The old design fired a random event every 10 taps, including auto-applied penalties (reverse, reset)
that punished the only action that progresses you. That is gone. Every milestone is now deterministic
and every option is a real upgrade.

Tiers fire off **`_climb`** — a monotonic counter that every click (manual *or* helper) advances. So
**tapping always moves you toward the next tier, even when the world is flipped and your visible score
is dropping.** Progress can never be taken away by a disruption.

| Climb | Event |
|------:|-------|
| **10** | Auto-grant **AUTO-CLICKER** — a helper clicks 1/sec. Pure gift, no choice. |
| **30** | **Choose:** faster helper (×2/sec) **or** +1 per tap. |
| **50** | **Choose:** faster helper **or** more per tap **or** **FLIP THE WORLD** (+100 to you). |
| 80, 122, … | Escalate: doubling helper / tap value, bigger flip bonus, instant bursts. |

Thresholds: `10, 30, 50`, then growing gaps (×1.4). Tap value and helper rate also boost the helper's
output (a click is a click), so late game runs away — on theme for "count forever."

## The disruption facet — shared world direction

`CountDirection` (in the module) is the disruption mechanic: a shared up/down toggle. When reversed,
**all** taps subtract until it's flipped back; concurrent flips resolve by **parity** (two cancel out).
Choosing **FLIP THE WORLD** flips it and pays the chooser a bonus (the bribe for flipping it on
everyone).

This is the per-game expression of the framework-wide rule: *every game offers a way for players to
disrupt each other.* The `CountDirection` abstraction is the seam between game logic and transport.

### Phasing
- **Phase 1 (done):** deterministic tiers + all-positive choices; promoted into `MiniGameHost`
  (session scoring, intro/countdown/results, opponents). Direction is `LocalCountDirection`.
- **Phase 2:** host injects an **AI-driven** `CountDirection` so, when `disruption` is on in solo,
  AI opponents periodically flip the world on you.
- **Phase 3:** host injects a **networked** `CountDirection` backed by `party_net` so real players
  share the toggle (parity resolution across devices).

The host passes a `direction` into `CountForeverGame`; Phases 2–3 swap the implementation **without
touching game logic.**

## Win / end condition
Highest count when the 60s clock ends (host-owned clock + results). `MiniGameSession.addScore` floors
the count at 0, so a flipped world can stall you at zero but never negative.

## Notes for future agents
- Edit ONLY this folder. The game is self-contained; the only framework dependencies are
  `MiniGameSession` and Flutter.
- Tune feel via the `_k*` constants at the top of `count_forever.dart`.
- The big number uses `FittedBox` — it will not overflow at any length (the old RenderFlex bug).
