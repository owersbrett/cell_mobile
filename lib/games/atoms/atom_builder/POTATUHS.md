# POTATUHS — Atom Builder

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Atom Builder — the atoms-scale particle-collector. Module at
  `lib/games/arcade/atom_builder.dart` (`AtomBuilderGame`); registry game on `BioScale.atoms`.
- **O — Objectives:** post the highest timed score by building one continuously growing atom up the
  noble-gas ladder (He→Ne→Ar→Kr→Xe). Sub-goals: bank all four N-P-S-K fertilizer nutrients; clear
  each shell checkpoint perfectly balanced.
- **T — Tasks (the play to-do list):** tap streaming particles within 48 px to collect them · add
  protons to climb the element ladder · pair neutrons alongside protons to stay stable · only add an
  electron when a proton exists to orbit · hit each noble checkpoint at `p = n = e` to advance.
- **A — Automations (firing in the background):** the per-frame physics sim — Coulomb pull of
  electrons toward protons, free neutrons barreling and scattering · the spawner whose rate/speed
  scale to the `max(timeRamp, tempo, built)` drive · nuclear-decay timer that strips a proton at
  `instability ≥ 1.0` · extra neutron disruptors injected at `drive > 0.3`.
- **T — Testing (experimental / in-flight):** the **cosmic-provenance WOW flare** is the primary
  build TODO (no auxiliary forging/potato-role surface yet) · no in-session restart button · faint
  unfilled-shell guide rings and `_spawnAccum` pause-clamp are open polish items.
- **U — UX:** a full-field tap surface · `CustomPainter` particles (red `+` / grey `n` / blue `−`) ·
  the atom drawn at `(w/2, h×0.72)` with a golden-angle nucleus spiral + concentric electron shells ·
  instability glow indigo→amber with nucleus jitter · top target panel · bottom-left N/P/S/K pip row.
- **H — Heuristics (how you actually win):** add a neutron for every proton to dodge decay · never
  grab an electron you can't orbit (−3) or a particle past shell cap (−10) · cross Z=7/15/16/19 to
  bank the +25 nutrients early · ride a clean streak (tempo speeds the swarm but feeds points).
- **S — Systems (what makes the world feel alive):** the self-escalating swarm where good play
  speeds the field up · the live atom growing through five real noble shells · star-forged-to-soil
  N-P-K chemistry — every element you assemble was forged in a star and washed into a potato's dirt.
