import 'package:cell_mobile/blocs/cell/cell_states.dart';
import 'package:cell_mobile/models/lesson_section.dart';

enum BioScale {
  nothings,
  somethings,
  particles,
  atoms,
  molecular,
  organelle,
  cell,
  tissue,
  organ,
  organSystem,
  organism,
  ecosystem,
  farmSystem,
  supplyChain,
  financial,
  planets,
  solarSystems,
  galactic,
  cosmicStructures,
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

  /// The module this entity belongs to within its scale (see [LearnModule]).
  /// Null ⇒ the scale's Introductory module — this is how all pre-module seed
  /// entities migrate in without touching a single entity file. New breadth /
  /// potato entities carry an explicit module id (e.g. `'atoms_periodic_table'`).
  final String? moduleId;

  /// Structured lesson blocks rendered after [longDescription] — tables,
  /// think-then-reveal questions, landmark facts (see lesson_section.dart).
  /// The 10x-engagement surface: content lives here, not in longer prose.
  final List<LessonSection> sections;

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
    this.moduleId,
    this.sections = const [],
  });
}
