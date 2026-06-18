/// Fun-fact flare data for molecules that appear in Molecule Mixer.
///
/// Keyed by formula string — matches the [formula] field on [_MoleculeDef]
/// in molecule_mixer.dart exactly ('H₂O', 'O₂', 'CO₂', 'CH₄', 'NH₃',
/// 'N₂', 'H₂O₂', 'HCl').
///
/// Each entry records:
///   [formula]    — formula string used as the lookup key
///   [name]       — display name shown in the card header
///   [whatItIs]   — one-line description of the molecule
///   [potatoFact] — one-line fact about its role in (or relevance to) a potato
///
/// Source: lib/games/molecular/MOLECULE_LOCATIONS.md (top table, game molecules).
/// Tone: plain, specific, no exclamation marks.

class MoleculeFact {
  final String formula;
  final String name;
  final String whatItIs;
  final String potatoFact;

  const MoleculeFact({
    required this.formula,
    required this.name,
    required this.whatItIs,
    required this.potatoFact,
  });
}

const List<MoleculeFact> kMoleculeFacts = [
  MoleculeFact(
    formula: 'H₂O',
    name: 'Water',
    whatItIs: 'The polar molecule that dissolves everything',
    potatoFact:
        'The cytoplasm, vacuole, and every cell in the potato is mostly water — it is the medium all potato chemistry happens in',
  ),
  MoleculeFact(
    formula: 'O₂',
    name: 'Oxygen',
    whatItIs: 'The gas released by photosynthesis; consumed by respiration',
    potatoFact:
        "The potato's mitochondria burn O₂ to convert glucose into ATP — the energy that builds every other molecule on this scale",
  ),
  MoleculeFact(
    formula: 'CO₂',
    name: 'Carbon dioxide',
    whatItIs: 'The carbon source for all photosynthesis',
    potatoFact:
        "CO₂ enters through the potato plant's leaf stomata and is stitched into glucose by RuBisCO — the first step toward every starch granule in the tuber",
  ),
  MoleculeFact(
    formula: 'CH₄',
    name: 'Methane',
    whatItIs: 'Simplest organic molecule — one carbon, four hydrogens',
    potatoFact:
        "Not found in potatoes, but its C–H bonds appear in every fatty acid, amino acid, and glucose unit in the plant",
  ),
  MoleculeFact(
    formula: 'NH₃',
    name: 'Ammonia',
    whatItIs: 'The nitrogen molecule soil bacteria convert into plant-usable form',
    potatoFact:
        'Nitrification bacteria in potato soil convert NH₃ into nitrate, which the potato roots absorb to build proteins and nucleic acids',
  ),
  MoleculeFact(
    formula: 'N₂',
    name: 'Nitrogen',
    whatItIs: '78% of the air, mostly locked away from life',
    potatoFact:
        "N₂'s triple bond is nearly unbreakable — only nitrogen-fixing bacteria in the field soil can crack it open and hand the nitrogen to potato roots",
  ),
  MoleculeFact(
    formula: 'H₂O₂',
    name: 'Hydrogen peroxide',
    whatItIs: 'A reactive oxygen species the plant must detoxify',
    potatoFact:
        'Potato cells produce H₂O₂ as a signaling molecule during stress and pathogen attack — it triggers the defense cascade that can ramp up solanine production',
  ),
  MoleculeFact(
    formula: 'HCl',
    name: 'Hydrochloric acid',
    whatItIs: 'A strong acid that does not appear in plant biology',
    potatoFact:
        "Not produced by potatoes, but its dissociation into H⁺ and Cl⁻ illustrates the proton-transfer chemistry that drives pH regulation in the potato cell's vacuole",
  ),
];

/// Lookup by formula string. Returns null if no fact entry exists for [formula].
MoleculeFact? factForFormula(String formula) {
  for (final f in kMoleculeFacts) {
    if (f.formula == formula) return f;
  }
  return null;
}
