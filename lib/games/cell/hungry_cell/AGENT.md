# AGENT.md — Hungry Cell

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/arcade/hungry_cell.dart` (`HungryCellGame` / `_HungryCellGameState` /
    `_HungryCellPainter`)
  - Game docs: `lib/games/cell/hungry_cell/` (GAME.md, MANUAL.md, AGENT.md)
  - Scale education: `lib/games/cell/EDUCATION.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_registry.dart` — read as needed, **no edits without explicit escalation**.
- **Do not touch** other games, other scales, or `mini_game_page.dart`.

---

## ⚠️ REQUIRED FOLLOW-UP — Registry scale change

`HungryCellGame` is currently registered in `lib/games/mini_game_registry.dart` on
**`BioScale.organelle`**, not `BioScale.cell`.

```dart
// lib/games/mini_game_registry.dart (current — DO NOT change here, it's read-only for this agent)
MiniGameSpec(
  id: 'hungry_cell',
  scale: BioScale.organelle,   // ← THIS IS WRONG for the Cell scale
  ...
)
```

**A one-line change is required:** `scale: BioScale.organelle` → `scale: BioScale.cell`.

**This agent must NOT make that change.** The registry is outside this agent's scope.
Flag it to Brett for confirmation before any other agent touches the registry, because:
- Changing `BioScale.organelle` to `BioScale.cell` will **remove Hungry Cell from the Organelle
  scale**, where it currently acts as the only game in Explore.
- The Organelle scale (22 blocks, richest scale in the app) would then have no game and become
  a cut candidate — or need a new organelle-appropriate game first.
- This is a scale-roster decision, not a one-line fix.

**Until the registry change is made, Explore shows Hungry Cell on the Organelle scale, not the
Cell scale.** The game itself is unchanged; only its registry entry determines which scale it
appears on in Explore.

---

## Scene / exit contract

- `HungryCellGame` is a **registry/arcade game** that uses `MiniGameSession`.
- `widget.session.isRunning` gates the update loop (`_update` is only called when true).
- `widget.session.addScore(n)` is called for all score changes. The host owns the timer,
  results, and exit affordance.
- The game does **not** implement a results screen or a restart — these are the host's
  responsibility.
- If the game throws, the host's error boundary shows an exit fallback. Never swallow
  exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/arcade/hungry_cell.dart` → `HungryCellGame` |
| Canonical spec | `lib/games/cell/hungry_cell/GAME.md` (rules live here — update first, then code) |
| Manual entry | `lib/games/cell/hungry_cell/MANUAL.md` |
| Scale education | `lib/games/cell/EDUCATION.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → currently `BioScale.organelle` (see flag above) |

---

## Tunable constants (current values — all in `hungry_cell.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kWorldW` / `_kWorldH` | 2400 | World size. Reduce for tighter gameplay; increase for more roaming. |
| `_kCamEase` | 8.0 | Camera lerp rate. Lower = floatier camera; higher = tighter follow. |
| `_kBaseRadius` | 26.0 | Player starting radius (px). |
| `_kMaxGrowth` | 40.0 | Max additional radius from score. |
| `_kPlayerMaxSpeed` | 340.0 | Player speed at minimum size. |
| `_kPlayerSizePenalty` | 0.28 | Speed reduction at max size (28% slower). |
| `_kPlayerInvuln` | 1.0 s | Invulnerability window after a hit. |
| `_kNutrientCount` | 90 | Nutrient pellets in the world. |
| `_kNutrientRadius` | 4.5 | Pellet pick-up radius. |
| `_kOrganelleMax` | 4 | Max simultaneous organelle pickups. |
| `_kPredatorCountEarly` | 2 | Predators at t=0. |
| `_kPredatorCountPeak` | 9 | Predators at session end. |
| `_kPredatorSpeedEarly` | 52.0 px/s | Base wander speed at t=0. |
| `_kPredatorSpeedMult` | 2.6 | Speed multiplier at session end. |
| `_kPredatorHomingStart` | 0.45 | Progress fraction where homing begins. |
| `_kPredatorHomingPeak` | 0.88 | Max homing weight at session end. |
| `_kPredatorRadiusMin` | 16.0 | Smallest predator radius. |
| `_kPredatorRadiusMax` | 36.0 | Largest predator radius. |
| `_kDiffExp` | 2.0 | Difficulty exponent (2 = quadratic ramp). Raise for steeper curve. |

---

## Known bugs / TODOs (in priority order)

1. **[BLOCKING — registry] Scale is `BioScale.organelle`, not `BioScale.cell`.** See required
   follow-up section above. Do not move the game to the Cell scale until Brett confirms that the
   Organelle scale will get a replacement game.

2. **[MEDIUM] Registry `rules` entry says "Spiky viruses drain you: −15 mass."** The code
   implements predator cells (cells with a wobbly membrane and a nucleus), not viruses. The
   penalty is −25 mass, not −15. The `rules` string in the `MiniGameSpec` is stale — it should
   read: "Larger predator cells drain you: −25 mass. Eat smaller ones: +30 mass." Update in
   the registry when the scale migration happens.

3. **[MEDIUM] `howToWin` says "Biggest mass gained."** Accurate but terse. Consider: "Most mass
   accumulated in 45 seconds wins." (clearer that it's time-limited).

4. **[MEDIUM] Score can go negative.** If a player is hit repeatedly, `session.addScore(-25)`
   can drive score below 0. Check whether the host's `addScore` clamps to 0. If not, add a
   guard in the game: `widget.session.addScore(max(-25, -widget.session.score))`.

5. **[LOW] Organelle respawn does not check for duplicates.** It's possible to have two
   Mitochondria pickups simultaneously if the random kind selection repeats. Cosmetic issue.
   Fix: track `_organelles.map((o) => o.kind)` and exclude already-present kinds from the
   spawn pool if count > 1.

6. **[LOW] World boundary respawn for pellets uses `awayFrom: _playerPos, minDist: 80`.**
   This is generous enough that pellets rarely respawn on top of the player, but at max
   world coverage they may cluster far from the player. No fix needed unless playtesting
   shows dead zones.

7. **[INFO] `_Speck` drift wraps world bounds.** Background specks wrap at `_kWorldW` /
   `_kWorldH`. Visually correct — no fix needed.

8. **[INFO] `shouldRepaint` always returns false.** The `_HungryCellPainter` uses a
   `_RepaintNotifier` (ChangeNotifier) to trigger repaints. The `shouldRepaint` override
   returns false because repaint is driven by the notifier, not by the painter rebuild cycle.
   This is the correct pattern for this game — do not change it.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG, JPEG, or raster assets.** The game draws:
- Player cell as a sine-deformed wobbly membrane path (64 segments) with radial gradient fill,
  leaning nucleus, and nucleolus dot
- Predator cells as a similar wobbly membrane (40 segments) with distinct color per predator
- Nutrients as glowing pulsing dots with highlight
- Organelle pickups: Mitochondria (rounded rect + cristae bezier), Golgi (stacked arc strokes),
  Ribosome (cluster of labeled circles)
- Background specks as tiny drifting circles
- Ripple rings expanding from pickup/hit events
- Popups as `TextPainter` text in screen-space (world-to-screen conversion applied)
