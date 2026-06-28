# Low-Tier Game Polish — Backlog (C & D)

Grounded review of every C/D-ranked game (one deep-dive per game against the real
code), turned into an ordered, actionable backlog. Companion to the in-app
`RankStore` notes and the `*_FEEDBACK_*.md` format. Each game was critiqued from 5
fixed lenses: **first-timer**, **score-chaser**, **educator**, **game-feel/juice**,
**accessibility/fairness**.

Status legend — type: FEATURE / TUNE / BUG / JUICE / MIGRATE · effort: S/M/L.

---

## Cross-cutting findings (do these once, every game benefits)

1. **Migration is the master lever.** 7 of 8 C games are legacy (no `MiniGameSpec`)
   and own bespoke — sometimes broken — game-over flows. Migrating each to the
   registry/`MiniGameHost` now grants the **locked game-over, cosmic transition,
   1–3 stars, 20/30 streak award, and the 3-view leaderboard** (Match/History/Bests)
   shipped in `lib/games/leaderboard/`. Most "no results screen / no closure"
   complaints evaporate on migration.
2. **Flat scoring, no streak.** Almost every low game scores linearly with no
   combo/streak. The host now has `session.noteStreak()` / `bestStreak` — wiring a
   game's existing chain counter into it is an S-effort juice win (done for Harvest).
3. **Untuned `starThresholds`/`humanMax`.** Cheap, safe tuning is now high-value
   because the star payoff is live. Set explicit cutoffs per game by playtest.
4. **Theme-as-paint.** The biology/physics theme is cosmetic in most; the mechanic
   doesn't teach its scale's concept. Biggest long-term lift, biggest effort.

## Recommended order

1. **Harvest (D)** — registry; safe tuning first. *(in progress)*
2. **Count Forever (C)** — registry; tuning + a real stop/goal mechanic.
3. **Star Collector (C)** — fix the broken instantiation; decide merge-vs-differentiate. **Needs Brett's call.**
4. **Migration wave** — Potato Rush, Farm Panic, Orbital Mechanic, Neuron Connect, Reality Merge → registry, one at a time, each with streak + star tuning.
5. **Delivery (C)** — **gated, pair with Brett**; ~30% implemented, needs design decisions.

---

## Harvest — D (registry `harvest`) · organism — *lowest in catalog*

**Diagnosis:** Flat, low-agency tap-fest. Combo was anemic (+3/step) vs. a single
golden pull (+50); no escalation, muted feedback; fact cards spawn mid-play and
*tax* you (−coins) instead of rewarding. Theme doesn't teach ripeness/biology.

**Done this pass:** `starThresholds [80,160,250]`; combo +3→+5/step (`mini_games_batch2.dart:1491,1611`); wired `noteStreak(_combo)` so the 20/30 streak award surfaces.

**Backlog:**
- Color-code patch ripeness (brown→yellow→green→pulsing-red) + legend — FEATURE/JUICE, M. Teaches ripeness at a glance; helps colorblind.
- Move fact cards to a 1s post-harvest reward window; never overlay active grid; tapping = +1 coin (voluntary, not a tax) — JUICE, M.
- Redesign Helper: from "auto-plays for you" to "rescue N rotten patches" (mistake insurance) — FEATURE, M.
- Rot escalation: pulsing red + tick as a patch nears rot; real score loss on rot — JUICE, S.

## Count Forever — C (registry `infinity_counter`) · infinities

**Diagnosis:** Mechanically sound incremental but narratively hollow — tap-to-increment
with no stop condition, no fail state, no reason the "infinity" theme matters. Flip
disruption is pure upside (no real risk). `starThresholds` unset.

**Backlog:**
- Goal-number + overshoot penalty: round ends when first lands within ±10% of a target; overshoot >10% scores 0 — FEATURE, M. Makes *stopping* a skill. (May want a spec flag e.g. `hasOvershootPenalty`.)
- `starThresholds [200,400,600]` (humanMax 600) — TUNE, S.
- Reframe "Flip the World" as a true risk (lose 25% / tap-value resets / costs to revert) — FEATURE, L.
- Visualise auto-clicker taps (sampled particles) + escalate tier-up payoff with tier — JUICE, M.

## Star Collector — C (legacy `galaxy_collector`) · galactic — **BROKEN + redundant**

**Diagnosis:** Instantiated at `mini_game_page.dart:160` with **no `MiniGameSession`,
but the constructor requires one** (`mini_games_batch3.dart:4932`) — broken legacy
wiring, can't reach party/leaderboard. Also a near-duplicate of Big Bang (tap fading
collectibles + combo) with no differentiation and zero galactic teaching.

**Decision needed (Brett):** **(A) Merge** into Big Bang (retint as "Star Forge", cut this) — S; or **(B) Differentiate** to teach a real galactic concept (parallax: nearer stars faster; orbital arcs) — L.

**Backlog (if kept):**
- Migrate to registry — MIGRATE, M — spec: `durationSeconds 60, scoreUnit 'stars', humanMax 450, starThresholds [120,250,450]`.
- Escape consequence juice (screen jolt + whoosh) — JUICE, S.
- Gentler wave ramp (cap stars, 2.5s floor not 2.0s) — the wave-4 reflex wall is unfair — TUNE, S.

## Potato Rush — C (legacy) · ecosystem

**Diagnosis:** 7 farm-task microgames strung together; scores **+1 per round only**,
no streak. **No results screen** — on life-loss it just stops (UX dead end). Theme
("ecosystem balance") is pure paint — no balance mechanic.

**Backlog:**
- Migrate to registry — MIGRATE, M — spec: `durationSeconds 30, scoreUnit 'tasks', humanMax 30, starThresholds [10,20,30]`. (Inherits the results screen it's missing.)
- Streak system → multiplier, wired to `noteStreak` — FEATURE, M.
- Difficulty curve: cap round-time floor at 1.6s (not 1.4s), gentler drop — TUNE, S.
- (Ambitious) make "balance" real: 3 ecosystem bars each task nudges; win = keep all in the green zone — FEATURE, L.

## Farm Panic — C (legacy) · farmSystem

**Diagnosis:** Incoherent tuning across 3 timescales (potato flow vs. bug threshold
vs. weed linger); 8s feedback vacuum at the start; the best score path (spam taps
bugs/weeds) conflicts with the intended mechanic (maintain flow). "Panic" never
escalates — bugs arrive on a fixed timer, not in response to you slipping.

**Backlog:**
- Migrate to registry — MIGRATE, M — spec: `durationSeconds 30, scoreUnit 'points', humanMax 380, starThresholds [120,220,380]`.
- Tie bug spawn rate to flow deficit (low flow → earlier/faster bugs) — TUNE, M. Creates the missing feedback loop.
- Immediate "+FLOW" feedback on first swipe; potato pulse before harvest — JUICE, S.
- Let sustained-flow actions feed combo, not just discrete taps — TUNE, L.

## Orbital Mechanic — C (legacy `solar_sort`) · solarSystems

**Diagnosis:** Solid pedagogy, but opens on an **impossible round** (Sun:Mercury ~285:1)
→ players fail instantly and quit. Log-error scoring is opaque (no accuracy %). Ignores
the host clock. Tacked-on spiral finale.

**Backlog:**
- Reorder rounds easy-first (Venus–Earth before Sun–Mercury) — TUNE, S. Removes the failure wall.
- Show accuracy % on the reveal card — FEATURE, S. Demystifies scoring.
- Migrate to registry (keep `enabled:false` until tuned) — MIGRATE, M — spec: `durationSeconds 90, scoreUnit 'cosmic pts', humanMax 3500, starThresholds [1500,2500,3500]`.
- Live circle preview while drawing + haptic on "perfect scale" — JUICE, M.

## Neuron Connect — C (legacy) · cosmicStructures

**Diagnosis:** Premium juice, but tap-to-cycle input has no analog skill, and puzzle
generation is too generous (blocker ≤22%, lock ≤15%, always BFS-solvable) → brute-force
rotate-until-solved. GAME.md's 3D-layer ambition is unimplemented.

**Backlog:**
- Migrate to registry — MIGRATE, M — spec: `durationSeconds 60, scoreUnit 'circuits', humanMax 18, starThresholds [8,14,18]`.
- Tune puzzle density up (blocker→0.35 cap, lock→0.25 cap; re-verify solvability) — TUNE, S.
- Flick-to-aim input (swipe sets node direction) per GAME.md — FEATURE, M.
- "Nearly complete" live-path highlighting (bright live wires vs. dim dead) — JUICE, S.

## Reality Merge — C (legacy) · multiverseAll

**Diagnosis:** Bubble-growth + rival-defense physics. **Passive area scoring dominates**
active taps → optimal play is to sit still (inverted intent). Abstract "fold realities"
theme is confusing and load-bearing debt. Low skill ceiling (rivals only get bigger).

**Backlog:**
- Rebalance: halve passive area points, raise tap rewards (rival shrink +25, swallow +30) — TUNE, S. Makes engaging worth it.
- Migrate to registry — MIGRATE, L — spec: `durationSeconds 60, scoreUnit 'mass', humanMax 450, starThresholds [150,300,450]`.
- Clearer bubble identity (label/shape, dead-tap feedback) + visual onboarding — JUICE, S.
- Rival escalation *phases* (dumb → seeking → swarming every 20s) — FEATURE, M.
- **Open question:** commit to the multiverse theme (quantum-collapse anchor) or drop it for a clear "Bubble Dominion" framing? Needs Brett.

## Delivery — C (legacy `supply_chain`) · supplyChain — **GATED (pair with Brett)**

**Diagnosis:** ~30% of its GAME.md spec. Bare node-placement loop with passive cash
accumulation; **no spoilage, no market events, no saturation** → no tension, optimal
strategy emerges in ~15s. Cash pops render off-screen (placeholder at -9999).

**Backlog (pairing session):**
- Spoilage clocks on nodes + overflow penalty — FEATURE, M. The core missing tension.
- Periodic market events (blight / boom / crash at 15/30/45s) — FEATURE, L.
- Market saturation (price dip on oversupply) — FEATURE, M.
- Migrate to registry — MIGRATE, L — spec sketch: `durationSeconds 45, scoreUnit 'potatoes sold', humanMax 450, starThresholds [150,300,450]`.
- Fix FxPop positioning (`mini_games_batch2.dart` ~3746, -9999 placeholder) — BUG, S.
- **Open questions for Brett:** (1) spoilage severity (3s harsh vs 8s strategic; scale with difficulty?); (2) events random vs. authored per skill tier?
