# Codebase Fidelity Review — cell_mobile (Explore the Cell)

**Date:** 2026-07-01 · **Method:** 5 parallel review agents across perf-guardrail, architecture, GAMES-rubric docs, analyzer/tests/gates, and general code smells. Read-only; nothing was edited.

**Scope:** 128 enabled registry specs · 127 game-widget modules · shared host + registry + catalog.

---

## TL;DR verdict

The codebase holds its **hardest** contracts faithfully and its **softest** ones loosely.

- 🟢 **Rock-solid:** single-Ticker discipline (100%), NaN/Infinity math (uniformly softened), module self-containment (zero cross-game imports), host contract (addScore + isRunning in every game), registry↔catalog reconcile exactly, the 4 CI gates all pass.
- 🟡 **Eroding:** internal file structure (15 files >1200 lines, 2 god-widgets), text-rendering duplication (65 raw `TextPainter` sites), a two-font split shipping live, per-particle TextPainter perf tax.
- 🔴 **Actual breakage:** the lint safety net is silently OFF, 4 real test failures, 3 latent inverted-clamp black-screens, and doc holes in 9 enabled games.

The single most alarming finding is quiet: **`flutter_lints` fails to load**, so ~28 dead-code warnings accrue unenforced.

---

## 🔴 HIGH — fix first

### 1. Lint safety net is dark
`analysis_options.yaml:10` includes `package:flutter_lints/flutter.yaml` — **file-not-found**. The recommended ruleset is not loaded; the low info-lint count is an artifact of the net being off, not cleanliness. Fix the include (or add `flutter_lints` to dev_deps) and the ~28 accumulated warnings become visible/enforced.

### 2. Test suite is not green — 4 real failures (101/106 pass)
- `test/party/board_play_test.dart:16` — **compile error**: non-exhaustive `PartyPhase` switch missing `cardDecision` (also the lone analyzer *error*). Poisons the shared compile batch → collateral failure of `party_net_test` (which passes in isolation).
- `test/game_catalog_test.dart` — **stale assertion**: "particles has exactly 2 games" — actual is 6. Update the count.
- `test/party_flow_widget_test.dart` ×2 — party-flow UI regressions: `ROUND 1 / 5` label no longer found (board not reached / label changed), and a live **RenderFlex overflow (3px vertical) in `mini_game_host.dart:416` `_IntroView` Column**.

### 3. Three latent inverted-clamp black-screens
`.clamp(lo, hi)` throws when `hi < lo`; inside `paint()` with `shouldRepaint => true` it re-throws every frame → black screen (the confirmed historical mechanism).
- `organelle/powerhouse/powerhouse_game.dart:517` — `hi = h - 196`; throws when canvas height < 286px. **Most reachable** (short/embedded web views). Has an `if (h<=0) return;` guard the clamp defeats.
- `organelle/powerhouse_v2/powerhouse_v2_game.dart:583` — identical; the v2 carried the bug over.
- `organism/homeostasis_v2/homeostasis_v2_game.dart:408` — guard checks `_w` but not `_h`; throws on very short viewport.

(Lower-risk same-class sites, only fire <~30–150px: pest_patrol, forage_v2, space_rush, constants/constants_v2.)

### 4. Doc holes — 9 enabled games not truly GAMES-complete
~111 of 128 games are rubric-complete (G/A/M/E; M satisfied by GAME.md). Gaps:
- **Zero docs:** `planet_catch`→`planets/orbit_catch`, `reality_merge`→`multiverse/reality_merge`.
- **No doc folder at all:** `tissue_layer`, `farm_panic` (widgets under `views/screens/mini_game_page/games/`).
- **Missing AGENT.md + EDUCATION.md** (only GAME.md+POTATUHS.md): `organ_rush`, `harvest`, `everything`, `market_trader`, `delivery`.
- *Judgment call:* 8 arcade games (`big_bang`, `corners`, `collider`, `accelerator`, `atom_builder`, `molecule_mixer`, `hungry_cell`, `mitosis_rush`) have only scale-level EDUCATION.md, not per-game.

---

## 🟡 MED — structural debt

### 5. Dead files to delete (2)
- `financial/financial_trading/financial_trading_game.dart` — **zero refs**; a dead pre-host-contract twin of the live `market_trader` (duplicates `FinancialTradingGame` + 8 more classes, self-draws its own game-over). The registry builds `FinancialTradingGame` from `market_trader.dart`, not this.
- `arcade/grow_the_plant.dart` — **zero refs** (2115 lines).

### 6. Files not separated into logical components (weakest axis)
Module boundaries are clean, but internal structure rots in big files. 15 game files >1200 lines. God-widgets:
- `party/screens/party_page.dart` — 3424 lines; `_BoardScreenState` ~1200 lines (flow + board + dice painter + all screens).
- `views/screens/mini_game_page/games/farm_panic_game.dart` — 2690 lines; `_FarmPanicGameState` ~1100 lines, 97 methods, 13 inner data classes inlined.
- Also >2000: `mini_game_registry.dart` (2841, chokepoint), `mini_game_page.dart` (2335), `mitosis_rush` (2051).
- `mitosis_rush`/`tissue_layer`/`big_bang`/`molecule_builder` are large *and* carry **no `Feel constants` block** — tuning buried in hot paths.

### 7. Text-rendering duplication (highest-leverage cleanup)
`GameFx.text()` exists in `fx.dart:137` but is bypassed: **~19 files hand-roll `_drawText`/`_paintText`**, **65 files instantiate `TextPainter` directly** — the single most-repeated block. Correct cached models to copy: `market_trader.dart:1225`, `galaxy_classify:522`, `harvest`.

### 8. Two body fonts ship live
`_kFont` is defined 18× and they disagree: some → `'Avenir'` (45 files hardcode this string), others → `Potatuhs.bodyFont` (Outfit), incl. `party_page.dart:23` and `mini_game_host.dart:394`. **The app renders two different body fonts depending on which game you're in.** Routing all text through one `GameFx.text` source (see #7) would fix this incidentally.

### 9. Per-particle TextPainter perf tax
`GameFx.text()` builds+`layout()`s a fresh `TextPainter` per call; particle-heavy games call it per-particle per-frame: worst in standard_model(_v2), decay_chain(_v2), electron_shells(_v2), membrane_gate(_v2), nephron(_v2), everything.dart, quantum_foam(_v2). Cache the glyph (as market_trader/galaxy_classify/harvest do).

### 10. Per-frame `setState` instead of repaint-Listenable
~14 games `setState((){})` every tick + `shouldRepaint=>true` (rebuilds the whole subtree) instead of `super(repaint: notifier)` + `shouldRepaint=>false` (as cell_type/nephron/isotopes/market_trader already do). Several **v2 rewrites did not adopt the fix their siblings have**.

### 11. Shared particle system
`class _Spark`/`_Particle` re-declared ~35× with no shared util despite `GameFx` being the natural home. `PotatoArt` (the mandated canonical potato renderer) is referenced by only **3 files** — most potato-drawing is presumably still hand-rolled ovals.

---

## 🟢 Clean (stated once)

- **Single-Ticker:** 100% compliant — one `createTicker` per State, zero multi-ticker.
- **NaN/Infinity math:** uniformly softened (`distSq.clamp(minSq, 1e9)`, `max(radius, softening)`); `structure_formation` + `harvest` are reference-quality.
- **saveLayer:** only used in the correct gated-fade pattern.
- **Cross-game imports:** none — games import only shared framework/data utils.
- **Host contract:** addScore + isRunning gating in every game; host-owned countdown/results respected.
- **Registry↔catalog↔folder:** reconcile exactly — 128↔128, no drift, no duplicate ids.
- **CI gates:** `four_per_scale`, `ux_pass`, `mini_game_host_lock` all PASS.
- **Suppressions:** minimal + benign (1 generated `ignore_for_file`, 2 targeted deprecation ignores, 1 TODO, 0 FIXME/HACK). No analyzer rules explicitly disabled (the flutter_lints break in #1 is the real hole).
- **Dead code within files:** essentially none (no commented-out blocks, no `_unused` markers).

---

## Recommended order of attack

1. **Fix `flutter_lints` include (#1)** — restores the safety net; everything else gets easier.
2. **Green the suite (#2)** — 1 compile fix, 1 stale count, 2 party-flow regressions (incl. the live `_IntroView` overflow).
3. **Patch the 3 black-screen clamps (#3)** — powerhouse first (most reachable).
4. **Delete the 2 dead files (#5)** — trivial, removes confusion.
5. **Fill the 9 doc holes (#4)** — dispatch per-game agents (esp. the 4 with zero docs).
6. **Longer arc:** the 38 base/v2 pairs need judging (pick a winner, disable the loser); text-rendering consolidation (#7) + font unification (#8) is the highest-leverage refactor and touches nearly every game without changing game logic.
