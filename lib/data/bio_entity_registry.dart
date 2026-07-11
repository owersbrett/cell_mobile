import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/learn_module.dart';
import 'package:cell_mobile/data/scales/scale_meta.dart';
import 'package:cell_mobile/data/scales/scale_modules.dart';
import 'package:cell_mobile/data/scales/nothings_entities.dart';
import 'package:cell_mobile/data/scales/somethings_entities.dart';
import 'package:cell_mobile/data/scales/particles_entities.dart';
import 'package:cell_mobile/data/scales/atoms_entities.dart';
import 'package:cell_mobile/data/scales/molecular_entities.dart';
import 'package:cell_mobile/data/scales/organelle_entities.dart';
import 'package:cell_mobile/data/scales/cell_entities.dart';
import 'package:cell_mobile/data/scales/tissue_entities.dart';
import 'package:cell_mobile/data/scales/organ_entities.dart';
import 'package:cell_mobile/data/scales/organism_entities.dart';
import 'package:cell_mobile/data/scales/ecosystem_entities.dart';
import 'package:cell_mobile/data/scales/farm_system_entities.dart';
import 'package:cell_mobile/data/scales/supply_chain_entities.dart';
import 'package:cell_mobile/data/scales/financial_entities.dart';
import 'package:cell_mobile/data/scales/planets_entities.dart';
import 'package:cell_mobile/data/scales/solar_systems_entities.dart';
import 'package:cell_mobile/data/scales/galactic_entities.dart';
import 'package:cell_mobile/data/scales/organ_system_entities.dart';
import 'package:cell_mobile/data/scales/cosmic_structures_entities.dart';
import 'package:cell_mobile/data/scales/multiverse_all_entities.dart';
import 'package:cell_mobile/data/scales/universe_all_entities.dart';
import 'package:cell_mobile/data/scales/infinities_entities.dart';
import 'package:cell_mobile/data/scales/infinity/calc1_entities.dart';
import 'package:cell_mobile/data/scales/infinity/calc2_entities.dart';
import 'package:cell_mobile/data/scales/infinity/calc3_entities.dart';
import 'package:cell_mobile/data/scales/infinity/linear_algebra_entities.dart';
import 'package:cell_mobile/data/scales/infinity/potato_calculus_entities.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_01_10.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_11_20.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_21_36.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_37_54.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_55_71.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_72_86.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_87_103.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/elements_104_118.dart';
import 'package:cell_mobile/data/scales/atoms_periodic/atoms_potato.dart';
import 'package:cell_mobile/data/scales/particles_sm/sm_fermions.dart';
import 'package:cell_mobile/data/scales/particles_sm/sm_bosons.dart';
import 'package:cell_mobile/data/scales/particles_sm/forces_composite.dart';
import 'package:cell_mobile/data/scales/particles_sm/beyond_sm.dart';
import 'package:cell_mobile/data/scales/particles_sm/particles_potato.dart';
import 'package:cell_mobile/data/scales/cell_modules/cell_types.dart';
import 'package:cell_mobile/data/scales/cell_modules/neurobiology.dart';
import 'package:cell_mobile/data/scales/cell_modules/cell_life.dart';
import 'package:cell_mobile/data/scales/cell_modules/cell_potato.dart';
import 'package:cell_mobile/data/scales/organism_modules/kingdoms.dart';
import 'package:cell_mobile/data/scales/organism_modules/human.dart';
import 'package:cell_mobile/data/scales/organism_modules/potato.dart';
import 'package:cell_mobile/data/scales/tissue_modules/animal.dart';
import 'package:cell_mobile/data/scales/tissue_modules/potato.dart' as tissue_potato;
import 'package:cell_mobile/data/scales/organ_system_modules/human.dart';
import 'package:cell_mobile/data/scales/organ_system_modules/potato.dart' as orgsys_potato;
import 'package:cell_mobile/data/scales/molecular_modules/bonds.dart';
import 'package:cell_mobile/data/scales/molecular_modules/gallery.dart';
import 'package:cell_mobile/data/scales/molecular_modules/potato.dart' as molec_potato;
import 'package:cell_mobile/data/scales/ecosystem_modules/biomes.dart';
import 'package:cell_mobile/data/scales/ecosystem_modules/how.dart';
import 'package:cell_mobile/data/scales/ecosystem_modules/potato.dart' as eco_potato;
import 'package:cell_mobile/data/scales/planets_modules/eight.dart';
import 'package:cell_mobile/data/scales/planets_modules/moons.dart';
import 'package:cell_mobile/data/scales/planets_modules/potato.dart' as planets_potato;
import 'package:cell_mobile/data/scales/solar_modules/anatomy.dart';
import 'package:cell_mobile/data/scales/solar_modules/formation.dart';
import 'package:cell_mobile/data/scales/solar_modules/potato.dart' as solar_potato;
import 'package:cell_mobile/data/scales/galactic_modules/zoo.dart';
import 'package:cell_mobile/data/scales/galactic_modules/how.dart';
import 'package:cell_mobile/data/scales/galactic_modules/potato.dart' as galactic_potato;
import 'package:cell_mobile/data/scales/cosmic_modules/web.dart';
import 'package:cell_mobile/data/scales/cosmic_modules/patterns.dart';
import 'package:cell_mobile/data/scales/cosmic_modules/potato.dart' as cosmic_potato;
import 'package:cell_mobile/data/scales/universe_modules/story.dart';
import 'package:cell_mobile/data/scales/universe_modules/fate.dart';
import 'package:cell_mobile/data/scales/universe_modules/potato.dart' as universe_potato;
import 'package:cell_mobile/data/scales/multiverse_modules/minds.dart';
import 'package:cell_mobile/data/scales/multiverse_modules/science.dart';
import 'package:cell_mobile/data/scales/multiverse_modules/potato.dart' as multiverse_potato;
import 'package:cell_mobile/data/scales/financial_modules/money.dart';
import 'package:cell_mobile/data/scales/financial_modules/economy.dart';
import 'package:cell_mobile/data/scales/financial_modules/potato.dart' as financial_potato;
import 'package:cell_mobile/data/scales/organ_modules/human.dart';
import 'package:cell_mobile/data/scales/organ_modules/potato.dart' as organ_potato;
import 'package:cell_mobile/data/scales/nothings_modules/nature.dart';
import 'package:cell_mobile/data/scales/nothings_modules/potato.dart' as nothings_potato;
import 'package:cell_mobile/data/scales/somethings_modules/rise.dart';
import 'package:cell_mobile/data/scales/somethings_modules/potato.dart' as somethings_potato;
import 'package:cell_mobile/data/scales/supply_chain_modules/full.dart';
import 'package:cell_mobile/data/scales/supply_chain_modules/ops.dart';
import 'package:cell_mobile/data/scales/supply_chain_modules/potato.dart' as sc_potato;
import 'package:cell_mobile/data/scales/farm_system_modules/methods.dart';
import 'package:cell_mobile/data/scales/farm_system_modules/modern.dart';
import 'package:cell_mobile/data/scales/farm_system_modules/potato.dart' as farm_potato;
import 'package:cell_mobile/data/scales/organelle_modules/plant.dart';
import 'package:cell_mobile/data/scales/organelle_modules/potato.dart' as organelle_potato;

class BioEntityRegistry {
  static final BioEntityRegistry _instance = BioEntityRegistry._internal();
  factory BioEntityRegistry() => _instance;

  late final Map<String, BioEntity> _byId;
  late final Map<BioScale, List<BioEntity>> _byScale;
  late final Map<String, List<BioEntity>> _byModule;

  BioEntityRegistry._internal() {
    final allEntities = <BioEntity>[
      ...nothingsEntities,
      ...somethingsEntities,
      ...particlesEntities,
      ...atomsEntities,
      ...molecularEntities,
      ...organelleEntities,
      ...cellEntities,
      ...tissueEntities,
      ...organEntities,
      ...organSystemEntities,
      ...organismEntities,
      ...ecosystemEntities,
      ...farmSystemEntities,
      ...supplyChainEntities,
      ...financialEntities,
      ...planetsEntities,
      ...solarSystemsEntities,
      ...galacticEntities,
      ...cosmicStructuresEntities,
      ...multiverseAllEntities,
      ...universeAllEntities,
      ...infinitiesEntities,
      ...infinityCalc1Entities,
      ...infinityCalc2Entities,
      ...infinityCalc3Entities,
      ...infinityLinearAlgebraEntities,
      ...infinityPotatoEntities,
      ...periodicElements01to10,
      ...periodicElements11to20,
      ...periodicElements21to36,
      ...periodicElements37to54,
      ...periodicElements55to71,
      ...periodicElements72to86,
      ...periodicElements87to103,
      ...periodicElements104to118,
      ...atomsPotatoEntities,
      ...smFermionEntities,
      ...smBosonEntities,
      ...particlesForcesEntities,
      ...particlesBeyondEntities,
      ...particlesPotatoEntities,
      ...cellTypesEntities,
      ...cellNeurobiologyEntities,
      ...cellLifeEntities,
      ...cellPotatoEntities,
      ...organismKingdomsEntities,
      ...organismHumanEntities,
      ...organismPotatoEntities,
      ...tissueAnimalEntities,
      ...tissue_potato.tissuePotatoEntities,
      ...organSystemHumanEntities,
      ...orgsys_potato.organSystemPotatoEntities,
      ...molecularBondsEntities,
      ...molecularGalleryEntities,
      ...molec_potato.molecularPotatoEntities,
      ...ecosystemBiomesEntities,
      ...ecosystemHowEntities,
      ...eco_potato.ecosystemPotatoEntities,
      ...planetsEightEntities,
      ...planetsMoonsEntities,
      ...planets_potato.planetsPotatoEntities,
      ...solarAnatomyEntities,
      ...solarFormationEntities,
      ...solar_potato.solarPotatoEntities,
      ...galacticZooEntities,
      ...galacticHowEntities,
      ...galactic_potato.galacticPotatoEntities,
      ...cosmicWebEntities,
      ...cosmicPatternsEntities,
      ...cosmic_potato.cosmicPotatoEntities,
      ...universeStoryEntities,
      ...universeFateEntities,
      ...universe_potato.universePotatoEntities,
      ...multiverseMindsEntities,
      ...multiverseScienceEntities,
      ...multiverse_potato.multiversePotatoEntities,
      ...financialMoneyEntities,
      ...financialEconomyEntities,
      ...financial_potato.financialPotatoEntities,
      ...organHumanEntities,
      ...organ_potato.organPotatoEntities,
      ...nothingsNatureEntities,
      ...nothings_potato.nothingsPotatoEntities,
      ...somethingsRiseEntities,
      ...somethings_potato.somethingsPotatoEntities,
      ...supplyChainFullEntities,
      ...supplyChainOpsEntities,
      ...sc_potato.supplyChainPotatoEntities,
      ...farmMethodsEntities,
      ...farmModernEntities,
      ...farm_potato.farmPotatoEntities,
      ...organellePlantEntities,
      ...organelle_potato.organellePotatoEntities,
    ];

    _byId = {for (final e in allEntities) e.id: e};
    _byScale = {};
    for (final scale in BioScale.values) {
      _byScale[scale] = allEntities
          .where((e) => e.scale == scale)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    }

    // Group entities by module. An entity's module is its explicit [moduleId],
    // or — for all the pre-module seed content — its scale's Introductory
    // module. This is the migration: no entity file needed editing.
    _byModule = {};
    for (final e in allEntities) {
      final mid = e.moduleId ?? LearnModule.introId(e.scale);
      (_byModule[mid] ??= []).add(e);
    }
    for (final list in _byModule.values) {
      list.sort((a, b) => a.position.compareTo(b.position));
    }
  }

  BioEntity? getById(String id) => _byId[id];

  List<BioEntity> getByScale(BioScale scale) => _byScale[scale] ?? [];

  int entityCount(BioScale scale) => getByScale(scale).length;

  /// The ordered modules for a scale: a synthesized **Introductory** module
  /// first, then the scale's [kExtraModules] (topic modules in listed order),
  /// then the **Potato** module last. Modules with no entities are omitted, so
  /// a scale with only seed content returns just its Introductory module (the
  /// caller can then skip the picker — nothing to choose).
  List<LearnModule> modulesForScale(BioScale scale) {
    final meta = scaleMetaFor(scale);
    final intro = LearnModule(
      id: LearnModule.introId(scale),
      scale: scale,
      title: 'Introduction',
      subtitle: meta.subtitle,
      icon: meta.icon,
      kind: ModuleKind.intro,
    );

    final extras = kExtraModules.where((m) => m.scale == scale).toList();
    // Enforce the spine regardless of author ordering: intro → topics → potato.
    extras.sort((a, b) => _kindRank(a.kind).compareTo(_kindRank(b.kind)));

    return <LearnModule>[intro, ...extras]
        .where((m) => getByModule(m.id).isNotEmpty)
        .toList();
  }

  static int _kindRank(ModuleKind k) => switch (k) {
        ModuleKind.intro => 0,
        ModuleKind.topic => 1,
        ModuleKind.potato => 2,
      };

  /// Entities belonging to a module, in position order.
  List<BioEntity> getByModule(String moduleId) => _byModule[moduleId] ?? [];

  List<BioEntity> getRelated(BioEntity entity) {
    return entity.relatedIds
        .map((id) => _byId[id])
        .whereType<BioEntity>()
        .toList();
  }

  List<BioEntity> getZoomIn(BioEntity entity) {
    return entity.zoomInIds
        .map((id) => _byId[id])
        .whereType<BioEntity>()
        .toList();
  }

  List<BioEntity> getZoomOut(BioEntity entity) {
    return entity.zoomOutIds
        .map((id) => _byId[id])
        .whereType<BioEntity>()
        .toList();
  }
}
