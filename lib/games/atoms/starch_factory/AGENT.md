# AGENT.md — Starch Factory

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/views/screens/mini_game_page/games/starch_factory_game.dart`
    (`StarchFactoryGame` / `_StarchFactoryGameState`)
  - Game docs: `lib/games/atoms/starch_factory/` (GAME.md, MANUAL.md, AGENT.md)
  - Scale education: `lib/games/atoms/EDUCATION.md`
- **Read-only:** `lib/theme/potatuhs.dart` (fonts, accent colors) — do NOT modify without
  explicit escalation.
- **Do not touch** `atom_builder.dart`, other games, the host/router, or `mini_game_registry.dart`
  without explicit escalation.

---

## Scene / exit contract

- `StarchFactoryGame` currently owns its own game-over and restart loop — it does NOT defer to a
  `MiniGameSession` host. This is a divergence from `AtomBuilderGame`.
- If integrated into the session host later, the internal restart (`_restart`) and the
  `_gameOver` draw path would need to be removed or handed off. Flag this before any
  host-integration work.
- The game must not trap the player. Any host wrapper that mounts it must provide an exit
  affordance.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/views/screens/mini_game_page/games/starch_factory_game.dart` → `StarchFactoryGame` |
| Canonical spec | `lib/games/atoms/starch_factory/GAME.md` (rules live here — update first, then code) |
| Manual entry | `lib/games/atoms/starch_factory/MANUAL.md` |
| Scale education | `lib/games/atoms/EDUCATION.md` |

---

## Tunable constants (current values — in `starch_factory_game.dart`)

| Constant / field | Initial value | What to tune it for |
|---|---|---|
| `_scrollSpeed` | 0.14 norm/s | Conveyor pace. Raise to increase base difficulty; note it also ramps with elapsed time. |
| `_drainRate` | 0.018 /s | Starch drain per second. Raise to shorten games; lower for more forgiving survival. |
| `_swapCooldown` | 10.0 s | Starting swap interval. Minimum floor is 4.5 s (clamped). |
| Score threshold (lane 4) | 1000 | Score at which purple lane unlocks. |
| Score threshold (lane 5) | 10000 | Score at which pink lane unlocks. |
| Starch refill per correct | 0.055 | How much a correct routing restores. Raise if the bar feels unrecoverable. |
| Starch penalty per wrong | 0.07 | How much a wrong routing removes. Lower if game-overs feel sudden. |
| Combo multiplier formula | `10 × (1 + n × 0.15)` | Points per correct routing at combo n ≥ 3. |

Spawn: a new molecule spawns whenever fewer than 3 unresolved molecules are in flight and the
last unresolved molecule has passed the 22 % mark.

---

## Known bugs / TODOs (in priority order)

1. **[HIGH — registry] Not registered in `mini_game_registry.dart`.** `StarchFactoryGame` is
   currently reachable only via `mini_game_page.dart` (legacy path), not via the shared game
   registry on `BioScale.atoms`. Before scheduling it as a scale game, register it or confirm
   the legacy path is the intended delivery mechanism.

2. **[HIGH — session contract] No `MiniGameSession` integration.** `StarchFactoryGame` manages
   its own score, timer, and restart. `AtomBuilderGame` delegates all of these to the session
   host. The two games on the same scale should have consistent contracts. Decide: adapt
   StarchFactory to use `MiniGameSession`, or accept it as a standalone legacy widget.

3. **[MEDIUM — font] Uses `'Avenir'` system font.** `AtomBuilderGame` uses `Potatuhs.bodyFont`
   (Outfit) from the shared design kit. `StarchFactoryGame` hardcodes `'Avenir'`. Align to
   `Potatuhs.bodyFont` for visual consistency on the same scale.

4. **[MEDIUM — edu tie] Molecule labels (G, A, B, P, D) are opaque.** The letters don't visibly
   map to chemistry. An upgrade would label them `C₆` or use colour names + a brief tooltip, so
   the "glucose = carbon chain" message is explicit rather than implied.

5. **[LOW — spawn edge case] Orphaned spawn check.** In `_spawnMol`, the `orElse` fallback
   creates a throwaway `_Mol(x: 1.0)` just to satisfy the `lastWhere` contract. This is harmless
   but confusing. Refactor to a nullable check or a separate `_hasUnresolved()` guard.

6. **[INFO] Self-managed restart.** `_restart()` directly resets all state and immediately spawns
   a molecule. If wrapped in a host later, this path bypasses the host's session lifecycle. See
   bug #2.

---

## Educational position

**Edu tie is ⚠️ (thematic, not structural).** This game does not teach atomic number, electron
shells, or nuclear stability. It reinforces:
- Carbon as the backbone of starch
- The amyloplast as a real sub-cellular organelle
- Starch as a polymer that must be assembled correctly

Do NOT rework the core mechanic to add atom-building mechanics — that is `atom_builder`'s job.
If stronger atomic-structure coverage is needed on this scale, improve `atom_builder` or add a
third game, rather than hybridizing this one.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG, JPEG, or raster assets. Rendering uses:
- `ui.Gradient.radial` for backgrounds and glows
- `Path`-based hexagons for molecules and endpoints
- `TextPainter` for labels and HUD text
- `RRect`-based bars for starch and swap-countdown
