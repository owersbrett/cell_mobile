/// Cosmic provenance data for elements that appear in Atom Builder.
///
/// Keyed by atomic number (Z). Each entry records:
///   [symbol]     — element symbol (matches _kElements in atom_builder.dart)
///   [name]       — full element name
///   [forgedIn]   — scientifically accurate origin (Big Bang / stellar / supernova)
///   [potatoRole] — concrete role in a potato; null where no direct role exists
///
/// Coverage includes every noble-gas checkpoint (Z=2,10,18,36,54),
/// the five education-block elements (H,C,N,O,P), the fertilizer-bonus
/// elements (S, K), and a handful of intermediaries so the flare fires at
/// natural waypoints across the whole ladder.
///
/// Source accuracy:
///   H, He    → Big Bang nucleosynthesis (first 3 min / 380 kyr recombination)
///   Li        → Big Bang + cosmic ray spallation
///   C, N, O  → stellar nucleosynthesis (CNO cycle, triple-alpha, helium shell burning)
///   Ne, Na, Mg, Al, Si → silicon/neon burning in massive stars
///   P, S, Cl → supernova nucleosynthesis (s/r-process in massive stars)
///   Ar, K, Ca → supernova ejecta / s-process
///   (Z 21-35 intermediaries) → stellar/supernova s-process
///   Kr, Xe   → s- and r-process (supernova + neutron-star merger)

class AtomProvenance {
  final int z;
  final String symbol;
  final String name;
  final String forgedIn;
  final String? potatoRole;

  const AtomProvenance({
    required this.z,
    required this.symbol,
    required this.name,
    required this.forgedIn,
    this.potatoRole,
  });
}

/// Provenance table. Only elements with a notable teaching moment are listed.
/// The flare fires the first time the player's proton count reaches each Z.
const List<AtomProvenance> kAtomProvenances = [
  AtomProvenance(
    z: 1,
    symbol: 'H',
    name: 'Hydrogen',
    forgedIn: 'Big Bang — 380,000 years after the start of everything',
    potatoRole: 'Water, every organic molecule, the star-fuel that grew your potato',
  ),
  AtomProvenance(
    z: 2,
    symbol: 'He',
    name: 'Helium',
    forgedIn: 'Big Bang + the core of every star ever born',
    potatoRole: null,
  ),
  AtomProvenance(
    z: 3,
    symbol: 'Li',
    name: 'Lithium',
    forgedIn: 'Big Bang trace + cosmic rays shattering heavier nuclei in space',
    potatoRole: null,
  ),
  AtomProvenance(
    z: 6,
    symbol: 'C',
    name: 'Carbon',
    forgedIn: 'Red giant cores — three helium nuclei fused (triple-alpha process)',
    potatoRole: 'Backbone of glucose, starch, cellulose, and DNA',
  ),
  AtomProvenance(
    z: 7,
    symbol: 'N',
    name: 'Nitrogen',
    forgedIn: 'Stellar cores via the CNO cycle; scattered by supernova explosions',
    potatoRole: 'Amino acids, chlorophyll, DNA — the N in N-P-K fertilizer',
  ),
  AtomProvenance(
    z: 8,
    symbol: 'O',
    name: 'Oxygen',
    forgedIn: 'Massive stellar cores fusing helium and carbon',
    potatoRole: 'Water (H₂O), respiration, soil oxidation chemistry',
  ),
  AtomProvenance(
    z: 10,
    symbol: 'Ne',
    name: 'Neon',
    forgedIn: 'Carbon-burning shells inside massive pre-supernova stars',
    potatoRole: null,
  ),
  AtomProvenance(
    z: 11,
    symbol: 'Na',
    name: 'Sodium',
    forgedIn: 'Neon-burning shells in massive stars, released by supernova',
    potatoRole: 'Ion balance in plant cells; minor soil nutrient',
  ),
  AtomProvenance(
    z: 12,
    symbol: 'Mg',
    name: 'Magnesium',
    forgedIn: 'Carbon and neon burning in stellar interiors',
    potatoRole: 'Core of every chlorophyll molecule in a potato leaf',
  ),
  AtomProvenance(
    z: 13,
    symbol: 'Al',
    name: 'Aluminium',
    forgedIn: 'Carbon burning in the shells of massive pre-supernova stars',
    potatoRole: null,
  ),
  AtomProvenance(
    z: 14,
    symbol: 'Si',
    name: 'Silicon',
    forgedIn: 'Oxygen and silicon burning in the final hours of a massive star',
    potatoRole: 'Soil mineral; structural in some plant cell walls',
  ),
  AtomProvenance(
    z: 15,
    symbol: 'P',
    name: 'Phosphorus',
    forgedIn: 'Supernova nucleosynthesis (s- and r-process in massive stars)',
    potatoRole: 'ATP energy bonds, DNA backbone — the P in N-P-K fertilizer',
  ),
  AtomProvenance(
    z: 16,
    symbol: 'S',
    name: 'Sulfur',
    forgedIn: 'Oxygen burning in pre-supernova stars; scattered by the blast',
    potatoRole: 'Protein structure (cysteine, methionine) — the S in N-P-S-K',
  ),
  AtomProvenance(
    z: 18,
    symbol: 'Ar',
    name: 'Argon',
    forgedIn: 'Supernova ejecta from silicon-burning stellar cores',
    potatoRole: null,
  ),
  AtomProvenance(
    z: 19,
    symbol: 'K',
    name: 'Potassium',
    forgedIn: 'Supernova nucleosynthesis; abundant in the crust of rocky planets',
    potatoRole: 'Ion pumps, starch quality, crop yield — the K in N-P-K',
  ),
  AtomProvenance(
    z: 20,
    symbol: 'Ca',
    name: 'Calcium',
    forgedIn: 'Silicon burning and supernova ejecta in massive stars',
    potatoRole: 'Cell wall strength; enzyme activation in root growth',
  ),
  AtomProvenance(
    z: 26,
    symbol: 'Fe',
    name: 'Iron',
    forgedIn: 'The end of stellar fusion — iron is where stars run out of energy',
    potatoRole: 'Enzyme cofactor; iron deficiency yellows potato leaves',
  ),
  AtomProvenance(
    z: 36,
    symbol: 'Kr',
    name: 'Krypton',
    forgedIn: 'S-process neutron capture inside AGB stars; r-process in supernovae',
    potatoRole: null,
  ),
  AtomProvenance(
    z: 54,
    symbol: 'Xe',
    name: 'Xenon',
    forgedIn: 'S- and r-process neutron capture — some forged in neutron-star mergers',
    potatoRole: null,
  ),
];

/// Lookup by atomic number. Returns null if no provenance entry exists for [z].
AtomProvenance? provenanceForZ(int z) {
  for (final p in kAtomProvenances) {
    if (p.z == z) return p;
  }
  return null;
}
