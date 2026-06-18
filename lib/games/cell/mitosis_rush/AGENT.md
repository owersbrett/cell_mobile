# AGENT.md — Mitosis Rush

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/views/screens/mini_game_page/games/mitosis_rush_game.dart`
    (`MitosisRushGame` / `_MitosisRushGameState` / `_MRPainter`)
  - Game docs: `lib/games/cell/mitosis_rush/` (GAME.md, MANUAL.md, AGENT.md)
  - Scale education: `lib/games/cell/EDUCATION.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart` (fonts, accent colors), `lib/games/mini_game.dart`,
  `lib/games/mini_game_registry.dart` — read as needed, **no edits without explicit escalation**.
- **Do not touch** other games, other scales, the host/router, or `mini_game_page.dart`.

---

## Scene / exit contract

- `MitosisRushGame` is **self-contained** — `const MitosisRushGame()`, no args, no callbacks.
  It owns its own timer loop, score, results screen, and restart.
- It does **not** use `MiniGameSession` or the `MiniGameHost`. This is a divergence from registry
  games (e.g., `HungryCellGame`).
- **If integration with the session host is needed later:** the internal results screen
  (`_Phase.results`) and the internal restart (`_onTapDown` branch at `_Phase.results`) must be
  removed and delegated to the host. The `_phaseTimer` and per-phase scoring logic would remain.
  Flag this before any host-integration work and do not proceed without explicit instruction.
- The game must never trap the player. Any wrapping host must provide an exit affordance.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/views/screens/mini_game_page/games/mitosis_rush_game.dart` → `MitosisRushGame` |
| Canonical spec | `lib/games/cell/mitosis_rush/GAME.md` (rules live here — update first, then code) |
| Manual entry | `lib/games/cell/mitosis_rush/MANUAL.md` |
| Scale education | `lib/games/cell/EDUCATION.md` |
| Registry | Not registered in `lib/games/mini_game_registry.dart` (legacy path only) |

---

## Tunable constants (current values — all in `mitosis_rush_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kDnaTarget` | 20 | Taps needed to complete Interphase. Lower = easier / faster phase. |
| `_kDnaPhaseTime` | 10.0 s | Interphase timer. |
| `_kChromatinCount` | 12 | Total chromatin blobs in Prophase (must be even; pairs). |
| `_kPropPhaseTime` | 10.0 s | Prophase timer. |
| `_kPlateSnapDist` | 32.0 px | Vertical snap radius to metaphase plate. Raise to make alignment more forgiving. |
| `_kChromosomeCount` | 4 | Chromosomes to align in Metaphase. |
| `_kMetaPhaseTime` | 12.0 s | Metaphase timer. |
| `_kSwipeThreshold` | 55.0 px | Minimum vertical delta to register an anaphase swipe. Lower = easier. |
| `_kSwipeHitRadius` | 52.0 px | Hit radius on each chromatid pair in Anaphase. |
| `_kChromatidPairs` | 4 | Pairs to swipe in Anaphase. |
| `_kAnaPhaseTime` | 12.0 s | Anaphase timer. |
| `_kNuclei` | 2 | Nuclei to seal in Telophase (do not change — mitosis always produces 2). |
| `_kTapsPerNucleus` | 5 | Taps per nucleus to seal it. |
| `_kTeloPhaseTime` | 8.0 s | Telophase timer. |
| `_kFurrowTarget` | 0.80 | Fraction of cell width the furrow must cross (80%). |
| `_kCytoPhaseTime` | 10.0 s | Cytokinesis timer. |
| `_kPerfectBonus` | 100 | Max speed bonus per phase. |
| `_kPhaseBaseScore` | 50 | Base score for completing (or timing out of) any phase. |
| `_kPhaseDoneDelay` | 1.1 s | Hold time on "PHASE COMPLETE!" before advancing. |

---

## Known bugs / TODOs (in priority order)

1. **[FIXED — documented] Anaphase swipe direction.** The original code checked `pos.dx` (horizontal
   delta) to determine pole direction. This was wrong — the poles are drawn at top and bottom of the
   cell, so the gesture should be vertical. The fix (`pos.dy - _swipeStart.dy`, negative = up = top
   pole) is already in the current code. This item exists for documentation; **do not revert it.**

2. **[HIGH — registry] Not registered in `mini_game_registry.dart`.** `MitosisRushGame` is currently
   routed only via `mini_game_page.dart` legacy path (the `cell` case in `_buildGame`). To make it
   available via the party/session system, register it on `BioScale.cell` and provide a
   `MiniGameSession` integration (see item 3).

3. **[HIGH — session contract] No `MiniGameSession` integration.** The game manages its own score and
   timer. Before registering it in the session host, decide: keep the self-contained loop (remove
   the built-in results screen, expose score via session) or keep it as a standalone legacy widget.
   Do not attempt this migration without explicit instruction — it requires touching the host.

4. **[MEDIUM — potato WOW layer] No per-phase potato context.** The intro screen names the six phases
   but does not connect them to the potato. A brief, non-scoring flare per phase — e.g., "PROPHASE —
   happening right now in every growing tip of your potato plant" — would close the loop from
   mechanic to real-world context. Analogous to the cosmic provenance card in Atom Builder.
   Implementation: a secondary text line in `_drawBanner` that shows a potato-context string keyed
   to the current phase. Non-blocking, fades with the banner.

5. **[MEDIUM — font] Uses `'Avenir'` system font.** Registry games use `Potatuhs.bodyFont` (Outfit).
   Align font to the shared design kit if/when this game is promoted to the registry.

6. **[LOW — Anaphase visual] Pole direction cue is passive.** The `↑` and `↓` arrows on each
   chromatid pair tell the player what to do, but don't indicate *which* pole is top vs. bottom.
   Adding a faint "TOP POLE / BOTTOM POLE" label near the pole glows (already present as `▲ POLE`
   and `POLE ▼` text) is sufficient — but may already be visible enough.

7. **[LOW — Metaphase] Drag offset math.** `_dragOffset` is set once on pan-start as
   `Offset(c.x - pos.dx, c.y - pos.dy)`. If a player picks up a chromosome and it moves under them,
   the offset may make the chromosome feel sticky. Benign but noticeable. No fix needed unless
   feedback confirms it.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG, JPEG, or raster assets.** The game draws:
- Wobbly cell membranes via a 90-segment sine-deformed path
- Chromatin blobs as fuzzy circles with interior strand dots
- Chromosomes as paired oval X-shapes with centromere dot
- Spindle fibers as faint lines between poles and chromosomes
- Nuclei as `_drawDashedCircle` with fill-fraction parameter
- The cleavage furrow as a shrinking vertical line with glow
- HUD timer bar, phase name, score, and progress meter via `TextPainter` and `RRect`
