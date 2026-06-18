# AGENT.md — Molecule Mixer

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/arcade/molecule_mixer.dart` (widget code) and
  `lib/games/molecular/molecule_mixer/` (docs). Shared scale data:
  `lib/games/molecular/MOLECULE_LOCATIONS.md` (+ future `molecule_locations.dart`).
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, fx helpers — no edits without escalation.
- **Do not touch** other games, the mini-game registry, or the host.

## Scene / exit contract
- Isolated scene; never trap the player. Exit, timer, and results are host-owned
  (`MiniGameHost`). Error boundary keeps exit alive regardless of game state.
- The game's `session.addScore()` and `session.addTime()` calls are the only hooks into the host.

## Files
- Widget: `lib/games/arcade/molecule_mixer.dart` → `MoleculeMixerGame`
- Spec: `GAME.md` (canonical rules — obey it; if rules change, update GAME.md first)
- Manual: `MANUAL.md`
- Scale education: `../EDUCATION.md`
- WOW flare data: `../MOLECULE_LOCATIONS.md` (+ future `../molecule_locations.dart`)

## Tunable constants (current)
| Constant | Value | Effect |
|---|---|---|
| `_kMoleculeTimeBonus` | 4 s | Seconds added per completed molecule |
| `_kPanelReserve` | 112 px | Vertical space reserved for the target panel |
| `_kAtomR` | 21 px | Visual radius of a floating atom |
| `_kHitR` | 34 px | Effective tap radius (one-thumb generous) |
| `_kFont` | 'Avenir' | All text in the game |
| `_kAccent` | 0xFF00BCD4 (cyan) | Glow color for bonds, panels, particles |
| Speed ramp | `1.0 + (elapsed/dur).clamp(0,1) * 0.7` | Atoms reach 1.7× speed by end |
| Advanced bias threshold | `_elapsed > 18 \|\| _completedCount >= 3` | When to prefer 4–5 atom targets |
| Advanced pool bias | 0.65 | Probability of picking an advanced target once threshold is met |
| Atom pool target | 12 atoms on field | Maintained continuously |
| Supply buffer | 2 spares per required element | Guaranteed on each new target |
| Celebration duration | 1.35 s | Time before next target loads |
| Flying atom duration | 0.38 s | Atom-to-slot flight time |

## Molecule set (8 targets)
`H₂O`, `O₂`, `CO₂`, `CH₄` (advanced), `NH₃` (advanced), `N₂`, `H₂O₂` (advanced), `HCl`.
Elements used: H (0), O (1), C (2), N (3), Cl (4) — indices into `_elements` list.

## Backbone gating
`_backboneSlot()` returns the slot index of the unique highest-degree hub, or `null` if:
- All bonds have degree ≤ 1 (diatomic — O₂, N₂, HCl, H₂O₂ falls here too due to degree tie)
- There is a degree tie among multiple slots

When a backbone slot exists and is unfilled, tapping a peripheral atom triggers:
- `BACKBONE FIRST` popup at the tapped atom position
- `_backbonePulse = 1.0` → amber ring pulses on the backbone slot ghost in the painter
- No score penalty

## Scoring
- Correct atom placed: `session.addScore(5)` + popup `+5`
- Wrong atom tapped: `session.addScore(-10)` + popup `-10` + `atom.shake = 1.0`
- Molecule complete: `session.addScore(30)` + `session.addTime(Duration(seconds: 4))`
  + popups `+30` and `+4s` + burst particles + celebration banner

## To build
**WOW flare (primary TODO):**
1. Create `lib/games/molecular/molecule_locations.dart` — a const list of
   `{formula, name, whatItIs, whereInPotato}` matching the game-molecule section of
   `MOLECULE_LOCATIONS.md`.
2. In `_MoleculeMixerGameState`, add `int _flareIndex = 0` and a `_FlareCard?` state.
3. In `_arrive()`, after `_celebT = 0`, look up `molecule_locations[_target.formula]`
   and schedule the flare card to appear ~0.8 s later (after the celebration banner peaks).
4. Render the flare as a two-line canvas text card at `_buildCenter + Offset(0, unit * 2)`.
   Fade in over 0.6 s, hold 1.2 s, fade out. Does not block input.
5. Persist `_flareIndex` for session resume.

## Known bugs / TODOs
- No confirmed bugs at time of writing. Add here as discovered during implementation.
- **Watch for:** atom pool size can drift if multiple `_ensureSupply()` calls fire close together
  — the field can momentarily exceed 16 atoms. Not a correctness bug but may feel crowded.
- **Watch for:** if `session.isRunning` is false (pre-countdown overlay), `_elapsed` does not
  advance and `_update()` is skipped — but the `_seedField()` call in `build()` depends on
  `_fieldSize` being set. Ensure layout has fired before `_seedField()` is called (it guards on
  `_bounds.isEmpty`, so this should be safe; confirm if you see a blank first frame).

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG. Atoms: radial gradient fill + glow halo +
  element symbol text. Bonds: blur-softened wide glow line + bright 3px core. Particles: plain
  colored circles. All text: Avenir bold.
