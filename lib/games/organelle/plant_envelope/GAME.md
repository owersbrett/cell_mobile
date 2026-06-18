# GAME.md — The Plant Envelope

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **Status: UNBUILT — forward build-spec. Build from this document.**

- **Scale (cell):** organelle
- **Game id:** plant_envelope
- **One-line concept:** Molecules try to cross the cell's boundary layers — tap to let them
  through or block them, managing turgor pressure and starch storage in a layered defence game
  that puts the plasma membrane, cell wall, central vacuole, chloroplast, amyloplast, and
  plasmodesmata all on screen at once.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

The Somethings scale showed that containers make things possible — a boundary is what
separates something from nothing. Here, that idea pays off at the cell level. A plant cell
is not one wall but a *system* of nested boundaries: the plasma membrane, the cell wall
outside it, the central vacuole pressing out from within, and the chloroplast and amyloplast
as specialized inner vaults. Plasmodesmata punch through the wall to connect neighboring cells.
The game makes each boundary a mechanic, not just decoration.

The potato payoff: the amyloplast is the organelle that does nothing but pack starch. Every
starch granule in a potato chip was sealed inside an amyloplast. In this game the amyloplast
is the vault the player is protecting — and filling.

Solanine tie: the chloroplast is also the source of greening. When a potato is exposed to
light, its chloroplasts activate and the cell begins producing solanine as a defense compound.
The game surfaces this as a hazard: sunlight waves that penetrate to the chloroplast trigger
a solanine warning, docking points if left unblocked.

---

## Rules (canonical)

1. **The canvas shows a cross-section of a plant cell boundary.** Left to right, innermost to
   outermost: Central Vacuole | Cytoplasm | Plasma Membrane | Cell Wall (outer layer). Below
   the plasma membrane, a Chloroplast and an Amyloplast are visible as labeled ovals. Dotted
   channels through the cell wall represent Plasmodesmata.

2. **Molecules and hazards stream inward and outward.** They appear at the outer edge (cell wall)
   and move toward the interior, or appear at the vacuole and move outward. Types:
   - **Water (blue drop)** — should enter freely; helps fill the vacuole (turgor).
   - **Glucose (orange hexagon)** — should be allowed in; feeds the amyloplast.
   - **CO₂ (grey double-circle)** — should enter; feeds the chloroplast.
   - **Toxin (red spiky circle)** — must be blocked at the plasma membrane.
   - **Solanine wave (yellow pulse)** — triggered by a sunlight burst; must be blocked at the
     chloroplast layer before it reaches the central vacuole.
   - **Overflow (white overflow arrow)** — too much water or glucose at once; must be routed
     through plasmodesmata channels (tap a plasmodesmata channel to vent excess).

3. **Tap to gate.** Each boundary layer has an active zone (a horizontal band across the canvas).
   - **Tap a molecule** in the cell wall zone to admit or block it — a molecule's type determines
     whether admission or blocking is the correct action. The game shows a brief "✓ ADMIT" or
     "⊘ BLOCK" indicator when the molecule reaches the membrane band.
   - **Correct gate action:** +8 points.
   - **Wrong gate action (e.g., blocking water, admitting toxin):** −10 points.

4. **Turgor pressure meter** — a vertical gauge on the left, driven by water admitted. Too low =
   the cell goes limp (−5 points/s penalty while below the threshold). Too high (overflow) = the
   player must tap a plasmodesmata vent to equalize.

5. **Amyloplast fill gauge** — a small starch-granule counter on the amyloplast oval. Admitting
   glucose increments it. Each 5-unit fill = +15 bonus ("STARCH PACKED"). This is the potato
   payoff beat; the amyloplast label reads "AMYLOPLAST — Starch Vault."

6. **Chloroplast solanine trigger.** Every 12–15 seconds a sunlight burst crosses the outer wall.
   If CO₂ is not being admitted (the chloroplast is idle), the sunlight activates greening and
   a solanine wave spawns. If the player does not block the solanine wave at the chloroplast
   band within 2 seconds, −15 points and a "SOLANINE — GREEN POTATO" warning flare. If blocked
   in time, +10 points and a "CHLOROPLAST DEFENDED" banner.

7. **Session ends when time expires.** Score is reported to the host.

---

## Controls

Tap anywhere in the active band of a boundary layer to gate the nearest molecule in that band.
Tap a plasmodesmata channel (dotted line in the cell wall) to vent excess turgor.

Canvas-drawn only:
- **Cell cross-section** — layered bands: outer (Cell Wall, beige), middle (Plasma Membrane,
  blue gradient), inner left (Central Vacuole, lavender fill). Organelles drawn as labeled ovals:
  Chloroplast (dark green), Amyloplast (pale tan labeled "Starch Vault"), with small starch-granule
  circles inside.
- **Plasmodesmata** — dotted lines punching through the cell wall band.
- **Molecules** — each type has a distinct shape and color (see §Rules #2).
- **Sunlight burst** — a bright wedge sweep from the outer edge.
- **Turgor gauge** — left-edge vertical bar, blue fill, two threshold marks.
- **Amyloplast fill gauge** — stacked granule dots inside the amyloplast oval.
- **Solanine wave** — yellow-green pulse ring that expands inward.

---

## Scoring

| Event | Score |
|---|---|
| Correct gate action (admit or block) | +8 |
| Wrong gate action | −10 |
| Solanine wave blocked at chloroplast | +10 |
| Solanine wave missed (reaches vacuole) | −15 |
| Amyloplast starch fill milestone (every 5 units) | +15 |
| Turgor too low (per second below threshold) | −5/s |
| Overflow vented through plasmodesmata | +5 |

---

## Win / end condition

Timed score attack. Session duration set by the host. Highest score at time-up wins.

---

## Difficulty curve

Three levers:
1. **Molecule speed** — scales linearly from 1.0× to 2.0× over the session.
2. **Molecule variety** — first 15 s: only water and glucose. After 15 s: toxins added. After
   30 s: solanine events and overflow events enabled.
3. **Spawn rate** — interval shrinks from 1.6 s to 0.6 s over the session.

Key tunables:
- `_kSpeedMin` = 1.0, `_kSpeedMax` = 2.0
- `_kSpawnIntervalMin` = 0.6 s, `_kSpawnIntervalMax` = 1.6 s
- `_kSolanineInterval` = 12–15 s (randomized)
- `_kSolanineWindow` = 2.0 s — time to block before penalty
- `_kTurgorLowPenaltyRate` = 5 pts/s
- `_kStarchFillMilestone` = 5 — glucose units per +15 bonus
- `_kGateScore` = 8
- `_kGatePenalty` = 10
- `_kSolanineBlockScore` = 10
- `_kSolanineMissPenalty` = 15

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Plasma Membrane | The middle boundary band; the primary gating layer — students learn that it is selective (water/glucose in, toxins out) | ✅ |
| Cell Wall | The outer band; structurally present; plasmodesmata channels pierce it | ✅ |
| Central Vacuole | The turgor gauge IS the vacuole — players feel that a vacuole full of water keeps the cell firm | ✅ |
| Chloroplast | Solanine mechanic: idle chloroplast + sunlight = solanine. Teaches CO₂ uptake and the greening/toxicity link | ✅ |
| Amyloplast | The starch vault and the game's main scoring loop — glucose in, starch packed, potato payoff. Not in `organelle_entities.dart` (TODO flagged by other agent) | ✅ |
| Plasmodesmata | Vent mechanic — venting overflow through the dotted channels teaches that they equalize pressure between cells | ✅ |
| Cytoplasm | The interior band; molecules travel through it; labeled for context | ⚠️ (contextual) |

---

## Potato angle

This is the most concentrated potato moment in the entire scale. Three direct connections:

1. **Amyloplast = the potato's starch vault.** Every starch granule in a potato chip was packed
   inside an amyloplast. The game's primary scoring loop is literally filling that vault with
   glucose converted to starch. The amyloplast label reads "AMYLOPLAST — Starch Vault" and the
   fill gauge shows granules stacking up inside it.

2. **Solanine hazard = green potato warning.** Solanine is the alkaloid a potato plant makes when
   its skin turns green from light exposure. The game's solanine mechanic directly teaches why
   green potatoes are toxic — sunlight activates chloroplasts which triggers solanine production.
   The WOW flare on a solanine miss reads: "Green potatoes contain solanine — a natural pesticide.
   Safe to peel if just the skin is green; discard if green throughout."

3. **Boundary = the Somethings payoff.** The Somethings scale introduced the idea that a boundary
   is what makes a thing a thing. Here, the player manages that boundary directly for a real potato
   cell. It closes the loop planted five scales earlier.

---

## Session / resume

Persist: `score`, `elapsed time`, `_turgorLevel` (current turgor gauge fill), `_starchFillCount`
(glucose units packed into amyloplast), `_solanineCount` (number of solanine events triggered).
Drifting molecules are ephemeral — reseed on resume.

---

## Implementation notes

**Status: UNBUILT.** Create `lib/games/organelle/plant_envelope/plant_envelope.dart` →
class `PlantEnvelopeGame extends StatefulWidget` implementing `MiniGame`. Register on
`BioScale.organelle` in `lib/games/mini_game_registry.dart`.

**Canvas-only. No raster assets.**

**Amyloplast note:** `organelle_entities.dart` does not yet include an Amyloplast `BioEntity`.
The other agent on this scale has flagged this as a TODO in EDUCATION.md. When the entity is
added, link this game to it in EDUCATION.md. In the meantime, the game can reference the
amyloplast concept without a data-layer entity — the educational content lives in the WOW flare
text and the amyloplast label on canvas.

**Solanine tie to molecular scale:** solanine (`molecular_solanine`) is defined at the molecular
scale. Cross-reference it in the WOW flare text but do NOT import or depend on molecular scale
data files directly. The connection is narrative, not a code dependency.
