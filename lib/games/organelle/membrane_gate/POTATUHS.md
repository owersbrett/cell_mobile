# POTATUHS.md — Membrane Gate

> How this game ties into the Potatuhs / Hot Potato Games brand.

## GAMES rubric status

| Letter | Criterion | This game |
|---|---|---|
| **G** | Game exists and is playable | `membrane_gate_game.dart` — a complete 60 s go/no-go transport game |
| **A** | Agent assigned | `AGENT.md` (this folder) |
| **M** | Manual / rules declared | `GAME.md` (this folder) |
| **E** | Educational component | `EDUCATION.md` (this folder) |
| **S** | Session close + re-enter | Host-owned clock; stateless reset on `hostReset` — closes and a fresh round starts clean |

## Brand fit

Cell biology is the spine of **Explore The Cell** (cell_mobile → explore-the-cell.web.app),
the launch artifact for the Hot Potato Games summer cycle. Membrane Gate sits at
the **organelle scale**, alongside Hungry Cell and Organelle Rush, teaching the
one property every cell game assumes: the membrane that defines "inside" vs.
"outside."

## Potato angle

The cell is a cell in a potato tuber. Its job is to **import water, ions, and
glucose to lay down starch**, while keeping out the microbes and toxins that turn
a firm tuber soft. The gatekeeper you play *is* the reason a healthy potato keeps.
Russ would call it "uhhh... border control, but for snacks."

## Visual language

Pure Potatuhs dark theme via `theme/potatuhs.dart` and `games/fx.dart`:
ink-deep background, orange/sienna phospholipid heads, gold nucleus glow that
brightens as the cell thrives, transport-cyan accent. No raster assets — every
molecule, the bilayer, and the channel proteins are Canvas-drawn.
