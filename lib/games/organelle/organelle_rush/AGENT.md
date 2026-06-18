# AGENT.md — Organelle Rush

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> **Status: UNBUILT — this is a forward build-spec. No Dart file exists yet.**

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/organelle/organelle_rush/organelle_rush.dart` (to be created)
  - Game docs: `lib/games/organelle/organelle_rush/` (GAME.md, MANUAL.md, AGENT.md)
  - Scale flare data: `lib/games/organelle/ORGANELLE_REVEAL.md` (spec) and
    `lib/games/organelle/organelle_reveal.dart` (Dart data file, to be created — shared read-only
    once written; escalate if changes needed)
  - Scale education: `lib/games/organelle/EDUCATION.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_host.dart`, `lib/games/mini_game_registry.dart` — read as needed,
  **no edits without explicit escalation**.
- **Do not touch** other games, other scales, the host/router, or `mini_game_page.dart`.

---

## Scene / exit contract

- `OrganelleRushGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the outer timer, the final results screen, and the exit affordance. Do NOT
  reimplement these.
- Each micro-game segment has its own internal ~20 s sub-timer drawn on the Canvas — this is
  the game's responsibility, not the host's. The host timer is the session ceiling.
- If the game throws, the host's error boundary shows a fallback exit. Never swallow exceptions.
- `widget.session.isRunning` gates gameplay. Respect the pause contract — do not advance game
  state (including segment timers) when `isRunning` is false.
- Canvas-drawn only. No PNG/JPEG/SVG rasters. All organelle shapes are procedural.
- Sessions are droppable and resumable — see Session / resume in GAME.md.

---

## Files

| Role | Path |
|---|---|
| Game widget (to create) | `lib/games/organelle/organelle_rush/organelle_rush.dart` |
| Canonical spec | `lib/games/organelle/organelle_rush/GAME.md` (rules — update first, then code) |
| Manual entry | `lib/games/organelle/organelle_rush/MANUAL.md` |
| Flare data spec | `lib/games/organelle/ORGANELLE_REVEAL.md` |
| Flare data Dart (to create) | `lib/games/organelle/organelle_reveal.dart` |
| Scale education | `lib/games/organelle/EDUCATION.md` |
| Registry (read-only) | `lib/games/mini_game_registry.dart` → add `BioScale.organelle` entry when ready |

---

## Architecture notes

The eight micro-games are implemented as nested `StatefulWidget`s or painters
mounted inside the parent `OrganelleRushGame` scene. A single `_currentSegment` index (0–7)
drives which sub-game is active. On segment complete, store the segment score and increment.

Recommended structure:
```
OrganelleRushGame (StatefulWidget, mounts in MiniGameHost)
  ├─ _SegmentZoom          (Segment 1)
  ├─ _SegmentErLanes       (Segment 2)
  ├─ _SegmentGolgiSort     (Segment 3)
  ├─ _SegmentDnaUnzip      (Segment 4)
  ├─ _SegmentRibosomeLine  (Segment 5)
  ├─ _SegmentMitoburn      (Segment 6)
  ├─ _SegmentSpindleFire   (Segment 7)
  └─ _SegmentPeroxiSweep   (Segment 8)
```

Each segment exposes `onComplete(int segmentScore)` to the parent. The parent advances the index
and accumulates the total.

Between segments: a 1.5 s ORGANELLE_REVEAL flare card fires. It is painted over the Canvas by
the parent, not the segment. Segments are unaware of the flare layer.

---

## Tunable constants (define these in `organelle_rush.dart`)

| Constant | Suggested value | Effect |
|---|---|---|
| `_kSegmentDuration` | `20.0` (seconds) | Hard cap per micro-game segment |
| `_kFlareHoldDuration` | `1.5` (seconds) | How long the reveal card holds between segments |
| `_kZoomTargetFadeTime` | `2.5` (seconds) | Time each Zoom target ring stays visible |
| `_kZoomPerfectBonus` | `30` | Bonus for 7/7 Zoom hits |
| `_kErLaneCorrectScore` | `8` | Points per correct lane tap (Seg 2) |
| `_kErLanePenalty` | `−5` | Penalty per wrong lane tap (Seg 2) |
| `_kGolgiCorrectScore` | `10` | Points per correct vesicle sort (Seg 3) |
| `_kGolgiPenalty` | `−5` | Penalty per wrong sort (Seg 3) |
| `_kDnaCorrectScore` | `7` | Points per correct base-pair tap (Seg 4) |
| `_kDnaPenalty` | `−3` | Penalty per wrong base tap (Seg 4) |
| `_kRiboCorrectScore` | `10` | Points per correct amino acid tap (Seg 5) |
| `_kRiboPenalty` | `−4` | Penalty per wrong amino acid (Seg 5) |
| `_kMitoCorrectScore` | `10` | Points per combustion event (Seg 6) |
| `_kSpindleAttachScore` | `15` | Points per chromosome attached (Seg 7) |
| `_kSpindleMissPenalty` | `−10` | Penalty per unattached chromosome (Seg 7) |
| `_kPeroxiHitScore` | `8` | Points per free radical neutralized (Seg 8) |
| `_kPeroxiComboMultiplier` | `2.0` | Score multiplier for 3+ chain in Seg 8 |
| `_kAllClearBonus` | `100` | Bonus for completing all 8 segments in one session |

---

## Known bugs / TODOs (pre-build checklist)

1. **[HIGH] Game does not exist yet.** `organelle_rush.dart` must be created from scratch.
   Use `GAME.md` as the sole authoritative spec. Do not build features not in the spec.

2. **[HIGH] Amyloplast not in `organelle_entities.dart`.** The flare data file includes entry #21
   (Amyloplast) but no BioEntity exists for it. Build the flare data file with the entry included;
   it will not be reached during Rush (Plant Envelope segments are in game-4), but the Dart const
   list should be complete for when game-4 is built. Track as a follow-up for the data layer.

3. **[HIGH] Registry entry.** `BioScale.organelle` currently points to Hungry Cell. Before
   registering this game, confirm Hungry Cell has been re-keyed to `BioScale.cell`. Raise this
   with Brett before wiring the registry.

4. **[MEDIUM] Segment shuffle order.** GAME.md allows Segments 2–8 to shuffle on replay.
   Implement a deterministic shuffle seeded per session (so drop-and-resume sees the same order).
   Segment 1 (Zoom) is always first — do not shuffle it.

5. **[MEDIUM] Codon table (Segment 5).** A simplified 5-entry codon table must be on screen.
   Decide which 5 codons to feature: recommend UUU (Phe), AUG (Met/start), UAA (stop), GGU (Gly),
   CCU (Pro) — enough variety to be educational, simple enough for 20 s of play.

6. **[LOW] Per-scale game picker.** Multiple games on the organelle scale will be unreachable
   until a game picker is implemented (see NORTH_STAR §8). This is a host-level concern — do not
   solve it within this game's scope. Flag for Brett.

---

## Canvas-only rule

All rendering is `CustomPainter`. No PNG, JPEG, SVG, or raster assets. Organelle shapes:
- **Nucleus** — large circle with inner nucleolus circle
- **Ribosomes** — small dense dots (2 stacked ovals, 70% fill)
- **ER** — sinuous ribbon (Smooth = clean curves; Rough = curve with dot stippling)
- **Golgi** — stacked crescent stack (3–4 curved strips, offset)
- **Mitochondria** — rounded oval with internal cristae folds (drawn as inward arcs)
- **Microtubules** — parallel lines with faint cross-banding
- **Centrioles** — small cylinder pairs (two rectangles, rotated 90° to each other)
- **Peroxisomes** — round, single-membrane sphere with a faint core dot
- **Vacuoles** — large single-membrane sphere, mostly empty interior
- **DNA** — two antiparallel sinusoidal lines with rungs between them
- **Free radicals** — jagged irregular polygon with a charge-arc stroke
- **Vesicles** — small circles; protein = slightly spiky outline; lipid = smooth iridescent fill
