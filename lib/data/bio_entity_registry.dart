import 'package:cell_mobile/models/bio_entity.dart';
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

class BioEntityRegistry {
  static final BioEntityRegistry _instance = BioEntityRegistry._internal();
  factory BioEntityRegistry() => _instance;

  late final Map<String, BioEntity> _byId;
  late final Map<BioScale, List<BioEntity>> _byScale;

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
    ];

    _byId = {for (final e in allEntities) e.id: e};
    _byScale = {};
    for (final scale in BioScale.values) {
      _byScale[scale] = allEntities
          .where((e) => e.scale == scale)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    }
  }

  BioEntity? getById(String id) => _byId[id];

  List<BioEntity> getByScale(BioScale scale) => _byScale[scale] ?? [];

  int entityCount(BioScale scale) => getByScale(scale).length;

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
