# AGENT.md — Protein Factory

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> **Status: UNBUILT — this is a forward build-spec. No Dart file exists yet.**

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/organelle/protein_factory/protein_factory.dart` (to be created)
  - Game docs: `lib/games/organelle/protein_factory/` (GAME.md, MANUAL.md, AGENT.md)
  - Scale flare data: `lib/games/organelle/ORGANELLE_REVEAL.md` (spec, read-only) and
    `lib/games/organelle/organelle_reveal.dart` (Dart data file — read-only once created by
    the Rush build; escalate if changes needed)
  - Scale education: `lib/games/organelle/EDUCATION.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_host.dart`, `lib/games/mini_game_registry.dart` — read as needed,
  **no edits without explicit escalation**.
- **Do not touch** Organelle Rush, other games, other scales, the host/router, or
  `mini_game_page.dart`.

---

## Scene / exit contract

- `ProteinFactoryGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the outer timer, the results screen, and the exit affordance. Do NOT reimplement.
- The game's own "end condition" (queue overflow) triggers a `session.endGame()` call to the
  host — the host then shows results. The game does not show a game-over screen itself.
- `widget.session.isRunning` gates gameplay. All timers (order generation, ribosome progress,
  vesicle drift) must freeze when `isRunning` is false.
- Canvas-drawn only. No PNG/JPEG/SVG rasters. All organelle shapes are procedural.
- Sessions are droppable and resumable — see Session / resume in GAME.md.

---

## Files

| Role | Path |
|---|---|
| Game widget (to create) | `lib/games/organelle/protein_factory/protein_factory.dart` |
| Canonical spec | `lib/games/organelle/protein_factory/GAME.md` (rules — update first, then code) |
| Manual entry | `lib/games/organelle/protein_factory/MANUAL.md` |
| Flare data spec | `lib/games/organelle/ORGANELLE_REVEAL.md` |
| Flare data Dart (created by Rush build) | `lib/games/organelle/organelle_reveal.dart` |
| Scale education | `lib/games/organelle/EDUCATION.md` |
| Registry (read-only) | `lib/games/mini_game_registry.dart` → add `BioScale.organelle` entry (second slot) when ready |

---

## Architecture notes

The game board is a single Canvas scene showing the full secretion pathway (Nucleus → Rough ER
→ Golgi → Vacuole/Export). All five organelles are rendered simultaneously.

Recommended state model:
```
ProteinFactoryState {
  List<ProteinOrder> queue          // pending orders from Nucleus (max 5)
  List<RibosomeSlot> erSlots        // 4 slots on the ER ribbon (occupied or empty)
  List<Vesicle> inFlightVesicles    // ER → Golgi, Golgi → destination
  List<VacuoleStore> vacuoles       // 2 vacuoles, each with capacity bar
  int score
  double elapsedTime
  double nextOrderIn                // countdown to next order spawn
}
```

Tick lifecycle (called every frame when `session.isRunning`):
1. Advance `elapsedTime`; decrement `nextOrderIn`; if ≤ 0, spawn next order.
2. For each occupied `RibosomeSlot`, advance `job.progress`; if complete, spawn vesicle.
3. For each vesicle in-flight, advance position; if past window/destination, resolve.
4. Check queue length → if ≥ 6, call `session.endGame(score)`.
5. Repaint Canvas.

---

## Tunable constants (define these in `protein_factory.dart`)

| Constant | Suggested value | Effect |
|---|---|---|
| `_kMaxQueueSize` | `5` | Queue overflow at 6; end game. |
| `_kOrderSpawnIntervalEarly` | `8.0` s | Order arrival rate (0–30 s) |
| `_kOrderSpawnIntervalMid` | `6.0` s | Order arrival rate (30–90 s) |
| `_kOrderSpawnIntervalLate` | `4.0` s | Order arrival rate (90 s+) |
| `_kComplexityBaseDuration` | `4.0` s | Base assembly time per complexity level (×1, ×2, ×3) |
| `_kVesicleDriftWindow` | `4.0` s | Window for player to tap ER vesicle before it's lost |
| `_kMaxERRibosomes` | `4` | Maximum ribosomes that can attach to the ER |
| `_kVacuoleCapacity` | `5` | Number of proteins a vacuole holds before blocking |
| `_kVacuoleBlockPenalty` | `8.0` pts/s | Score drain per second while vacuole is overfull |
| `_kDeliveryOnTimeScore` | `20` | Points for on-time delivery |
| `_kDeliveryLateScore` | `10` | Points for late delivery |
| `_kMissedVesiclePenalty` | `−10` | Points for dropped vesicle |
| `_kComboThreshold` | `3` | Consecutive completions needed for combo bonus |
| `_kComboBonus` | `15` | Bonus points per combo trigger |
| `_kModifyPassChance` | `0.25` | Probability that a Golgi output requires a MODIFY second pass |
| `_kSmoothErLipidInterval` | `12.0` s | How often the Smooth ER generates a lipid vesicle |

---

## Protein order card pool (the named proteins)

Use real potato proteins for order card names. This is the payload of the potato/ribosome
unsung-heroes lore — the player is building real things.

| Protein | Destination | Notes |
|---|---|---|
| Patatin | Vacuole | Primary storage protein, ~40% of tuber protein |
| Starch Synthase | Vacuole | Adds glucose units to amylose chain |
| Invertase | Vacuole | Converts sucrose to glucose + fructose |
| Solanine Synthase | Export | Defense compound biosynthesis |
| RuBisCO (leaf game only) | Export | Most abundant protein on Earth; Calvin cycle |
| Plasma Membrane H⁺-ATPase | Export | Membrane protein; drives ion gradients |
| Tubulin | Export | Microtubule monomer |

Cycle through this pool in random order. Complexity assignment:
- Complexity 1: Patatin, Invertase (common, fast)
- Complexity 2: Starch Synthase, Tubulin, Solanine Synthase
- Complexity 3: RuBisCO, Plasma Membrane H⁺-ATPase (rare, slow)

---

## Known bugs / TODOs (pre-build checklist)

1. **[HIGH] Game does not exist yet.** `protein_factory.dart` must be created from scratch.
   Use `GAME.md` as the sole authoritative spec.

2. **[HIGH] Registry slot.** The organelle scale's registry entry currently points to Hungry Cell
   (per NORTH_STAR). This game is the second game slot. Before registering, confirm: (a) Hungry
   Cell has moved to `BioScale.cell`; (b) the per-scale game picker is implemented or planned, so
   this game is reachable. Escalate to Brett before wiring.

3. **[MEDIUM] Lore intro card.** GAME.md specifies an intro card surfacing the ribosomes-as-
   unsung-heroes / potato parallel. This must be implemented as a Canvas-drawn card that clears
   before gameplay begins (player taps to dismiss). Do not skip this — it is the emotional hook
   that sets the game apart from a generic throughput manager.

4. **[MEDIUM] Vesicle window fairness.** The 4 s window for tapping ER vesicles must freeze
   correctly on session pause. If the player pauses with 1 s remaining on a vesicle window, resume
   should restore the remaining 1 s — not reset to 4 s (too generous) and not expire instantly
   (too punishing). Freeze the countdown exactly.

5. **[MEDIUM] Golgi visual.** The Golgi must be visually distinct from the ER ribbons. Use the
   stacked-crescent motif (3–4 curved strips, slightly offset). The MODIFY second-pass should be
   animated as the vesicle visibly re-entering the Golgi cisternae from the exit side.

6. **[LOW] Smooth ER parallel lane.** The Smooth ER lane is a passive system (no player
   assignment). If it becomes confusing — players trying to interact with it — add a faint label
   "LIPID LANE — AUTO" to make clear it runs itself. Escalate if UX is unclear.

7. **[LOW] Combo counter display.** Show a small combo counter near the Golgi output zone so
   players can see they are building toward the combo bonus. Fades between completed deliveries.

---

## Canvas-only rule

All rendering is `CustomPainter`. No PNG, JPEG, or raster assets.

Canonical organelle shapes for this game (consistent with Organelle Rush):
- **Nucleus** — large circle (top, dimmer fill), with a smaller inner nucleolus circle; mRNA
  strands emerge as short sinusoidal lines when an order spawns
- **Rough ER** — sinuous ribbon across mid-screen; ribosome dots (small dual-oval shapes) studded
  along its upper edge; occupied slots glow; empty slots are faint outlines
- **Smooth ER** — parallel ribbon below the Rough ER; clean sinusoidal, no dots; lipid vesicles
  emerge as iridescent circles
- **Golgi** — stacked crescent stack (3–4 curved strips, offset left-to-right); incoming vesicles
  flatten to enter; output vesicles emerge from the trans face
- **Vacuoles** — two large single-membrane circles at bottom-left; capacity shown as a fill
  gradient (bottom-to-top fill, color shifts from calm to urgent at 80% capacity)
- **Export exit** — Plasma Membrane boundary at bottom-right; vesicles cross it with a brief
  glow burst
- **Vesicles** — small circles; protein vesicles have a label icon (letter initial of protein);
  lipid vesicles are smooth iridescent circles
- **Order cards** — Canvas-drawn rectangles in the top strip; protein name, destination icon,
  complexity bar drawn with TextPainter and RRect
