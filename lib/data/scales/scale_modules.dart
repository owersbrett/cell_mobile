import 'package:flutter/material.dart';

import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/learn_module.dart';

/// SSOT for the **explicit** LEARN modules — the topic and potato modules that
/// sit between and after each scale's auto-generated Introductory module.
///
/// You do NOT list Introductory modules here. Every scale gets one for free
/// (see [BioEntityRegistry.modulesForScale]); any entity with a null `moduleId`
/// belongs to it. This list holds only the breadth modules authored on top.
///
/// ── How to add a module (the per-scale content pipeline) ────────────────────
///  1. Append a [LearnModule] here with a scale-namespaced id
///     (`'<scale>_<slug>'`) and its [ModuleKind] (topic or potato).
///  2. Author the module's entities in that scale's `*_entities.dart` file,
///     each carrying `moduleId: '<that id>'`.
///  3. The picker and explorer pick it up automatically — Introductory first,
///     topic modules in listed order, Potato last.
///
/// Ordering within a scale is: intro → topics (in this list's order) → potato.
///
/// Authoring bar (Brett): each module is a TEACHING TOOL a real teacher could
/// use — a hook up front, think-then-reveal + tables + landmark facts, and
/// narrative pull that compels the learner onward. Never word-vomit.
const List<LearnModule> kExtraModules = <LearnModule>[
  // ── Farm System — existing 5 (soil practices) are the intro; add methods,
  // the modern farm, and growing potatoes.
  LearnModule(
    id: 'farmSystem_methods',
    scale: BioScale.farmSystem,
    title: 'Farming Methods',
    subtitle: 'Conventional to regenerative to vertical',
    icon: Icons.agriculture,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'farmSystem_modern',
    scale: BioScale.farmSystem,
    title: 'The Modern Farm',
    subtitle: 'Machines, livestock, pests, and precision',
    icon: Icons.precision_manufacturing,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'farmSystem_potato',
    scale: BioScale.farmSystem,
    title: 'Growing Potatoes',
    subtitle: 'Seed, hill, guard against blight, harvest, store',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Supply Chain — existing 5 (downstream) are the intro; add the FULL chain
  // (incl. procurement, which Brett flagged as missing), the ops, and the potato.
  LearnModule(
    id: 'supplyChain_full',
    scale: BioScale.supplyChain,
    title: 'The Full Supply Chain',
    subtitle: 'Procurement to last mile — every link',
    icon: Icons.conveyor_belt,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'supplyChain_ops',
    scale: BioScale.supplyChain,
    title: 'Making Supply Chains Work',
    subtitle: 'Forecasting, the bullwhip, cold chain, resilience',
    icon: Icons.insights,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'supplyChain_potato',
    scale: BioScale.supplyChain,
    title: 'A Potato\'s Journey',
    subtitle: 'Seed to fry — the tuber\'s supply chain',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Organelle — the existing 22 are animal-cell-focused; add the plant-cell
  // organelles they lack, and the potato-cell potato lens.
  LearnModule(
    id: 'organelle_plant',
    scale: BioScale.organelle,
    title: 'Plant-Specific Organelles',
    subtitle: 'Chloroplasts, plastids, cell wall, and the big vacuole',
    icon: Icons.eco,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'organelle_potato',
    scale: BioScale.organelle,
    title: 'The Potato Cell\'s Organelles',
    subtitle: 'Inside a storage cell — the amyloplast is the star',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Nothings — the physics + philosophy of nothing, and the void in a potato.
  LearnModule(
    id: 'nothings_nature',
    scale: BioScale.nothings,
    title: 'The Nature of Nothing',
    subtitle: 'The vacuum, zero, and why there is anything at all',
    icon: Icons.circle_outlined,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'nothings_potato',
    scale: BioScale.nothings,
    title: 'The Nothing in a Potato',
    subtitle: 'A tuber is almost entirely empty space',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Somethings — the first distinction, information, existence, + the potato.
  LearnModule(
    id: 'somethings_rise',
    scale: BioScale.somethings,
    title: 'The Rise of Something',
    subtitle: 'Distinction, information, and the first bit',
    icon: Icons.blur_on,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'somethings_potato',
    scale: BioScale.somethings,
    title: 'A Potato Is Something',
    subtitle: 'The humblest example of existence',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Organ — existing 6 (plant organs) are the intro; add human organs + potato.
  LearnModule(
    id: 'organ_human',
    scale: BioScale.organ,
    title: 'The Human Organs',
    subtitle: 'Heart, brain, liver — the body\'s specialized parts',
    icon: Icons.favorite,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'organ_potato',
    scale: BioScale.organ,
    title: 'The Potato\'s Organs',
    subtitle: 'The tuber, and the plant parts that built it',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Financial — existing 4 (ag-economics) are the intro; add money/markets,
  // the wider economy, and the potato economy.
  LearnModule(
    id: 'financial_money',
    scale: BioScale.financial,
    title: 'Money & Markets',
    subtitle: 'What money is, and how prices happen',
    icon: Icons.payments,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'financial_economy',
    scale: BioScale.financial,
    title: 'The Bigger Economy',
    subtitle: 'GDP, trade, booms, busts, and central banks',
    icon: Icons.trending_up,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'financial_potato',
    scale: BioScale.financial,
    title: 'The Potato Economy',
    subtitle: 'The price of a spud, from field to global trade',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Multiverse (All) — lean on the GREAT MINDS + philosophy of science (Brett
  // suppressed his personal conception, 2026-07-09). No personal theology.
  LearnModule(
    id: 'multiverseAll_minds',
    scale: BioScale.multiverseAll,
    title: 'The Great Minds of the Multiverse',
    subtitle: 'Everett, Wheeler, Deutsch, Guth, Linde, Susskind, Tegmark',
    icon: Icons.psychology_alt,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'multiverseAll_science',
    scale: BioScale.multiverseAll,
    title: 'Is the Multiverse Science?',
    subtitle: 'Falsifiability, testability, and the honest debate',
    icon: Icons.balance,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'multiverseAll_potato',
    scale: BioScale.multiverseAll,
    title: 'Every Possible Potato',
    subtitle: 'What infinite worlds mean for one humble tuber',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Universe (All) — the whole story, its fate, and the potato that contains it.
  LearnModule(
    id: 'universeAll_story',
    scale: BioScale.universeAll,
    title: 'The Story of the Universe',
    subtitle: 'Big Bang to galaxies — 13.8 billion years',
    icon: Icons.auto_awesome,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'universeAll_fate',
    scale: BioScale.universeAll,
    title: 'The Fate of Everything',
    subtitle: 'How the universe might end',
    icon: Icons.hourglass_bottom,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'universeAll_potato',
    scale: BioScale.universeAll,
    title: 'A Potato Contains the Universe',
    subtitle: 'The whole cosmic story, in one tuber',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Cosmic Structures — the cosmic web + Brett's "patterns that recur across
  // every scale" (Fibonacci, golden ratio, fractals) + the potato phyllotaxis lens.
  LearnModule(
    id: 'cosmicStructures_web',
    scale: BioScale.cosmicStructures,
    title: 'The Cosmic Web',
    subtitle: 'Filaments, voids, and the largest things that exist',
    icon: Icons.hub,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'cosmicStructures_patterns',
    scale: BioScale.cosmicStructures,
    title: 'Patterns That Repeat',
    subtitle: 'Fibonacci, fractals, spirals — nature\'s reused blueprints',
    icon: Icons.auto_awesome,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'cosmicStructures_potato',
    scale: BioScale.cosmicStructures,
    title: 'Patterns in a Potato',
    subtitle: 'The spiral of eyes and the fractal of roots',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Galactic — was one galaxy; add a zoo of galaxies, how we study them
  // (modern techniques), and the Milky Way potato-home lens.
  LearnModule(
    id: 'galactic_zoo',
    scale: BioScale.galactic,
    title: 'A Zoo of Galaxies',
    subtitle: 'Spiral, elliptical, irregular — the island universes',
    icon: Icons.blur_on,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'galactic_how',
    scale: BioScale.galactic,
    title: 'How We Know',
    subtitle: 'Redshift, spectra, lensing — the modern astronomer\'s toolkit',
    icon: Icons.travel_explore,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'galactic_potato',
    scale: BioScale.galactic,
    title: 'Our Galactic Home',
    subtitle: 'The Milky Way, and the stardust in every potato',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Solar Systems — add the anatomy (asteroid belt, Kuiper, Oort), how they
  // form, and the Sun-and-potato lens.
  LearnModule(
    id: 'solarSystems_anatomy',
    scale: BioScale.solarSystems,
    title: 'Anatomy of the Solar System',
    subtitle: 'Sun, belts, the Kuiper Belt, and the distant Oort Cloud',
    icon: Icons.blur_circular,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'solarSystems_formation',
    scale: BioScale.solarSystems,
    title: 'How Solar Systems Form',
    subtitle: 'From a collapsing cloud to orbiting worlds',
    icon: Icons.cyclone,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'solarSystems_potato',
    scale: BioScale.solarSystems,
    title: 'The Sun & the Potato',
    subtitle: 'The star that powers every tuber',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Planets — existing 3 (Earth/Mars/Exoplanets) are the intro; add the
  // full solar system, moons/dwarfs, and the (real!) potato-shaped worlds.
  LearnModule(
    id: 'planets_eight',
    scale: BioScale.planets,
    title: 'The Eight Planets',
    subtitle: 'Mercury to Neptune — a tour of the Sun\'s worlds',
    icon: Icons.public,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'planets_moons',
    scale: BioScale.planets,
    title: 'Moons & Dwarf Planets',
    subtitle: 'The worlds that orbit worlds — and the almost-planets',
    icon: Icons.brightness_3,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'planets_potato',
    scale: BioScale.planets,
    title: 'Potato-Shaped Worlds',
    subtitle: 'Why small moons and asteroids really do look like spuds',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Ecosystem — existing 5 (companion planting) are the intro; add biomes,
  // how ecosystems work, and the farm-as-ecosystem potato lens.
  LearnModule(
    id: 'ecosystem_biomes',
    scale: BioScale.ecosystem,
    title: 'Biomes of the World',
    subtitle: 'Rainforest to tundra to coral reef',
    icon: Icons.public,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'ecosystem_how',
    scale: BioScale.ecosystem,
    title: 'How Ecosystems Work',
    subtitle: 'Food webs, energy flow, and keystones',
    icon: Icons.hub,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'ecosystem_potato',
    scale: BioScale.ecosystem,
    title: 'The Farm as an Ecosystem',
    subtitle: 'Soil life, pollinators, pests, and the monoculture trap',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Molecular — existing 12 biomolecules are the intro; add relationships,
  // breadth, and the potato lens (Brett: "more molecules + how they relate").
  LearnModule(
    id: 'molecular_bonds',
    scale: BioScale.molecular,
    title: 'How Molecules Relate',
    subtitle: 'Bonds and forces — what holds matter together',
    icon: Icons.link,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'molecular_gallery',
    scale: BioScale.molecular,
    title: 'A Gallery of Molecules',
    subtitle: 'From water to caffeine — molecules you meet daily',
    icon: Icons.science,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'molecular_potato',
    scale: BioScale.molecular,
    title: 'Molecules of a Potato',
    subtitle: 'Starch, solanine, and the chemistry of a fry',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Organ System — existing 4 (plant systems) are the intro; add human + potato.
  LearnModule(
    id: 'organSystem_human',
    scale: BioScale.organSystem,
    title: 'The Human Organ Systems',
    subtitle: 'The eleven teams that keep a body running',
    icon: Icons.favorite,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'organSystem_potato',
    scale: BioScale.organSystem,
    title: 'The Whole Potato Plant',
    subtitle: 'Root, shoot, vascular, and the tuber as a storehouse',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Tissue — the existing 4 (plant tissues) are the intro; add animal + potato.
  LearnModule(
    id: 'tissue_animal',
    scale: BioScale.tissue,
    title: 'Animal Tissues',
    subtitle: 'The four families: epithelial, connective, muscle, nervous',
    icon: Icons.grid_view,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'tissue_potato',
    scale: BioScale.tissue,
    title: 'Tissues of a Potato',
    subtitle: 'Skin, cortex, vascular ring, and the starchy storehouse',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Organism — the tree of life, the human, the potato ───────────────────
  // Existing seed entities (Corn, Soybean, Wheat, Tomato, Legume, Rice) form
  // the auto Introductory module (staple crops). Breadth added on top.
  LearnModule(
    id: 'organism_kingdoms',
    scale: BioScale.organism,
    title: 'The Kingdoms of Life',
    subtitle: 'Bacteria to beasts — the branches of the living',
    icon: Icons.account_tree,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'organism_human',
    scale: BioScale.organism,
    title: 'The Human',
    subtitle: 'Homo sapiens as an organism',
    icon: Icons.accessibility_new,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'organism_potato',
    scale: BioScale.organism,
    title: 'The Potato',
    subtitle: 'Solanum tuberosum, from Andes to everywhere',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Cell — the diversity, the nervous system, the life cycle ─────────────
  LearnModule(
    id: 'cell_types',
    scale: BioScale.cell,
    title: 'A Tour of Cell Types',
    subtitle: 'The astonishing variety of cells',
    icon: Icons.grain,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'cell_neurobiology',
    scale: BioScale.cell,
    title: 'Neurobiology',
    subtitle: 'The cells that think',
    icon: Icons.psychology,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'cell_life',
    scale: BioScale.cell,
    title: 'The Life of a Cell',
    subtitle: 'Membrane, division, signaling, and death',
    icon: Icons.autorenew,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'cell_potato',
    scale: BioScale.cell,
    title: 'Cells of a Potato',
    subtitle: 'Inside the plant cell and the tuber',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Particles — the Standard Model and its frontier ──────────────────────
  LearnModule(
    id: 'particles_standard_model',
    scale: BioScale.particles,
    title: 'The Standard Model',
    subtitle: 'The 17 fundamental particles of reality',
    icon: Icons.scatter_plot,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'particles_forces',
    scale: BioScale.particles,
    title: 'Forces & Composite Particles',
    subtitle: 'The four forces, and what quarks build',
    icon: Icons.hub,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'particles_beyond',
    scale: BioScale.particles,
    title: 'Beyond the Standard Model',
    subtitle: 'Antimatter, dark matter, and the frontier',
    icon: Icons.blur_on,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'particles_potato',
    scale: BioScale.particles,
    title: 'Particles of a Potato',
    subtitle: 'The subatomic census of a tuber',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Atoms — the full elemental census ────────────────────────────────────
  // Existing seed entities (H, C, N, O, elements of life) form the auto intro.
  LearnModule(
    id: 'atoms_periodic_table',
    scale: BioScale.atoms,
    title: 'The Periodic Table',
    subtitle: 'All 118 elements, hydrogen to oganesson',
    icon: Icons.grid_on,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'atoms_potato',
    scale: BioScale.atoms,
    title: 'Atoms of a Potato',
    subtitle: 'The elemental recipe of a tuber',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),

  // ── Infinity — explored through mathematics ──────────────────────────────
  // The existing entities form the auto-generated "Introduction" (The Idea of
  // Infinity: Cantor, infinitesimals, philosophical ∞). These build the
  // calculus + linear-algebra curriculum on top, ending in the potato lens.
  LearnModule(
    id: 'infinities_calc1',
    scale: BioScale.infinities,
    title: 'Calculus I — Limits & Derivatives',
    subtitle: 'The infinitely small, made rigorous',
    icon: Icons.trending_up,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'infinities_calc2',
    scale: BioScale.infinities,
    title: 'Calculus II — Integration & Series',
    subtitle: 'Summing infinitely many pieces',
    icon: Icons.area_chart,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'infinities_calc3',
    scale: BioScale.infinities,
    title: 'Calculus III — Multivariable',
    subtitle: 'Calculus in many dimensions',
    icon: Icons.threed_rotation,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'infinities_linear_algebra',
    scale: BioScale.infinities,
    title: 'Linear Algebra',
    subtitle: 'Vectors, matrices, and infinite-dimensional space',
    icon: Icons.grid_4x4,
    kind: ModuleKind.topic,
  ),
  LearnModule(
    id: 'infinities_potato',
    scale: BioScale.infinities,
    title: 'Infinity in a Potato',
    subtitle: 'Calculus, applied to a tuber',
    icon: Icons.spa,
    kind: ModuleKind.potato,
  ),
];

/// Guard: every id must be unique and namespaced by its scale. Kept as a
/// runtime assertion so a mis-typed id fails loudly in debug, not silently.
bool debugValidateModules() {
  final ids = <String>{};
  for (final m in kExtraModules) {
    assert(ids.add(m.id), 'Duplicate module id: ${m.id}');
    assert(m.id.startsWith(m.scale.name),
        'Module id ${m.id} must start with its scale name ${m.scale.name}');
  }
  // Reference BioScale so the import is always used even if the list empties.
  assert(BioScale.values.isNotEmpty);
  assert(Icons.spa.codePoint != 0);
  return true;
}
