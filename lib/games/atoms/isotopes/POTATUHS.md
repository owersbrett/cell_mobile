# POTATUHS — Isotopes

> The POTATUHS lens applied to one game: every game is itself a **Project** with
> Objectives, Tasks, Automations, Testing, UX, Heuristics, and Systems. One
> profile per game (template instance).

- **P — Project:** Isotopes — the atoms-scale build-a-spec nuclide puzzle. Module
  at `lib/games/atoms/isotopes/isotopes_game.dart` (`IsotopesGame`); registry
  game on `BioScale.atoms`.
- **O — Objectives:** post the highest timed score by building the most named
  nuclides. Sub-goals: lock fast (full speed bonus), ride an unbroken streak, and
  climb into the harder prompt tiers (named mass numbers → neutron counts → raw
  ᴬX notation) across a widening element pool (Z ≤ 8 → 26).
- **T — Tasks (the play to-do list):** read the prompt · dial PROTONS to make the
  named element (watch the live name lock to it) · dial NEUTRONS until the mass
  number A matches · confirm both ELEMENT and ISOTOPE pills are green · LOCK IT IN
  · repeat against the next, terser prompt.
- **A — Automations (firing in the background):** the difficulty engine —
  `_allowedPool` widens the element set at 3 / 7 / 12 solves and `_chooseKind`
  unlocks harder prompt phrasings at 2 / 4 / 7 solves, weighting the newest ·
  the per-prompt speed-bonus runway decaying over 7 s · live Z→element / A=Z+N
  recomputation on every stepper tap · the one-Ticker clock driving the nucleus
  spiral, electron orbits, and juice via a single `_NuclidePainter`.
- **T — Testing (experimental / in-flight):** ions (a third electron stepper +
  net-charge prompt axis) are the headline future extension, deliberately cut
  from v1 · a "same element, new isotope" combo bonus and an N/Z stability tint
  are open polish items · no audio.
- **U — UX:** a prompt card with twin ELEMENT/ISOTOPE confirm pills · a live
  isotope-notation readout (ᴬsymbol + Z / N / A chips) · two big +/- steppers
  (red protons, grey neutrons) whose values glow green on match · a `CustomPainter`
  atom (golden-angle proton/neutron core, faint neutral-atom electron shells) that
  blooms green when correct · a LOCK IT IN button that arms (green, "✓") only when
  both axes match · a centred "✓ / NOT A MATCH" banner.
- **H — Heuristics (how you actually win):** memorise the light elements' proton
  counts so you snap to the right Z instantly · compute neutrons as A − Z (or read
  it straight off "with N neutrons") · don't fish — a wrong lock breaks the streak ·
  lock the instant both pills go green to bank the speed bonus · keep a clean
  streak running for the +min(streak,8) bonus and the results-screen mastery award.
- **S — Systems (what makes the world feel alive):** the live atom that *becomes*
  whatever you dial — its identity flipping with every proton and its mass growing
  with every neutron · the two-axis identity/isotope model surfaced as two
  independent green gates · the self-terseing prompt ladder that quietly turns a
  count-it-out exercise into fluent isotope-notation reading.
