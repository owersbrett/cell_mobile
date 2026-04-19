import 'package:cell_mobile/blocs/cell/cell_states.dart';

enum BioScale {
  nothings,
  questions,
  particles,
  atoms,
  molecular,
  organelle,
  cell,
  tissue,
  organ,
  organism,
  ecosystem,
  farmSystem,
  supplyChain,
  financial,
  global,
  planets,
  solarSystems,
  galactic,
  clusters,
  cosmicStructures,
  bigQuestions,
  universe,
  multiverse,
  multiverseAll,
  universeAll,
  infinities,
}

class BioEntity {
  final String id;
  final BioScale scale;
  final int position;
  final String name;
  final String title;
  final String? iconCodePoint;
  final String? imagePath;
  final String shortDescription;
  final String longDescription;
  final List<String> zoomInIds;
  final List<String> zoomOutIds;
  final List<String> relatedIds;
  final Organelle? organelleEnum;

  const BioEntity({
    required this.id,
    required this.scale,
    required this.position,
    required this.name,
    required this.title,
    this.iconCodePoint,
    this.imagePath,
    required this.shortDescription,
    required this.longDescription,
    this.zoomInIds = const [],
    this.zoomOutIds = const [],
    this.relatedIds = const [],
    this.organelleEnum,
  });
}
