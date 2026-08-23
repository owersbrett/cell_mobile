import '../../models/bio_entity.dart';

/// The category layer of the madness wheels: 22 scales decompose into 7
/// readable groups, so wheel #1 always has fat segments. Presentation only —
/// the host config and the pool stay per-scale; a category appears on the
/// wheel only while at least one of its scales still has available games.
class MadnessCategory {
  final String name;
  final List<BioScale> scales;
  const MadnessCategory(this.name, this.scales);
}

const List<MadnessCategory> kMadnessCategories = [
  MadnessCategory('ORIGINS', [BioScale.nothings, BioScale.somethings]),
  MadnessCategory(
      'MATTER', [BioScale.particles, BioScale.atoms, BioScale.molecular]),
  MadnessCategory(
      'THE CELL', [BioScale.organelle, BioScale.cell, BioScale.tissue]),
  MadnessCategory(
      'THE BODY', [BioScale.organ, BioScale.organSystem, BioScale.organism]),
  MadnessCategory('THE HARVEST', [
    BioScale.ecosystem,
    BioScale.farmSystem,
    BioScale.supplyChain,
    BioScale.financial,
  ]),
  MadnessCategory('THE COSMOS', [
    BioScale.planets,
    BioScale.solarSystems,
    BioScale.galactic,
    BioScale.cosmicStructures,
  ]),
  MadnessCategory('EVERYTHING', [
    BioScale.multiverseAll,
    BioScale.universeAll,
    BioScale.infinities,
  ]),
];

/// The category holding [scale]. Every [BioScale] is covered (asserted by
/// test); falls back to the last category so an unmapped future scale can't
/// crash a live room.
MadnessCategory madnessCategoryOf(BioScale scale) {
  for (final c in kMadnessCategories) {
    if (c.scales.contains(scale)) return c;
  }
  return kMadnessCategories.last;
}
