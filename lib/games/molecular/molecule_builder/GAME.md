# GAME.md — Molecule Builder

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** molecular
- **Game id:** molecule_builder
- **One-line concept:** Drag atoms together to match live molecule orders before they expire —
  lose a life for every order that times out.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore (build to order)

Atom clouds drift around the screen. A row of order cards at the top shows molecules you need to
build — with a countdown bar shrinking on each one. Drag an atom into the cluster of others nearby
and watch them snap together if the combination matches a recipe. Fill the orders before they
expire; run out of lives and the round is over. The urgency is the toy; the bonding rules are the
teaching.

---

## Rules (canonical — as implemented in `MoleculeBuilderGame`)

1. ~14 labeled atom bubbles (H, O, C, N) drift freely on the play field with Brownian motion
   and soft-body repulsion between them.
2. A row of **order cards** at the top (3 active, 4 at score > 500) each show a target formula
   and a countdown timer bar.
3. **Drag an atom** close to others. When you release, the game checks if the dropped atom and
   its neighbors form a valid recipe (see recipe table below). If yes, the atoms are consumed,
   the matching order is fulfilled, and you score points.
4. **Order fulfillment:** if the assembled formula matches an active order, that order flashes
   green, the score credits, and a new order replaces it. If the formula is valid but no order
   matches, it is a "bonus build" worth a flat +5.
5. **Wrong combination:** if the released atom is near others but no recipe matches, a **repulsion
   burst** fires — nearby atoms scatter and a brief red screen flash occurs.
6. **Order expiry:** when an order's countdown reaches zero, a life is lost and the card flashes
   red. Starting lives: 5. Zero lives = game over (reason: "NO LIVES").
7. **Timer:** 90-second round. Reaching zero = game over (reason: "TIME").
8. **Combo:** fulfilling orders within 3 seconds of each other extends a combo multiplier
   (`1.0 + combo × 0.25`). Displayed in the bottom-right.
9. **Auto-formation:** atoms that drift within 1.4× combined-radius proximity automatically
   form a molecule if their types match a recipe — independent of player input. This is a
   deliberate mechanic: atoms bond without you, just as they do in chemistry.
10. **Atom supply:** the field maintains ~14 atoms. When atoms are consumed, replacements enter
    from the edges with a 0.3–0.5 s delay.

---

## Recipe table

| Formula | Atoms required | Points | Order window |
|---|---|---|---|
| H₂ | H + H | 10 | 20 s |
| H₂O | H + H + O | 25 | 30 s |
| CO₂ | C + O + O | 25 | 30 s |
| NH₃ | N + H + H + H | 40 | 35 s |
| CH₄ | C + H + H + H + H | 50 | 40 s |
| C₂H₆ | C + C + H + H + H + H + H + H | 80 | 50 s |

Matching is by sorted atom type — the geometry is not validated, only the composition. This is a
game-design simplification; the educational value is in recognizing what atoms belong together.

---

## Difficulty curve (score-gated)

| Score range | Recipe weights (H₂ / H₂O / CO₂ / NH₃ / CH₄ / C₂H₆) |
|---|---|
| 0–99 | 50 / 30 / 20 / 0 / 0 / 0 |
| 100–299 | 30 / 25 / 25 / 20 / 0 / 0 |
| 300–499 | 15 / 25 / 20 / 25 / 15 / 0 |
| 500+ | 10 / 20 / 15 / 20 / 20 / 15 |

Max simultaneous orders bumps from 3 to 4 at score > 500.

---

## Controls

Drag (pan gesture) to pick up and move an atom; release to attempt molecule formation. Magnetic
attraction: while dragging, nearby atoms are gently pulled toward the dragged atom to help cluster
formation. Tap anywhere when the pre-game or game-over screen is shown to start/restart.

Canvas-drawn only: atom circles with inner highlight glow, dashed bond-hint lines while dragging,
order cards with formula text + atom-dot indicators + countdown bar, lives dots (top-left),
timer (top-right), score (bottom-center), combo multiplier (bottom-right). No raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Order fulfilled (matching) | recipe.points × (1.0 + combo × 0.25), rounded |
| Bonus build (no active order) | +5 |
| Order expired | −1 life |

Combo: increments when two fulfillments happen within 3 s; resets otherwise. Display: `x{combo+1}`.

---

## Win / end condition

Round ends when either:
- The 90-second timer expires (reason: "TIME")
- Lives reach 0 from expired orders (reason: "NO LIVES")

Game-over screen shows: score (large), molecules built, percentage of orders filled.
Tap to restart. No host integration for timer/results in current (legacy) implementation —
this game predates the `MiniGameSession` registry system and owns its own clock and state.

---

## Educational blocks engaged

- **Water ✅** — H₂O is in the recipe set. Player assembles the formula.
- **Air Content ✅** — CO₂ and NH₃ (nitrogen-compound) are both recipes, touching the atmospheric
  chemistry block (CO₂ + N₂ component).
- **Carbon ✅** — C appears in CO₂, CH₄, and C₂H₆. Recognizing that carbon atoms combine with
  hydrogen or oxygen in specific ratios is the core challenge at higher difficulty.
- **Carbohydrates ⚠️** — C₂H₆ is ethane (not a carbohydrate), but the C + H combination at
  higher difficulty introduces carbon chains, conceptually adjacent to glucose's C₆H₁₂O₆.
- **Proteins, Lipids, Nucleic Acids, Solanine, Vitamin C, ATP ❌** — Not engaged.

---

## Potato angle

The order cards create urgency around molecules that are also in the potato's chemistry: CO₂ is
what the potato plant absorbs to build glucose, NH₃ is the nitrogen form soil bacteria convert
into plant food. Drag them together, watch them bond — the same process happens in the leaf's
stroma, just without the timer.

---

## Session / resume

Current implementation does not integrate with `MiniGameSession` — it owns a standalone
90-second clock, lives counter, and score. If promoted to the registry system, the following
must persist: score, time remaining, lives, order queue state (each order's formula and time
remaining), combo counter, last fulfillment time.

---

## Implementation

- Current: `lib/views/screens/mini_game_page/games/molecule_builder_game.dart`
  (`MoleculeBuilderGame`) — legacy game, not in registry.
- **Status:** fully functional standalone game; wiring into the registry system would require
  adapting to `MiniGameSession` (removing the internal clock/lives, deferring to host timer).
  Lives mechanic would need a design call — the host doesn't currently model lives.
- **Potential:** the auto-formation mechanic (atoms bond on their own when they drift close) is a
  genuinely interesting design idea that the canonical game (Molecule Mixer) does not have. Worth
  preserving if this game is promoted to a second slot.

---

## Decisions for a build agent

- The auto-formation feature is a strong differentiator from Molecule Mixer. Keep it.
- The H₂ recipe (hydrogen gas) is not biologically significant. If the recipe set is tuned,
  H₂ could be replaced with a more potato-relevant molecule (e.g. glucose components C₆H₁₂O₆
  is too large, but a simpler C₂H₂ or CH₂O as a formaldehyde-proxy step toward sugar synthesis
  could work thematically).
- The lives mechanic is the key tension differentiator from Molecule Mixer (time-only). Consider
  preserving lives even if integrating into the registry host.
