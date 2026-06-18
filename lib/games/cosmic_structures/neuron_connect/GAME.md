# GAME.md — Neuron Connect (refinement + 3D layers)

> Canonical spec for the Cosmic-Structures-scale game. Graphics have improved; this refines the input
> (flick to aim), sharpens the goal (complete the circuit), and adds a 3D-layer dimension at depth.

- **Scale (cell):** cosmicStructures
- **Game id:** neuron_connect (widget `NeuronConnectGame` in `mini_games_batch3.dart`)
- **One-line concept:** Aim each neuron's gate so the signal flows source → target and **completes the
  circuit.** Deeper levels go **3D** — route through stacked layers to reach the nodes you can turn.
- **Role:** solo high-score

## Change 1 — Flick to aim (replaces tap-to-cycle)
- Instead of tapping a neuron to cycle its gate, **flick the neuron in a direction** to point its gate
  that way (up/down/left/right; diagonals if it fits). Flick = intuitive, tactile, directional. A short
  flick reads as the cardinal direction nearest the swipe angle.
- Keep locked nodes (un-flickable) and blockers as obstacles.

## Change 2 — Complete the circuit (sharpen the goal)
- The objective is explicitly **completing the circuit**: route the signal from the source neuron to
  the target so the path lights up end-to-end, then fire. Frame the win as "CIRCUIT COMPLETE."
- A faint "incomplete" vs "live" state on wires makes the goal legible (you can see how close the
  circuit is to closing).

## Change 3 — 3D layers at deeper levels (the ambition)
- From a threshold level onward, the board becomes **multiple stacked layers** (a 3D grid).
- The signal must **travel through layers** — special **via / interlayer nodes** move it up or down a
  layer. To reach some turnable nodes, you must first route through another layer.
- **Render with depth:** stacked grids drawn with an isometric/parallax offset (Canvas-only) so layers
  read as front/back; the active layer is bright, others dimmed; the signal visibly dips between layers
  at via-nodes. Let the player **switch the focused layer** (e.g. a layer selector / pinch or two-finger
  swipe to change depth) to flick nodes on the layer they're viewing.
- Escalation: more layers + more interlayer dependencies as levels deepen.

## Keep
- Grid grows with level, blockers + locks ramp, BFS-guaranteed solvable generation, fire-signal +
  particle payoff on completion, fact flares.

## Educational angle
The mechanic — routing signals through a connected network of nodes, across layers — doubles for the
scale's blocks: the **Cosmic Web** is exactly a 3D network of **filaments** connecting nodes across
**voids**. Lean the fact flares into that (cosmic web / filaments / voids), so the "neuron circuit"
visual teaches the large-scale structure of the universe too.

## Implementation
- Rework `NeuronConnectGame` in `mini_games_batch3.dart` (edit ONLY that class — megafile; self-
  contained). Phase it: (1) flick-to-aim + circuit framing first, then (2) the 3D-layer system for
  deeper levels. Canvas-only. Reuse the existing grid/signal/generation code; swap the input model and
  add the layer dimension.
