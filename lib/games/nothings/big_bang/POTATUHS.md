# POTATUHS — Big Bang

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Big Bang ("First Light") — the nothings-scale tap-to-summon-void game and the
  standard **onboarding** game for Explore the Cell. Docs at `lib/games/nothings/big_bang/`; what
  Explore actually renders is the arcade tap-base (`lib/games/arcade/big_bang_arcade.dart`).
- **O — Objectives:** in the darkness, gather the most **light** and ignite the most **stars** before
  the clock ends. Sub-goals: fill the star meter to ignite; avoid swallowing **matter** that
  shouldn't exist yet; place voids precisely as spawn density climbs.
- **T — Tasks (the play to-do list):** tap to summon a void at a point · let it auto-suck nearby
  light motes · steer placement toward dense light, away from drifting matter · cash the star meter
  on each ignition · keep re-summoning as the field gets crowded late.
- **A — Automations (firing in the background):** the void's **auto-suction radius** (pulls light
  once placed) · the per-frame tick driving motes, vortex bending, starfield and ignition bursts ·
  the rising **spawn rate** and matter:light ratio over time · MiniGameHost's host-owned clock,
  3-2-1 countdown and results.
- **T — Testing (experimental / in-flight):** the game is a **lore-accurate redesign in flight** —
  the two existing builds predate the light-collection spec (arcade taps matter/antimatter; legacy
  forges H→Fe) and need rework toward summon-void + light-suction + star ignition. Resume
  persistence (score, meter, star count, field) is required and not yet wired.
- **U — UX:** a full-screen field of **darkness** as canvas · glowing light motes drifting through ·
  voids drawn as dark vortices with light bending inward · a star meter filling toward ignition ·
  particle bursts + a new star on the sky each ignition. Canvas-drawn only, no raster assets.
- **H — Heuristics (how you actually win):** summon voids **inside clusters of light**, not on lone
  motes · keep voids clear of matter — a swallowed mote of matter is a penalty that eats meter
  progress · cash ignitions promptly · late game is precision placement, so read the field before
  every tap.
- **S — Systems (what makes the world feel alive):** the **radiation-dawn** theme — only light and
  darkness exist, matter "shouldn't exist yet" · darkness as the living medium everything happens
  inside · light gathering into the universe's **first stars**, the emergence beat at the heart of
  the nothings scale: from nothing, everything.
