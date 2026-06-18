# Explore the Cell — NORTH STAR

> The single source of truth for what this project is, how it's structured, and the
> rules any agent (human or AI) must follow when building inside it. When in doubt,
> this document wins. Keep it current — it is what we spin agents off of.

Last synchronized: 2026-06-17

---

## 1. What this is

**Explore the Cell** is not one game. It is a **game-of-games** — a Mario Party /
WarioWare-style experience where characters navigate a board, and each region of that
board is a **scale** (a "cell"). When you land in a scale's territory, you choose one of
that scale's mini-games and play it.

- Some mini-games are **solo** (chase the high score).
- Some are **disruptive** (interfere with your teammates).
- Some mini-games are themselves **six-in-one** (a bundle of micro-games, WarioWare-style).
- The whole session is **droppable and resumable** — you can put it down and pick it back up.

This is **our first game**, and it is really many games. After this comes **Hot Potato
Games** — many more games, all learning-based, structured differently (not Mario Party).
What we build here — the conventions, the manual, the agent workflow — becomes standard
practice.

---

## 2. Vocabulary (use these words precisely)

| Term | Meaning |
|---|---|
| **Main game** | The **board game** itself (Mario Party-style) — the layer players navigate that **triggers** the mini-games. When Brett says "the main game," he means this board layer, NOT an individual mini-game. |
| **Mini-game / Game** | A playable game triggered from the main game, living on a scale. (Same as "Game" below.) |
| **Cell / Scale / Dominion** | One of the 22 zoom levels (nothings → infinities). On the board, a scale is a *dominion* a character moves through. "Cell" and "scale" are interchangeable. |
| **Game** | A playable mini-game that lives on a scale. A scale has **at least one** game; the target is **~5**. |
| **Block** | An **educational** unit that occupies a scale (e.g., "Quarks", "Mitochondria"). Stored today in `lib/data/scales/<scale>_entities.dart` as `BioEntity`s. |
| **Manual entry** | The player-facing "how to play" for one game. All entries together = **the Manual**. |
| **Agent doc** | Per-game `AGENT.md` — the context an AI agent needs to work on that game safely and well. |
| **Scene** | The isolated runtime container a game plays inside. A scene must always be **escapable**. |

---

## 3. Targets

- **~5 games per scale** (1–5 are all valid). 22 scales → **~78–110 games** total.
- **Every scale must have at least one *fun* game.** That is the bar. Exact ordering of
  scales and which game goes where is **not locked** — do not over-optimize ordering yet.
- **Every kept scale's educational blocks must associate with a game.** If a scale's
  blocks have no game association and we can't make one, **cut the scale.**

---

## 4. Design principles (non-negotiable)

1. **Procedural, Canvas-drawn assets only.** Everything is `CustomPainter` + particle
   effects + procedural drawing. **No PNG/JPEG raster assets.** This is a hard preference
   and the entire existing library already honors it.
2. **Rules are the asset; implementation is disposable.** A game's value lives in its
   *rules*, not its current code. If the concept is good but the execution is bad
   (e.g., the Multiverse game — good idea, terrible graphics), we keep the rules and
   **re-implement from scratch.** This is why `GAME.md` (the spec) outranks the `.dart`.
3. **Educational association is required.** A scale we keep must have at least one game
   that meaningfully engages its blocks. Cosmetic theming is not association.
4. **Sessions are droppable/resumable.** Nothing may assume an uninterrupted run.
5. **Potato through-line.** The potato is this game's **theme**, the way the Mario theme
   binds Mario Party. Lean on potato-based examples wherever it's natural: starch, sulfur,
   potato farms, and — as scale grows — Earth-as-a-potato-farm, the cosmos as potato lineage.
   It is **not required for every game** (not every Mario Party game is about Mario), but it
   is the connective tissue: when a block or mechanic *can* be framed through the potato,
   prefer it. Never force it at the cost of fun or clarity.
6. **Every game shows its instructions before play.** No cold starts. Registry games get this free
   from the shared host (it shows their rules); legacy games must each present a pre-game instructions
   screen. The per-game `MANUAL.md` is the source of that copy. (Gap: several legacy games still drop
   you in cold — e.g. Reality Merge — and need an intro added.)
7. **Scene isolation / fault containment (see §5).**

---

## 5. Architecture commitment — Scene isolation & directory scoping

This is a **commitment the system makes**, in response to a real concern about how the
codebase is written:

- **Every game runs inside an isolated scene.** If a single game throws or hangs, the
  player can **always exit it**, the rest of the session **keeps working**, and the
  overall flow **does not break**.
- **Mechanism:** each game is mounted behind (a) an error boundary that catches build/paint
  exceptions and shows an "exit game" fallback, and (b) a guaranteed exit affordance that
  never depends on the game's own state. The host (`MiniGameHost`) owns the timer, the
  results, and the exit — a game cannot trap the player.
- **Directory scoping for agents.** When we spin off an agent to build or fix a game, that
  agent works **only within that game's own directory** (plus shared read-only kit). It
  does **not** reach across into other games or shared host code without explicit
  escalation. One game = one scoped workspace = blast radius of one game.

> Status: today games are scattered (`lib/games/arcade/`, `lib/views/screens/mini_game_page/games/`,
> two `mini_games_batch*.dart` megafiles, and inline classes in `mini_game_page.dart`).
> The target structure in §7 is what makes per-game scoping real. Migration is incremental.

---

## 6. The four docs every unit carries

We document on two levels. **Per scale (cell)** and **per game.**

### Per scale (lives at the scale level)
- **`EDUCATION.md`** — the blocks that occupy this scale, and which game(s) engage each
  block. This is the association ledger. Source data: `lib/data/scales/<scale>_entities.dart`.

### Per game (lives in the game's directory)
- **`GAME.md`** — the canonical **spec**: concept, the exact rules, win/lose, scoring,
  difficulty curve, solo-vs-disrupt role, six-in-one breakdown if applicable. *This is the
  durable asset — it survives a re-implementation.*
- **`MANUAL.md`** — the **player-facing** "how to play" (one entry in the Manual). Plain
  language, anyone can read it and understand the game. Feeds the deployable Manual app.
- **`AGENT.md`** — the **agent context**: where the files are, the scoped directory, the
  tunable constants, known bugs/TODOs, the scene/exit contract, and the do-not-touch list.

Templates live in `docs/templates/`.

### The deployable Manual (sanctioned sibling project)
Locking and confirming rules has been the hardest part of this work. So a separate
**TypeScript / React / NPM app whose entire job is to be the Manual** is valid and may be
deployed. The per-game `MANUAL.md` files are its **source of truth**; the app renders them,
grouped by scale. This becomes standard practice carried into Hot Potato Games.

---

## 7. Target directory structure (incremental goal)

```
lib/games/
  <scale_key>/                  # e.g. nothings, particles, atoms ...
    EDUCATION.md                # blocks on this scale + game associations
    <game_id>/
      <game_id>.dart            # the game widget (Canvas-only)
      GAME.md                   # canonical spec / rules
      MANUAL.md                 # player-facing how-to (Manual entry)
      AGENT.md                  # scoped agent context
  shared/                       # host, scene wrapper, fx kit, design kit (read-mostly)
docs/
  NORTH_STAR.md                 # this file
  EDUCATION_BLOCKS.md           # cross-scale review worksheet
  templates/                    # the four-doc skeletons
```

We do **not** have to migrate everything at once. New work lands in this shape; existing
games migrate scale-by-scale as we review them.

---

## 8. Current state — two game systems

There are **two parallel systems** today; several scales have a game in each:

1. **Registry / "arcade" games** (`lib/games/arcade/`, listed in
   `lib/games/mini_game_registry.dart`) — party-ready, polished, carry `rules`/`howToWin`
   metadata. 8 games: Big Bang, Corners, Collider, Accelerator, Atom Builder,
   Molecule Mixer, Hungry Cell, Grow The Plant.
2. **Legacy games** (`mini_game_page.dart` `_buildGame` switch → `games/` files +
   `mini_games_batch2/3.dart` + inline classes) — these are what **Explore** actually shows
   per scale today.

**How Explore actually routes (verified):** `MiniGamePage` calls
`MiniGameRegistry.forScale(scale)` and, if a spec exists, plays the **registry/arcade** game via
the host; only if none exists does it fall back to the legacy `_buildGame` switch. So for the 8
registry scales, **Explore shows the ARCADE game** and the legacy `_buildGame` entry for that scale
is **dead code**. Two consequences:
- The "organelle falls through to Big Bang" bug is **masked/latent** — `forScale(organelle)`
  returns Hungry Cell, so Explore shows Hungry Cell. (Still fix the missing switch case.)
- `forScale` returns only the **FIRST** enabled spec for a scale, so a scale's **second game
  (e.g. Accelerator on particles) is unreachable from Explore.** Multiple-games-per-scale needs a
  **per-scale game picker** (registry `gamesForScale()` + an Explore chooser when count > 1).

---

## 9. Inventory & status (22 scales)

Education tie ratings are from the code audit. "Verdict" is a starting recommendation, to be
confirmed during the block review.

| # | Scale | Game(s) in play | Edu tie | Notes / verdict |
|---|---|---|---|---|
| 1 | nothings | Big Bang (legacy + arcade) | cosmetic | **Theme mismatch.** Blocks are math/void/zero/paradox. Per direction, nothings = math/word/sound/waves/light. Big Bang is *material* → belongs in somethings. Needs a math/word game. |
| 2 | somethings | Corners (geometry) + Thought Catcher | geometry solid; TC weak | somethings = start of material. Geometry fits *before* Big Bang; Big Bang could move here. Thought Catcher has no block tie. |
| 3 | particles | Collider + Accelerator | moderate/cosmetic | Two games (good — proves the 1+ model), but **only Collider is on Explore** (`forScale` returns first). Locked: add **discovery-timeline** flare (1897→2012, who/when) on PERFECT. See `lib/games/particles/`. |
| 4 | atoms | Atom Builder (arcade) + Starch Factory | **strong** | Atom Builder teaches atomic number, shells, stability, N-P-S-K. Best edu tie in the app. Pick canonical. |
| 5 | molecular | Molecule Mixer + Molecule Builder | **strong** | Real formulas/bonding. 12 blocks here. |
| 6 | organelle | Hungry Cell (arcade) | moderate | Explore shows Hungry Cell (registry). `_buildGame` has no `organelle` case → **latent/masked bug** (would fall to Big Bang only if Hungry Cell were disabled). 22 blocks (richest scale). |
| 7 | cell | Mitosis Rush | strong-for-mitosis | Blocks are cell *types* (guard/root-hair/xylem...), game is mitosis. Partial mismatch. |
| 8 | tissue | Tissue Layer (Layer Builder) | strong | Vascular/dermal/ground/meristematic — good match. |
| 9 | organ | Grow The Plant (arcade) + OrganGrow | moderate | Elements metaphor; blocks root/stem/leaf/flower/seed/fruit. |
| 10 | organSystem | Organ System (System Link) | strong | Root/shoot/vascular/reproductive systems — good match. |
| 11 | organism | Organism Harvest | cosmetic | Blocks are crops (corn/soy/wheat/rice). Game is harvest-timing. Weak tie. |
| 12 | ecosystem | Potato Rush (wired) / EcosystemBalance (batch2) | PR cosmetic; EB strong | **EcosystemBalance (companion planting) matches blocks far better but may be unwired.** Verify routing. |
| 13 | farmSystem | Farm Panic (wired) / FarmRotation (batch2) | FP thematic; FR strong | **FarmRotation = crop rotation/cover crop/irrigation/fertilizer/compost = exactly the blocks, but may be unwired.** Verify. |
| 14 | supplyChain | SupplyChain (batch2) | thematic | Harvest→storage→processing→distribution→retail. **GlobalFeedGame (batch3) is dead/unwired** — decide keep or delete. |
| 15 | financial | Financial Trading (Market Trader) | moderate | Commodity/cost/risk/policy. Trading game ties to commodity markets. |
| 16 | planets | Planet Catch (Orbit Catch) | **strong** | Real gravity sim; bigger body = stronger pull. Mechanic *is* the concept. |
| 17 | solarSystems | Solar Sort (spiral-draw) | **very weak** | "Orbital Mechanic" is freehand spiral drawing — no orbital physics. Orphaned `LightSpeedGame` (gravity) fits better. Rework candidate. |
| 18 | galactic | Galaxy Collector (Star Collector) | cosmetic | Tap-the-star; blocks Milky Way/dark matter/recycling untouched. |
| 19 | cosmicStructures | Neuron Connect (wired) / Cosmic Web (exists) | NC mismatch; CW strong | **Cosmic Web game (graph connectivity) matches the blocks; Neuron Connect is what's routed.** Likely swap. Name mismatch in code. |
| 20 | multiverseAll | Reality Merge | metaphorical | **Concept good, graphics bad → keep rules, re-implement.** (User's explicit call.) |
| 21 | universeAll | Everything (word/language) | weak-to-blocks but fun | Multilingual vocab game; blocks are totality/math-universe/final-theory. Fun but loose tie. |
| 22 | infinities | Infinity Counter (Count Forever) | weak | Tap-counter with power-ups. **No restart button bug.** Blocks: countable/uncountable/limits/infinitesimals. |

---

## 10. Cleanup backlog (structural)

- **`organelle` routing bug** — add the missing `_buildGame` case (currently shows Big Bang).
- **Legacy vs arcade divergence** — choose one canonical game per scale; retire the other or
  promote it to a second slot.
- **Unwired games to adjudicate:** `EcosystemBalance`, `FarmRotation` (both batch2),
  `CosmicWebGame`, and the fully-dead `GlobalFeedGame` (batch3, never imported).
- **Orphaned inline classes in `mini_game_page.dart`** (dead code): `_TapToCreateGame`,
  `_CatchTheFlashGame`, `_BalanceGame`, `_MarketTraderGame`, `_ChoosePathGame`,
  `_CountForeverGame`, `LightSpeedGame` (the last is worth salvaging for solarSystems).
- **Two `mini_games_batch2/3.dart` megafiles** — split per-game as we migrate to §7.
- Per-game bug list lives in each game's eventual `AGENT.md`; raw audit notes are the source.

---

## 11. Working process (how we move)

1. **Review a scale's blocks** (use `docs/EDUCATION_BLOCKS.md`).
2. **Confirm association**: does a game on this scale meaningfully engage these blocks?
   - Yes → keep; write/confirm `GAME.md` + `MANUAL.md` + `EDUCATION.md`.
   - Weak/none → either rework the game, build a new one, or **cut the scale**.
3. **Spin off a scoped agent** for the chosen task (build/fix/re-implement one game). The
   agent gets: the game's directory, its `GAME.md` spec, the scene/exit contract, and a
   **do-not-leave-this-directory** rule.
4. **Lock the rules in `GAME.md`** before/while implementing. Rules first.
5. Keep this North Star and `EDUCATION_BLOCKS.md` current as verdicts land.

---

## 12. Open decisions (to confirm with Brett)

- Canonical game per scale where legacy & arcade both exist.
- Scale roster: does every current scale earn a keep, or do some get cut?
- Where the deployable Manual app lives (separate repo vs `manual/` here).
- Final home for the target directory structure (§7) and migration order.
