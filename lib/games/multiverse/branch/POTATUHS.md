# Branch — POTATUHS.md

> Where this game sits in the Potatuhs / Hot Potato Games world.

## Vertical & objective
- **Vertical:** hotpotatogames (Summer rip — Tech/health).
- **Cycle:** 1 of 3 — **GAMES**. KPI: complete games (target 4). A game counts
  only when **all five** GAMES criteria are met: Game / Agent / Manual /
  Education / Session.
- **Launch artifact:** `cell_mobile` → `explore-the-cell.web.app`.

## GAMES rubric status
| Letter | Artifact | State |
|--------|----------|-------|
| **G** Game | `branch_game.dart` (`BranchGame`) | built, analyze-clean |
| **A** Agent | `AGENT.md` (Branchwright) | present |
| **M** Manual | `GAME.md` | present |
| **E** Education | `EDUCATION.md` (MWI) | present |
| **S** Session | host-driven close/re-enter | inherits framework |

## Where it lives
- Module: `lib/games/multiverse/branch/` — self-contained, no sibling-game deps.
- Scale: `BioScale.multiverseAll` — the outermost "all of everything" shelf,
  alongside Reality Merge. Branch is the **timeline-navigation** counterpart to
  Reality Merge's **alignment** mechanic — deliberately distinct in look (electric
  cyan branching tree vs. violet alignment rings) and feel (read-and-steer vs.
  time-the-lock).

## Brand voice notes
- Tagline energy: many-worlds made playable — *"every choice splits the world,
  and both happen."*
- Visual identity: a living branching tree of timelines on a dark ink field;
  electric cyan worldline, decohering violet ghosts.

## Registry wiring (owned by the orchestrator, not this module)
- `mini_game_registry.dart`: add the `MiniGameSpec` for id `branch` + the import
  `import 'multiverse/branch/branch_game.dart';`.
- `game_catalog.dart`: add a `CatalogGame` with `specId: 'branch'`.
- This module never edits those files itself.
