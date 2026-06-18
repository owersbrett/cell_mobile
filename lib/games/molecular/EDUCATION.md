# EDUCATION.md — Molecular (cell)

> The educational blocks that occupy the Molecular scale, and which game(s) engage each.
> Source data: `lib/data/scales/molecular_entities.dart` (12 blocks).
> **The learning arc:** atoms → named elements forged in stars; **molecular → those elements bond
> into molecules, and those molecules ARE the potato.** This is the scale where the cosmic chain
> (stars → atoms → molecules → potato) lands on something you can eat.

- **Scale (cell):** molecular
- **Games on this scale:** `molecule_mixer` (canonical, strong edu tie),
  `molecule_builder` (game-2, order-fulfillment drag mechanic)

---

## Blocks

### Potato Headliners — the molecules that exist nowhere else in this app

These five blocks are the stars of the Molecular scale. They are unique to potatoes (or closely
potato-specific), and the WOW flare layer ("where in the potato does this live?") is designed
specifically around them. The games are the vehicle; these are the payoff.

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Starch (Amylose) | The Linear Chain | Unbranched glucose chains; determines fluffy/waxy texture. | `molecule_mixer` ⚠️ indirect (glucose/H₂O present) · `molecule_builder` ❌ not in recipe set | ⚠️ |
| Starch (Amylopectin) | The Branched Matrix | Dominant branched starch; governs gelatinization. | `molecule_mixer` ⚠️ indirect · `molecule_builder` ❌ not in recipe set | ⚠️ |
| Solanine | The Chemical Defender | Toxic glycoalkaloid in green/sprouted skin; plant defense. | `molecule_mixer` ❌ · `molecule_builder` ❌ | ❌ |
| Vitamin C | The Antioxidant Shield | Ascorbic acid; why potatoes historically prevented scurvy. | `molecule_mixer` ❌ · `molecule_builder` ❌ | ❌ |
| ATP | The Energy Currency | Adenosine triphosphate; universal cellular energy molecule. | `molecule_mixer` ❌ · `molecule_builder` ❌ | ❌ |

### Supporting Cast — major biomolecule classes

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Water | The Universal Solvent | H₂O — polar molecule that dissolves everything and makes life possible. | `molecule_mixer` ✅ (H₂O is target molecule) · `molecule_builder` ✅ (H₂O in recipe set) | ✅ |
| Carbohydrates | The Energy & Structure Dual | Sugars, starches, cellulose — fuel and structural backbone. | `molecule_mixer` ⚠️ (glucose components; CH₄ is a carbon + H molecule) · `molecule_builder` ⚠️ | ⚠️ |
| Carbon | The Backbone of Life | Element 6; four bonds → scaffold of every biological molecule. | `molecule_mixer` ✅ (C appears in CO₂, CH₄ — carbon's bonding nature is the mechanic) · `molecule_builder` ✅ (CO₂, CH₄ in recipe set) | ✅ |
| Nucleic Acids | The Information Carriers | DNA and RNA — polymers that store and execute genetic instructions. | `molecule_mixer` ❌ · `molecule_builder` ❌ | ❌ |
| Proteins | The Molecular Machines | Amino acid chains folded into 3D machines; enzymes, transporters, structure. | `molecule_mixer` ❌ · `molecule_builder` ❌ | ❌ |
| Lipids | The Barrier Builders | Fats, oils, phospholipids — membranes and energy storage. | `molecule_mixer` ❌ · `molecule_builder` ❌ | ❌ |
| Air Content | The Atmospheric Exchange | N₂ (78%), O₂ (21%), CO₂ (0.04%) — the gases plants breathe. | `molecule_mixer` ✅ (O₂, CO₂, N₂ are all target molecules) · `molecule_builder` ✅ (CO₂, NH₃ in recipe set) | ✅ |

---

## Strength notes

**Water ✅** — H₂O is the first molecule in Molecule Mixer's target list and in Molecule Builder's
recipe set. The game literally has you assemble the universal solvent: two Hs bonded to one O,
backbone (O) first. Real bonding structure, real formula.

**Carbon ✅ (as bridge block)** — Carbon appears in CO₂, CH₄, and C₂H₆ across both games.
Its four-bonding behavior is implicit in the game mechanics: CO₂ needs carbon at the backbone with
oxygens on both sides; CH₄ needs carbon at the center with four hydrogens around it. The "CORE"
badge in Molecule Mixer fires on carbon for both of these, making the concept tangible. **This is
the intentional atoms→molecules bridge**: the same carbon that was a waypoint in Atom Builder
(Z=6, passed on the way to Neon) here becomes the central atom in every organic target. Frame it
explicitly: "The carbon forged in red giant stars is now bonding to make the molecules of your potato."

**Air Content ✅** — Three of the four gases in the atmosphere block (N₂, O₂, CO₂) are playable
target molecules in Molecule Mixer and appear as recipe molecules in Molecule Builder. The student
who builds CO₂ and N₂ in both games is directly handling the atmospheric chemistry block.

**Starch (Amylose/Amylopectin) ⚠️** — Neither game builds starch directly (amylose and
amylopectin are glucose polymers far too large to represent as a molecule-assembly game). However,
glucose's components (C, H, O) are the atoms used in both games, and the WOW flare layer fills the
gap: when the player completes H₂O or CO₂ in Molecule Mixer, the potato-location card can note that
"these are the inputs that a potato's amyloplast assembles into starch." The connection is real;
the engagement is indirect.

**Solanine, Vitamin C, Nucleic Acids, Proteins, Lipids, ATP ❌** — No game currently touches these
blocks. They are real molecular biology, but their complexity (large polymers, multi-stage
synthesis, no simple 2–5-atom formula) makes them difficult to represent in the current tap/drag
mechanics. The WOW flare is the primary educational vehicle for these blocks — especially for the
potato headliners.

---

## The WOW layer — "where in the potato does this live?" flare

Analogous to the Atoms scale's cosmic provenance cards (element → forged in stars → potato role),
the Molecular scale surfaces a brief, **non-scoring, dismissible** flare when the player completes
a molecule in Molecule Mixer. The card fades in over ~0.6 s and shows:

```
[formula]  [name]
[one line: what it is]
[one line: where in a potato it lives]
```

The full flare data table is in `MOLECULE_LOCATIONS.md`. Design notes:
- The card should fade in near the construction zone, over the celebration banner (after the
  formula/name banner fades), not competing with it.
- It must never block input; the next molecule can start spawning behind it.
- Advance through the table in the same order each run so players can learn the sequence.

This layer is the primary way the potato headliners (Solanine, Vitamin C, ATP, Amylose,
Amylopectin) get surface time in the scale, even though no game builds them directly. When the
player completes water, they learn it's the solvent of the cytoplasm. When they complete CO₂, they
learn it's what photosynthesis consumes to build glucose for starch. When they complete O₂, they
learn the potato's mitochondria burn it to make ATP. The scale's molecules are a doorway.

---

## Association verdict

**KEEP — strong tie on Water, Carbon, and Air Content; honest gap on the potato headliners.**

The scale earns its keep because the gap is filled by design: the WOW flare layer is the explicit
mechanism for surfacing the potato molecules that the games can't directly build. This is the same
approach used at the Particles scale (the 4 education blocks are a subset of the 17-entry discovery
timeline). Here, the 12 blocks are the full scope, but the flare layer reaches all of them.

Action items:
1. Build the potato-location flare feature (see `MOLECULE_LOCATIONS.md` for the data table).
2. Make both games reachable from Explore (per-scale game picker).
3. See Decisions for Brett below for the open gaps.

---

## Potato angle

The Molecular scale is where the potato tie is not metaphorical — it is literal. Every headline
block (Amylose, Amylopectin, Solanine, Vitamin C, ATP) is a molecule that exists inside a real
potato right now. The supporting blocks (Water, Carbon, Air Content) are the inputs and scaffolding
for making those molecules.

The narrative thread from the Atoms scale continues: carbon was forged in a red giant, assembled
into element-6 atoms, and now — at this scale — those carbon atoms are bonding to hydrogen and
oxygen to form glucose, which chains into amylose and amylopectin, which pack into the amyloplasts
inside the potato cells you will see at the next scale up. The player is zooming in on a potato
and seeing what it is made of, from the inside out.

Frame the potato molecules as headliners in any UI copy, tutorial text, or game intro. The supporting
cast exists because you can't build starch without understanding what glucose is made of; you can't
understand Vitamin C without understanding ascorbic acid's carbon backbone.

---

## Decisions for Brett

1. **Solanine and Vitamin C have zero game engagement.** They are the most potato-specific blocks
   on the scale. The WOW flare is the only mechanism touching them. Is that sufficient, or should
   a third game be scoped that specifically teaches the potato's defensive and nutritional chemistry?
   (One idea: a "solanine detection" game — scan potato slices to identify green/sprout regions;
   conceptually strong, but would need a design pass.)

2. **Nucleic Acids, Proteins, Lipids** are large-polymer classes with no playable game tie and no
   WOW flare entry in the current molecule set. The scale EDUCATION.md honestly marks them ❌.
   These are curriculum-important blocks. Options: (a) accept the WOW flare + long description
   as sufficient; (b) design a game that teaches polymer structure (e.g., a protein-folding or
   DNA-assembly mechanic); (c) move them to a dedicated "Macromolecules" scale if the roster ever
   expands.

3. **ATP** is marked ❌ in games but is flagged as a potato headliner. ATP is a nucleotide-based
   molecule (adenine + ribose + 3 phosphates) — arguably buildable as a molecule-assembly game if
   the Molecule Mixer were extended with phosphate (P) and ribose (Rb) atom types. Worth
   considering for a future Molecule Mixer v2 that adds the potato-specific molecules to the build
   queue.
