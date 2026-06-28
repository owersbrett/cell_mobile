# POTATUHS — Molecule Builder

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Molecule Builder — the molecular-scale drag-to-bond order game. Legacy standalone
  module (`lib/views/screens/mini_game_page/games/molecule_builder_game.dart`, `MoleculeBuilderGame`);
  on `BioScale.molecular`, owns its own 90s clock and lives — predates the registry.
- **O — Objectives:** post the highest score by filling live molecule orders before they expire — survive
  the round without running out of lives. Sub-goals: chain fulfillments to build the combo multiplier and
  climb into the harder recipe tiers.
- **T — Tasks (the play to-do list):** read the row of order cards (3, then 4 at score > 500) and their
  shrinking countdown bars · drag an atom (H, O, C, N) into a nearby cluster · release to snap a recipe
  (H₂ · H₂O · CO₂ · NH₃ · CH₄ · C₂H₆) · prioritize the order about to expire · keep fulfillments within 3s
  to hold the combo.
- **A — Automations (firing in the background):** the standalone 90s timer + 5-life counter · ~14 atoms
  drifting with Brownian motion + soft-body repulsion · the **auto-formation** rule — atoms that drift
  within 1.4× combined-radius bond on their own, no input needed · order expiry costing a life · atom
  supply auto-replenishing from the edges after a 0.3–0.5s delay · score-gated recipe re-weighting.
- **T — Testing (experimental / in-flight):** not yet wired to `MiniGameSession` — promotion would mean
  deferring the clock to the host and a design call on the **lives** mechanic (the host doesn't model
  lives), which is the key tension differentiator worth preserving. H₂ is flagged as a candidate to swap
  for a more potato-relevant molecule.
- **U — UX:** Canvas-only — atom circles with inner glow, dashed bond-hint lines while dragging, magnetic
  attraction pulling neighbors toward the dragged atom · order cards with formula + atom-dots + countdown ·
  lives dots (top-left), timer (top-right), score (bottom-center), combo (bottom-right) · green flash on
  fulfill, red burst + screen flash on a wrong combo.
- **H — Heuristics (how you actually win):** service the most-expired order first to protect lives · let
  auto-formation do free bonus builds (+5) while you steer the urgent ones · stage atoms near a cluster so
  a single drag closes a recipe · keep the 3s combo alive — the multiplier (1.0 + combo × 0.25) dwarfs
  raw recipe points · learn the recipe table so you never release a non-match (it scatters atoms).
- **S — Systems (what makes the world feel alive):** a drifting molecular soup where atoms bond *without
  you* — chemistry happening on its own — is the living system at the core · the order-card urgency frames
  CO₂ and NH₃ as the very molecules a potato plant absorbs, so the same bonding you race against happens
  quietly in the leaf's stroma.
