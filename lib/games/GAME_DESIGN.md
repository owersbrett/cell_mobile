# Mini-Game Design Standard — Explore The Cell / HotPotatoGames

**Read this before building or reworking any mini-game.** It exists because a
game should never ship looking like flat geometric primitives on a black void
(generic teal rings + arrows = unacceptable). Every game must look *intentional,
premium, and on-brand*, and play to the studio's gameplay law.

This complements the canonical Potatuhs design system at
`~/Potatuhs/potatuhs-design/DESIGN.md` and the in-app kit `lib/theme/potatuhs.dart`.

---

## 1. The gameplay law (non-negotiable)
- **~60 seconds**, single satisfying loop.
- **Point-driven**, score always visible.
- **Difficulty escalates until a perfect run is humanly impossible** — scores
  cluster at peak skill, never at a tie ceiling.
- **Clear objective**: the player must understand what to do in <3 seconds.
- **Teach in-context**: a WarioWare-style instruction banner per phase, and if
  the player is clearly doing badly (no points for a few seconds, or a phase
  about to fail), surface a brief mid-game HINT showing the control.
- Always provide a way to **quit/forfeit**.

## 2. Palette — pull from the theme, never random hex
Use `lib/theme/potatuhs.dart` (`Potatuhs.gold/orange/sienna/airForce/glaucous/
copper`, `inkDeep/inkPanel/ink`, `textPrimary/Secondary/Faint`) and the game's
**scale accent**. One accent per game + the warm neutrals. Backgrounds are a
**gradient** (e.g. `inkDeep`→ a dark tint of the accent), never flat `#000`.
No grab-bag of unrelated saturated colors.

## 3. Typography
- **Bowlby One SC** (`Potatuhs.display(...)`) — hero titles, big callouts, the
  WarioWare phase banner, score milestones.
- **Outfit** (`Potatuhs.body(...)` / `Potatuhs.label(...)`) — all HUD/UI/body.
- Do **not** use `'Avenir'` in new/reworked code (legacy). Wrap long names —
  **never ellipsize** a label the player needs to read.

## 4. The anti-flat-circle rule — objects must look like THINGS
A game object is never a single flat stroked shape. Build every important
element in layers:
1. **Glow halo** — `MaskFilter.blur` in the object's color (depth + life).
2. **Gradient body** — `RadialGradient` with a light highlight toward top-left
   and a darker edge/bottom (reads as a 3D orb/sphere, not a sticker).
3. **Rim** — a thin brighter or darker stroke.
4. **Representational detail** — make it READ as what it is:
   - neuron → soma + branching dendrites/axon + synaptic spark, not a ring+arrow
   - planet/star → shaded sphere + atmosphere rim + maybe a ring/craters
   - bug → body + legs + eyes + antennae
   - potato/tuber → textured oval with eyes, earthy gradient
   - cell/organelle → membrane + nucleus + inner texture
If your element is a `drawCircle` with one color and a letter, it is wrong.

## 5. Motion & juice (always on)
- **Everything moves a little** — idle bob/sway/pulse/drift, eased (never linear).
- **Success** → particle burst + a floating score pop (`+N`) + a brief glow/flash.
- **Failure** → red flash + small screen shake.
- **Transitions** eased (`Curves.easeOut`/`easeInOut`), things scale/fade in.
- A subtle animated **background** (drifting motes, starfield, shimmer) themed
  to the scale.

## 6. HUD standard
Top bar: **score** + **time remaining** + context (phase/level), on a
gradient-faded strip. Timer turns warning-red in the final ~5s. Keep it compact
and legible; don't let it fight the play field.

## 7. Reference bar (study these before building)
Good, on-standard examples in `lib/games/arcade/`: `atom_builder.dart`,
`grow_the_plant.dart`, `corners.dart`, `collider.dart`. Match that level of
layering, glow, motion, and readability. If your result looks flatter than
those, it's not done.

## 8. DON'Ts (instant rejection)
- Flat primitive shapes (plain `drawCircle`/`drawRect`) as the main visual.
- Flat black background.
- Random/unbranded hex colors; `'Avenir'`.
- Tiny cramped or ellipsized labels.
- Un-juiced interactions (a tap with no feedback).
- A game where the player can't tell what to do or how to score.
