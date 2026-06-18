# AGENT.md — Molecule Builder

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/views/screens/mini_game_page/games/molecule_builder_game.dart`
  (`MoleculeBuilderGame`) and `lib/games/molecular/molecule_builder/` (docs).
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, fx helpers — no edits without escalation.
- **Do not touch** other games, Molecule Mixer, the registry, or the host.

## Scene / exit contract
- This is a **legacy game** (pre-registry). It owns its own clock, lives, and game-over state.
- It does NOT currently use `MiniGameSession`. If you are tasked with registry integration,
  escalate — that requires a design call on how to handle lives within the host model.
- The game is rendered in full-screen `CustomPaint` inside a `GestureDetector`. It manages its
  own game-over overlay (tap to restart). Exit is via the host's guaranteed exit affordance.

## Files
- Widget: `lib/views/screens/mini_game_page/games/molecule_builder_game.dart`
  → `MoleculeBuilderGame`
- Spec: `GAME.md` (canonical rules — obey it; if rules change, update GAME.md first)
- Manual: `MANUAL.md`
- Scale education: `../EDUCATION.md`

## Tunable constants (current)
| Constant | Value | Effect |
|---|---|---|
| `_timeRemaining` init | 90.0 s | Round length |
| `_lives` init | 5 | Starting lives |
| `_targetAtomCount` | 14 | Field atom population target |
| H spawn weight | 8/20 = 40% | H spawn probability in pool |
| O spawn weight | 5/20 = 25% | O spawn probability |
| C spawn weight | 4/20 = 20% | C spawn probability |
| N spawn weight | 3/20 = 15% | N spawn probability |
| Needed-atom bias | 30% chance | Probability of picking a needed atom on spawn |
| Brownian nudge interval | 0.5–0.8 s | How often each atom gets a random impulse |
| Velocity cap | 60 px/s | Max atom speed |
| Magnetic range | (dragRadius + 20) × 3.5 | Radius of drag-atom attraction |
| Magnetic strength | 40 × (1 − dist/range) | Pull toward dragged atom |
| Auto-formation threshold | 1.4× (radiusA + radiusB) | Distance for automatic bonding |
| Combo window | 3.0 s | Time within which sequential orders extend the combo |
| Combo multiplier | 1.0 + combo × 0.25 | Score multiplier per combo step |
| Max orders (low score) | 3 | Active orders below score 500 |
| Max orders (high score) | 4 | Active orders at score ≥ 500 |
| Spawn delay | 0.3–0.5 s | Delay before replacement atoms enter from edges |
| Repulsion burst strength | 150 px/s | Velocity added per atom in a failed cluster |
| `_lastFulfillTime` combo window | 3.0 s | As above |

## Recipe table (by key = sorted atom types, joined by comma)
| Key | Formula | Points | Order window |
|---|---|---|---|
| H,H | H₂ | 10 | 20 s |
| H,H,O | H₂O | 25 | 30 s |
| C,O,O | CO₂ | 25 | 30 s |
| H,H,H,N | NH₃ | 40 | 35 s |
| C,H,H,H,H | CH₄ | 50 | 40 s |
| C,C,H,H,H,H,H,H | C₂H₆ | 80 | 50 s |

Matching logic: collect the dropped atom + all atoms within 2.5× combined-radius; enumerate subsets
of neighbors (2^n bitmask, max ~7 neighbors → 128 subsets); sort types, join with commas, look up
in `_kRecipeMap`. Prefer order-matching subsets; among ties, prefer larger subset.

## Auto-formation mechanic
Each tick (when not dragging): BFS from each atom to find clusters within 1.4× combined radii.
If a cluster matches a recipe exactly, it forms automatically — consuming those atoms and crediting
score. This fires before the player acts, so atoms can bond mid-drift. Design intent: chemistry
does not wait; the player is racing against thermodynamics.

## Known bugs / TODOs
- **No integration with `MiniGameSession`**: the game uses a standalone `AnimationController`
  clock (`duration: const Duration(days: 1)`) and calls `setState` directly for all game state.
  It cannot report scores to the registry host. Fix requires session integration (see GAME.md §
  "Session / resume" and escalation note above).
- **No exit affordance from the game itself**: the game-over screen has "Tap to restart" but no
  "Exit to board" button. The host's error boundary / guaranteed exit must remain active.
- **H₂ recipe**: hydrogen gas (H₂) is biologically uncommon; its inclusion is for mechanical
  simplicity (simplest possible recipe). Consider replacing with a more potato-relevant starter
  molecule — discuss with Brett before changing the recipe set.
- **C₂H₆ is ethane, not a biologically significant molecule**: it fills the high-difficulty slot
  but has no potato story. Same note as H₂ — keep for now unless a thematic replacement is
  identified.
- **Atom element set (H, O, C, N)**: Chlorine (Cl) from Molecule Mixer is not present here;
  neither is phosphorus. The set is intentionally minimal. Do not expand without a spec change
  in GAME.md first.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
- Atoms: filled circle + radial inner highlight + border ring + element letter (Avenir).
- Bonds: dashed white lines during drag preview.
- Order cards: rounded-rect background + formula text + atom-type dot row + countdown bar.
- HUD: lives as green/empty dot row (top-left), time as text (top-right), score (bottom-center),
  combo multiplier (bottom-right).
