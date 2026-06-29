# GAME.md — Lobbying

> Canonical spec for the financial-scale **Lobbying** mini-game. Light potato-politics SATIRE about
> public choice: you run a spud-lobby PAC, spend an influence budget on the right officials, and swing
> bills your way before the vote timer runs out. Tone is playful, never preachy.

- **Scale (cell):** financial
- **Game id:** `lobbying` (widget `LobbyingGame` in
  `lib/games/financial/lobbying/lobbying_game.dart`)
- **Role:** host-integrated mini-game. Score = total **payouts banked** in 60s, pushed to the host
  session via `session.addScore` on every passed bill. The host (`MiniGameHost`) owns the
  clock / countdown / results.

## Core loop
1. A **bill** comes up for a vote (e.g. "Fryer Subsidy Act"). It has a **payout** if it passes, and a
   panel of **officials** (5 → 7 as the game escalates). It needs a **majority** of YES votes to pass.
2. Each official has a **leaning** (a starting yes-chance, 0–98%) and a **price** (how expensive they
   are to move). You spend your **war chest** on them with the selected **DONATE** amount.
3. A live **PROJECTED pass-%** (exact poisson-binomial over the panel) shows the aggregate odds. You
   watch it move as you spend — that's the whole teaching surface.
4. When the **vote timer** hits zero (or you tap **CALL VOTE** to resolve early), each official rolls
   against their final yes-chance. Enough YES → the bill **PASSES** → payout banks into your score and
   refills the war chest. Too few → **FAILED**, and your spend is gone.
5. A fresh bill spawns immediately. Repeat for 60 seconds.

## The cost → probability curve (the lesson, made visible)
- **Diminishing returns.** Influence on one official follows a saturating curve
  `swing = maxSwing · (1 − e^(−units/scale))`, where `units = invested / (price × unitCost)`. Each card
  shows a live **"next $D: +Δ%"** marginal preview — the Δ visibly shrinks the more you pour in.
- **Where a dollar moves the needle most:** a **cheap swing vote near 50%**. Padding a sure thing
  (already ~90%) or a hopeless lost cause (high price, low lean) barely moves the projected %. The
  player learns to allocate at the margin — concentrated, pivotal spending.
- **Rival lobby pushback.** A competing lobby drags officials back over time (the `opposition` term),
  concentrating on the ones leaning your way. Win the vote before they erode your gains.
- **Scandal from overreach.** Spending **past the saturation point** heats an official up (visible
  SCANDAL-RISK bar). Max heat → **SCANDAL**: you lose a chunk of the war chest and the bill collapses.
  Overspending on one official is doubly punished — wasted money *and* scandal risk.

## Controls / UI (top → bottom)
- **Bill banner:** title + a "who-wins · who-pays" subtitle (the concentrated-benefit / diffuse-cost
  framing), payout chip, NEED k/n, big **PROJECTED %** (red→green), and the **vote timer** bar.
- **Officials list:** one tappable card each — potato portrait, name, leaning chip, **yes-% bar**,
  `$ in` / `price×`, the **marginal preview**, and a heat / scandal-risk bar when warm.
- **Control bar:** **WAR CHEST** and **BANKED** readouts, the **CALL VOTE** button (resolve early to
  bank faster), and the **DONATE** size selector ($10 / $25 / $50 / $100).

## Escalation (over the 60s)
Read from `session.remaining`: faster vote timers (~11s → 6s), bigger payouts ($160 → $440), larger
panels (5 → 7 officials), pricier officials, and stronger rival-lobby pushback.

## Scoring / win
Score = **cumulative payouts banked** (`session.addScore(payout)` per passed bill). Consecutive passes
build a streak (`session.noteStreak`). Failed bills and scandals reset the streak; the session clamps
score at ≥ 0. Most banked at the buzzer wins. Tuning lives in the **registry spec** (out of this game's
scope): `humanMax: 1800`, `starThresholds: [600, 1100, 1800]`.

## Implementation
- Self-contained in `LobbyingGame` (`lobbying/lobbying_game.dart`); constructor
  `LobbyingGame({super.key, required MiniGameSession session})`. One `AnimationController` ticker drives
  the sim; it only advances while `session.isRunning`. Background + FX are `RepaintBoundary`
  `CustomPainter`s; the small officials list rebuilds per frame (≤ 7 cards — cheap).
- Depends only on `fx.dart`, `mini_game.dart`, `theme/potatuhs.dart` — no other game.
- **Registry note (out of scope):** add the `lobbying` spec to `mini_game_registry.dart` plus
  `import 'financial/lobbying/lobbying_game.dart';`, and a `CatalogGame` in `game_catalog.dart`. The
  exact spec literal is in AGENT.md / the handoff report.
