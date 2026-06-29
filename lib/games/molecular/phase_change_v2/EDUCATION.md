# EDUCATION — Phase Change v2

**Scale:** molecular · **Concept:** states of matter, phase transitions, and
**latent heat**.

## What the player learns by playing
The lesson is delivered through the mechanic, not a quiz — and v2 moves the key
idea to where the eyes actually are.

1. **Three states of matter.** The 36-molecule grid visibly changes behaviour
   with energy:
   - **Solid** — molecules lock into a rigid **lattice** (bonds drawn between
     neighbours); they only vibrate in place.
   - **Liquid** — bonds break and molecules **flow** past each other.
   - **Gas** — molecules have enough energy to **fly apart** and fill the box.

2. **Temperature ≠ energy.** The bottom strip plots **temperature vs. energy
   added**. Adding energy usually raises temperature — but at the melting and
   boiling points the curve goes **flat**.

3. **Latent heat (the key idea), taught at the point of action.** v1 buried this
   on the bottom curve, so a stalled thermometer read as a stuck control. v2
   detects when you're on a plateau (`_stateOf == -1`) and shouts **"BREAKING
   BONDS — energy → bonds, not heat"** right over the molecules. The player
   keeps pouring energy, the thermometer doesn't move, and the game *names why*:
   latent heat of fusion (melting) and vaporization (boiling).

4. **Every substance is different.** Each material (water, wax, mercury, glass,
   iron) has its own melting/boiling points and plateau widths. Mercury is
   liquid across a wide range; iron needs enormous energy just to melt.
   Switching substances each round shows phase behaviour is a property of the
   material — and the target band moves with it.

## Why v2 sticks better
The target is a tight **energy band** that often hugs a plateau edge, and
ambient cooling constantly bleeds energy away. To lock it you must **feather**
heat against the bleed without tipping onto the plateau. That feathering is the
felt experience of "I'm right at the edge of melting" — the precise intuition a
textbook diagram can't give. The frustration of "I'm adding heat and nothing's
happening" is now labelled physics, not a bug.

## Carry-out idea
Energy added at a phase boundary breaks bonds instead of raising temperature —
which is exactly why steam burns worse than boiling water (it dumps the latent
heat of vaporization back into your skin).
