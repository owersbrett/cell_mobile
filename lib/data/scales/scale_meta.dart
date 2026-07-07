import 'package:flutter/material.dart';

import 'package:cell_mobile/models/bio_entity.dart';

/// SSOT for the 22 LEARN-path scales — the cinematic zoom from nothing to
/// infinity. Every LEARN surface (carousel, index sheet, explorer, indicator)
/// reads this one list so all 22 scales render identically and no downstream
/// screen can fall back to a blank chip.
///
/// Colours and icons are the exact values that shipped in the carousel — they
/// are lifted here verbatim so nothing regresses. The three education-forward
/// fields ([magnitude], [comparison], [learn]) make the awe of ~40 orders of
/// magnitude legible and give the browser a "what you'll learn" promise, which
/// is otherwise invisible in the LEARN path.
@immutable
class ScaleMeta {
  /// The scale this metadata describes.
  final BioScale scale;

  /// Short display name (e.g. "Atoms"). The journey label, nothing→infinity.
  final String label;

  /// One-line flavour under the label (e.g. "The elements of everything").
  final String subtitle;

  /// The scale's signature colour — tints cards, chips, backgrounds.
  final Color color;

  /// The scale's icon.
  final IconData icon;

  /// Order-of-magnitude readout (e.g. '10⁻¹⁰ m', '∞', '—'). The awe field.
  final String magnitude;

  /// A human-scale comparison line (e.g. 'a million across a grain of salt').
  final String comparison;

  /// The one-line teaching promise — what you'll learn at this scale.
  final String learn;

  /// True for the organelle scale, which owns the interactive cell preview.
  final bool hasInteractive;

  const ScaleMeta({
    required this.scale,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.magnitude,
    required this.comparison,
    required this.learn,
    this.hasInteractive = false,
  });
}

/// The 22 scales in journey order: nothing → cell → infinity. This ordering is
/// the "you are here" ladder; index 0 is Nothing, index 21 is Infinity.
const List<ScaleMeta> kScaleJourney = <ScaleMeta>[
  // ── Left side — from nothingness toward the cell ──
  ScaleMeta(
    scale: BioScale.nothings,
    label: 'Nothing',
    subtitle: 'Before the first distinction',
    color: Color(0xFF565062),
    icon: Icons.circle_outlined,
    magnitude: '—',
    comparison: 'the blank page before the first mark',
    learn: 'Why "nothing" is a chosen void, not an absence',
  ),
  ScaleMeta(
    scale: BioScale.somethings,
    label: 'Something',
    subtitle: 'The first distinctions',
    color: Color(0xFF7E57C2),
    icon: Icons.auto_awesome,
    magnitude: '0d → 3d',
    comparison: 'a point becoming a line becoming a shape',
    learn: 'How the first distinctions bootstrap geometry',
  ),
  ScaleMeta(
    scale: BioScale.particles,
    label: 'Particles',
    subtitle: 'Quarks, electrons & photons',
    color: Color(0xFFAB47BC),
    icon: Icons.grain,
    magnitude: '10⁻¹⁸ m',
    comparison: 'a quark to an atom is a marble to a stadium',
    learn: 'The particles everything else is built from',
  ),
  ScaleMeta(
    scale: BioScale.atoms,
    label: 'Atoms',
    subtitle: 'The elements of everything',
    color: Color(0xFF5C6BC0),
    icon: Icons.blur_on,
    magnitude: '10⁻¹⁰ m',
    comparison: 'a million lined up across a grain of salt',
    learn: 'How elements assemble into the periodic table',
  ),
  ScaleMeta(
    scale: BioScale.molecular,
    label: 'Molecules',
    subtitle: 'The chemistry of life',
    color: Color(0xFF00BCD4),
    icon: Icons.science,
    magnitude: '10⁻⁹ m',
    comparison: 'a strand of DNA is 2 nm across',
    learn: 'The chemistry that makes a cell run',
  ),
  ScaleMeta(
    scale: BioScale.organelle,
    label: 'Organelles',
    subtitle: 'Subcellular structures',
    color: Color(0xFF9C27B0),
    icon: Icons.blur_circular,
    magnitude: '10⁻⁶ m',
    comparison: 'a mitochondrion the width of this letter i',
    learn: 'The tiny machines that keep a cell alive',
    hasInteractive: true,
  ),
  // ── Center — the cell ──
  ScaleMeta(
    scale: BioScale.cell,
    label: 'Cells',
    subtitle: 'Specialized plant cells',
    color: Color(0xFF009688),
    icon: Icons.grid_view,
    magnitude: '10⁻⁵ m',
    comparison: 'a plant cell across the width of a hair',
    learn: 'How one specialized cell does the work of life',
  ),
  // ── Right side — from the cell toward infinity ──
  ScaleMeta(
    scale: BioScale.tissue,
    label: 'Tissues',
    subtitle: 'Organized cell groups',
    color: Color(0xFF4CAF50),
    icon: Icons.layers,
    magnitude: '10⁻⁴ m',
    comparison: 'a leaf-vein bundle at the edge of sight',
    learn: 'How cells organize into working tissue',
  ),
  ScaleMeta(
    scale: BioScale.organ,
    label: 'Organs',
    subtitle: 'Roots, stems, leaves & flowers',
    color: Color(0xFFCDDC39),
    icon: Icons.eco,
    magnitude: '10⁻² m',
    comparison: 'a leaf, a root, a flower in your hand',
    learn: 'The organs a plant feeds and reproduces with',
  ),
  ScaleMeta(
    scale: BioScale.organSystem,
    label: 'Organ Systems',
    subtitle: 'Integrated functional units',
    color: Color(0xFF8BC34A),
    icon: Icons.account_tree,
    magnitude: '10⁻¹ m',
    comparison: 'the whole root-to-shoot plumbing',
    learn: 'How organs cooperate as integrated systems',
  ),
  ScaleMeta(
    scale: BioScale.organism,
    label: 'Organisms',
    subtitle: 'Whole plants & life strategies',
    color: Color(0xFFFFC107),
    icon: Icons.local_florist,
    magnitude: '10⁰ m',
    comparison: 'a potato plant, root to flower',
    learn: 'What makes a whole plant a living strategy',
  ),
  ScaleMeta(
    scale: BioScale.ecosystem,
    label: 'Ecosystems',
    subtitle: 'Living systems & nutrient cycles',
    color: Color(0xFFFF9800),
    icon: Icons.forest,
    magnitude: '10² m',
    comparison: 'a field of interlocking lives',
    learn: 'How living things cycle nutrients together',
  ),
  ScaleMeta(
    scale: BioScale.farmSystem,
    label: 'Farm Systems',
    subtitle: 'Field-scale management',
    color: Color(0xFF8D6E63),
    icon: Icons.agriculture,
    magnitude: '10³ m',
    comparison: 'a managed field seen from the gate',
    learn: 'How humans steer whole systems to grow food',
  ),
  ScaleMeta(
    scale: BioScale.supplyChain,
    label: 'Supply Chains',
    subtitle: 'Harvest to table',
    color: Color(0xFF78909C),
    icon: Icons.local_shipping,
    magnitude: '10⁵ m',
    comparison: 'harvest to table across a country',
    learn: 'The journey from field to your plate',
  ),
  ScaleMeta(
    scale: BioScale.financial,
    label: 'Financials',
    subtitle: 'Markets & economics',
    color: Color(0xFFE19816),
    icon: Icons.trending_up,
    magnitude: '10⁶ m',
    comparison: 'markets spanning continents',
    learn: 'How value and prices move the food system',
  ),
  ScaleMeta(
    scale: BioScale.planets,
    label: 'Planets',
    subtitle: 'Worlds & their systems',
    color: Color(0xFF1E88E5),
    icon: Icons.language,
    magnitude: '10⁷ m',
    comparison: 'Earth is 12,700 km across',
    learn: 'Worlds and the forces that shape them',
  ),
  ScaleMeta(
    scale: BioScale.solarSystems,
    label: 'Solar Systems',
    subtitle: 'Stars & their orbits',
    color: Color(0xFFFDD835),
    icon: Icons.wb_sunny,
    magnitude: '10¹² m',
    comparison: 'light takes 8 minutes from the Sun',
    learn: 'Stars and the orbits they command',
  ),
  ScaleMeta(
    scale: BioScale.galactic,
    label: 'Galactic',
    subtitle: 'Billions of stars',
    color: Color(0xFFCE93D8),
    icon: Icons.auto_awesome,
    magnitude: '10²¹ m',
    comparison: 'a galaxy is 100,000 light-years wide',
    learn: 'Billions of stars bound into one wheel',
  ),
  ScaleMeta(
    scale: BioScale.cosmicStructures,
    label: 'Cosmic Structures',
    subtitle: 'The cosmic web',
    color: Color(0xFF80DEEA),
    icon: Icons.hub,
    magnitude: '10²⁴ m',
    comparison: 'the cosmic web strung across the void',
    learn: 'The largest structures that exist',
  ),
  ScaleMeta(
    scale: BioScale.multiverseAll,
    label: 'Multiverse',
    subtitle: 'The mesh of all realities',
    color: Color(0xFFB0BEC5),
    icon: Icons.device_hub,
    magnitude: '—',
    comparison: 'every reality that could be',
    learn: 'The mesh of all possible universes',
  ),
  ScaleMeta(
    scale: BioScale.universeAll,
    label: 'Universe',
    subtitle: 'The totality of existence',
    color: Color(0xFFEEEEEE),
    icon: Icons.all_inclusive,
    magnitude: '10²⁷ m',
    comparison: 'the observable edge, 93 billion ly wide',
    learn: 'The totality of everything we can observe',
  ),
  ScaleMeta(
    scale: BioScale.infinities,
    label: 'Infinity',
    subtitle: 'Beyond all bounds',
    color: Color(0xFFFFFFFF),
    icon: Icons.all_inclusive,
    magnitude: '∞',
    comparison: 'no edge, no end, no scale',
    learn: 'What lies beyond every bound',
  ),
];

/// Total number of scales in the journey (22).
int get kScaleCount => kScaleJourney.length;

final Map<BioScale, ScaleMeta> _byScale = {
  for (final m in kScaleJourney) m.scale: m,
};

/// The metadata for [scale]. Falls back to the Cell scale's meta (never null,
/// never a blank chip) if an unknown scale is ever passed.
ScaleMeta scaleMetaFor(BioScale scale) =>
    _byScale[scale] ??
    _byScale[BioScale.cell] ??
    kScaleJourney[kScaleJourney.length ~/ 2];

/// The 0-based position of [scale] in the nothing→infinity journey, or -1 if
/// the scale is not in the journey. For the "SCALE n / 22" readout, add 1.
int scaleJourneyIndex(BioScale scale) =>
    kScaleJourney.indexWhere((m) => m.scale == scale);
