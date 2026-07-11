import 'package:cell_mobile/models/bio_entity.dart';

class ScaleExplorerState {
  final BioScale currentScale;
  final int currentPosition;
  final BioEntity? currentEntity;
  final List<BioEntity> currentScaleEntities;

  /// The module currently being explored, if scoped to one. Null = the whole
  /// scale (legacy zoom-in/out navigation that lands on a bare scale).
  final String? currentModuleId;

  const ScaleExplorerState({
    required this.currentScale,
    required this.currentPosition,
    this.currentEntity,
    this.currentScaleEntities = const [],
    this.currentModuleId,
  });

  ScaleExplorerState copyWith({
    BioScale? currentScale,
    int? currentPosition,
    BioEntity? currentEntity,
    List<BioEntity>? currentScaleEntities,
    String? currentModuleId,
  }) {
    return ScaleExplorerState(
      currentScale: currentScale ?? this.currentScale,
      currentPosition: currentPosition ?? this.currentPosition,
      currentEntity: currentEntity ?? this.currentEntity,
      currentScaleEntities: currentScaleEntities ?? this.currentScaleEntities,
      currentModuleId: currentModuleId ?? this.currentModuleId,
    );
  }
}
