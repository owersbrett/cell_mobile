# AGENT.md — Lobbying

> Context for an AI agent working on THIS game. Read this and GAME.md first, then EDUCATION.md.
> Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/financial/lobbying/`
  - Game code: `lobbying_game.dart` (`LobbyingGame` / `_LobbyingGameState` / `_BgPainter` / `_FxPainter`
    + the `_Official`, `_Bill`, `_Pop` models)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`, `lib/games/mini_game.dart`,
  `lib/models/bio_entity.dart` — read as needed, **no edits**.
- **Do NOT touch:** `lib/games/mini_game_registry.dart`, `lib/games/game_catalog.dart`,
  `lib/games/mini_game_host.dart`, any other game folder, or anything outside this folder. The
  orchestrator wires the registry/catalog. Flag registry needs here; do not make them.

---

## Scene / exit contract

- `LobbyingGame` is a registry mini-game driven by `MiniGameSession`.
- `widget.session.isRunning` gates the sim: the ticker advances the vote timer, rival-lobby pushback,
  passive income and resolution **only while true**. Before that the desk renders as a calm, inert
  preview (the host overlays the intro/countdown).
- Score is reported via `widget.session.addScore(payout)` on each passed bill; the streak high-water
  mark via `widget.session.noteStreak(streak)`.
- The game does **not** draw its own countdown, score chrome, intro, results or restart — those are the
  host's. It never calls `endEarly` (no fail-out; a 60s session always completes).
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.

---

## Tone is non-negotiable: light SATIRE, not a lecture

Brett's framing: this is **potato-politics satire** about public choice — playful, on-brand, never
preachy. Bills are absurd ("Gravy Infrastructure Bill"); officials are potato varieties. The
educational payload (concentrated benefits / diffuse costs, diminishing returns, marginal allocation)
is taught **through the mechanic and the visible numbers**, not through moralizing copy. Keep it funny.
Do not turn the subtitles into a civics sermon — the "who-wins · who-pays" one-liner is the whole nod.

---

## The teaching surface must stay legible

The point of the game is that the **cost → probability relationship is visible**. Preserve all three:
1. The per-card **marginal preview** (`next $D: +Δ%`) — shows diminishing returns shrinking the Δ.
2. The banner **PROJECTED %** (exact poisson-binomial in `_passProbability`) — the aggregate odds you
   move by spending. Keep it exact; the panel is small (≤7) so the O(n²) DP is free.
3. The **SCANDAL-RISK** heat bar — the cost of overreach.
If you change the influence model, keep these readouts honest and in sync.

---

## Tunable constants (current values — all top-of-file in `lobbying_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kStartBudget` | 250 | Opening war chest. Raise for a gentler ramp. |
| `_kTrickle` | 4.5 $/s | Passive small-donor income (anti-soft-lock). |
| `_kUnitCost` | 18 | $ per influence unit at price 1.0. Higher = money buys less swing. |
| `_kMaxSwing` | 0.60 | Ceiling a fully-funded official can be swung above their lean. |
| `_kSwingScale` | 1.5 | Saturation constant of the swing curve. |
| `_kSaturationUnits` | 3.0 | Units past which marginal gain is tiny → starts heating. |
| `_kHeatGain` / `_kHeatCool` | 0.32 / 0.06 | Scandal-risk accrual on overreach / passive cooldown. |
| `_kScandalPenalty` | 120 | War-chest hit when an official scandals. |
| `_kPayoutMin/Max` | 160 / 440 | Bill payout, lerped by elapsed fraction. |
| `_kVoteTimeMax/Min` | 11 / 6 s | Vote-timer length, early → late. |
| `_kOppRateMin/Max` | 0.014 / 0.052 /s | Rival-lobby pushback rate, early → late. |
| `_kOppCap` | 0.40 | Most the rival lobby can drag one official down. |
| `_kDonations` | [10,25,50,100] | Donation-size presets. |

Star tuning lives in the **registry spec** (`humanMax: 1800`, `starThresholds: [600, 1100, 1800]`),
which is out of this agent's scope — flag changes for the orchestrator.

---

## Content guidelines

- **Bills** (`_kBills`): `[title, "who-wins · who-pays"]`. Keep titles absurd-but-plausible potato
  legislation; keep the subtitle a one-line concentrated-benefit / diffuse-cost gag.
- **Officials**: titles `_kTitles` + potato-variety surnames `_kSurnames`. Names must stay unique
  within a panel (the generator already enforces this). Leaning labels are derived from `baseLean`
  (SPUD-FRIENDLY / SWING VOTE / BIG-MASH ALLY) — keep the buckets in sync if you retune `baseLean`.

---

## Performance rules (codebase black-screen lesson)

- One `AnimationController` ticker → per-frame `setState` over a **small** tree (banner + ≤7 cards +
  control bar). Do NOT grow the per-frame subtree or add nested 60fps `CustomPaint`s beyond the two
  existing `RepaintBoundary` painters (`_BgPainter`, `_FxPainter`).
- Background motes are kept low (`motes: 22`). Bars are plain `Container`s (cheap). Keep it that way.

---

## Canvas-only rule

Background and FX are `CustomPainter`s; the single raster is the 🥔 emoji glyph. **No PNG/JPEG
assets.** Keep `_passProbability` allocation-light (it runs every frame for the banner).
