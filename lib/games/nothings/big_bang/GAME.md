# GAME.md — Big Bang (working lore name: "First Light")

> The canonical spec. This outranks the code: if we re-implement, this survives.
> NOTE: this spec reflects the **lore-accurate redesign** (light collection). The two current
> implementations predate it and capture matter/forge elements — they need rework to match
> (see "Implementation status" below).

- **Scale (cell):** nothings
- **Game id:** big_bang
- **One-line concept:** In the darkness, tap to summon a **void** that drinks in **light** — gather
  enough light to ignite **stars**, while avoiding the **matter** that shouldn't exist yet.
- **Role:** solo high-score (and the standard **onboarding** game for Explore the Cell)
- **Six-in-one?** no

## Lore (must stay accurate)
At the Nothings scale, **matter does not properly exist yet** — only **light** and **darkness**.
This is the radiation-dawn of the universe. The three building blocks of this scale:

1. **Light** — the good. Collect it; light accumulates and **forms stars**. (Light = "on" = 1.)
2. **Darkness** — the medium. Everything takes place inside it; it is the play space, not a
   target. (Darkness = "off" = 0.)
3. **Matter / dark matter** — the hazard. It "**shouldn't exist yet**" at this scale, so pulling
   it into your void is **bad**. (Matter is the realm of the *next* scale — somethings/material.)

The element-forging arc (H→Fe nucleosynthesis) does **not** live here anymore — stars are *made*
here; elements are *forged* later (in a star/material scale). This game ends at "let there be stars."

## Rules (canonical — redesign)
1. The screen is **darkness**. Motes of **light** drift through it.
2. **Tap** anywhere to **summon a void** at that point. The void **auto-sucks in nearby light**.
3. Collected light fills a **star meter**; when it's full, a **star ignites** (score + a star
   added to the sky).
4. **Matter / dark matter** also drifts in. If your void sucks in matter, it's a **penalty** —
   matter shouldn't exist yet. Position voids to pull light, not matter.
5. Darkness itself is never collected — it's the canvas.

## Controls
**Tap to summon a void** (auto-suction radius). Canvas-drawn only — voids as dark vortices with
light bending in, light as glowing motes, stars as procedural points of light, particle bursts on
ignition. No raster assets.

## Scoring (redesign — to tune)
- Each light mote drawn into a void: **+points**.
- Igniting a star (meter full): **bonus + a star on the field**.
- Sucking in matter/dark matter: **penalty** (lose light/meter progress).
- Goal: most light gathered / most stars ignited before time runs out.

## Win / end condition
Timer-based score attack. Most stars ignited (and light gathered) wins. (Optional stretch: a
target number of stars to "win" the dawn — TBD.)

## Difficulty curve (to tune)
Light/matter spawn rate rises over time; ratio of matter to light increases so late game is about
precise void placement to drink light without swallowing matter.

## Educational blocks engaged (strengthened by the new lore)
- **Binary Nothing (1/0):** ✅ light = on = 1, darkness = off = 0 — the simplest distinction.
- **The Void:** ✅ darkness is the medium; the void you summon is literally the mechanic.
- **Emergence — From Nothing, Everything:** ✅ light gathers into the first stars.
- **Nothing as Something:** ✅ matter "shouldn't exist yet" — collecting it is the paradox/hazard.
- **Zero:** ⚠️ darkness-as-zero, light-as-one (light math; a dedicated math game can deepen it).

## Potato angle
Light → stars → (later) the forged elements that build a potato. From pure light in the dark,
the long road to potato-stuff begins. Light touch here; payoff at larger scales.

## Session / resume
Persist score, elapsed time, star meter, ignited-star count, and active light/matter field.

## Implementation status — needs rework to match this lore
Both existing implementations predate the light-collection redesign:
1. **`lib/games/arcade/big_bang_arcade.dart` (`BigBangArcade`)** — registry/party, tap **matter**
   vs antimatter + combo/waves. **This is what Explore actually shows for nothings** (the registry
   intercepts before the legacy switch).
2. **`lib/views/screens/mini_game_page/games/big_bang_game.dart` (`BigBangGame`)** — legacy,
   hold-and-release sizing, captures **matter**, forges H→Fe. **Dead code for nothings** in Explore.

**Recommendation:** re-implement around this spec — tap-to-summon-void + light-suction + star
ignition + matter-as-hazard. The arcade tap base is the closer starting point. Keep darkness as
the play space. Brett to confirm before code work; a scoped agent can build it from this GAME.md.
