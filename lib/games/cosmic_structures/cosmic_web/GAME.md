# GAME.md — Cosmic Web

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** cosmicStructures
- **Game id:** cosmic_web
- **One-line concept:** Drag galaxy supercluster → supercluster along the faintly
  glowing dark-matter **filaments** to light up the cosmic web; never drag across
  an empty **void** (where no filament exists).
- **Role:** solo high-score (also party-mode round)
- **Six-in-one?** no
- **Duration:** 60 s (host-owned clock)
- **Lineage:** the proper, on-theme successor to the deleted **Neuron Connect**
  (same connect-the-nodes feel, correctly themed to large-scale structure).

---

## Lore

The universe's largest structures are not scattered at random. Galaxy
**superclusters** sit at the knots of a vast scaffolding of **dark matter**,
strung together along thread-like **filaments**, woven around enormous,
near-empty **voids**. Zoomed out far enough, the cosmos looks like a foam — a
"cosmic web." You are tracing that web: lighting the filaments that genuinely
connect clusters, and learning to read where the voids are.

---

## Rules (canonical)

1. **A web is a set of supercluster nodes.** Some pairs are joined by a real
   **filament** (drawn as a faint dark-matter thread); the rest are separated by
   **voids** (no thread).
2. **Drag cluster → cluster.** If a real filament joins them, the thread
   **ignites** (warm gold), banks points, and grows your chain combo.
3. **Drag across a void** (a pair with no filament) and the link **fizzles** — no
   score, and your chain combo resets. A "VOID — no filament there" cue shows.
4. **The rubber-band previews validity:** it glows gold while it would land on a
   real filament, white otherwise — so you can read a void before committing.
5. **Light every filament to COMPLETE the web** and bank a **completion bonus**
   (base + a speed bonus for a fast trace).
6. **Each completed web is replaced by a denser one** — more clusters, more
   filaments, **fainter** filament hints, and more voids.
7. The filament scaffold is a **Euclidean Minimum Spanning Tree** (the real
   cosmic web is filament/tree-like) plus a few short loop edges that bound the
   voids — so every web is always fully traceable.

---

## Controls

**Drag** from one cluster to another. That is the only input. All rendering is a
single `CustomPainter` on one ticker — no raster assets.

Visual language:
- **Superclusters** — layered orbs (`GameFx.orb`). Violet with a pulsing halo
  while they still have dark threads; warm gold once all their threads are lit.
- **Dark filament** — faint violet thread waiting to be traced.
- **Lit filament** — bright warm-gold glow beam (`GameFx.glowLine`).
- **Void** — a dark radial well with a faint rim; the web bends around it.
- **Rubber-band** — gold = lands on a real filament, white = would cross a void.

---

## Scoring

| Event | Score |
|---|---|
| Light a filament | `+ (10 + 0.6·web#)` base, `+ min(combo·2, 20)` chain bonus |
| Cross a void | 0 — chain combo resets |
| Complete a web | `+ (25 + speedBonus)`, speedBonus up to **+45** for a fast trace |
| Chain | consecutive correct links → `session.noteStreak` high-water |

Score = total banked in 60 s. No hard fail/game-over; a void miss only costs the
combo and a moment of time.

- `humanMax`: **2000** (a skilled player who reads voids fast and chains webs).
- `starThresholds`: **[700, 1400, 2000]** — 1★ trace a few webs, 2★ chain
  cleanly, 3★ near-optimal void-reading speed.

---

## Win / end condition

Highest score when the host buzzer ends the 60 s. No sudden death.

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Cluster count | `min(14, 6 + web#)` — denser webs |
| Loop filaments | `min(n-2, web#/2)` extra short edges (more voids to dodge) |
| Filament hint alpha | `0.50 → 0.13` as web# rises (fainter threads) |
| Void blobs | `2 + web#/3` decorative voids |
| Completion par | `filaments · 1.15 s` (faster traces score the speed bonus) |

---

## Session / resume (the S)

Host-driven. The widget watches `session.isRunning`; on the rising edge it calls
`_resetRun()` (clock 0, web 0, fresh first web). When the host ends the run and a
new session starts (`phase` returns to `intro`), the rising-edge guard clears so
the next run replays cleanly. Nothing in the widget owns the clock, countdown, or
results — the host does. A session can close and a fresh one re-enter with no
residual state.
