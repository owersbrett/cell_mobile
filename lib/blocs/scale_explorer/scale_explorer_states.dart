import 'package:cell_mobile/models/bio_entity.dart';

class ScaleExplorerState {
  final BioScale currentScale;
  final int currentPosition;
  final BioEntity? currentEntity;
  final List<BioEntity> currentScaleEntities;

  const ScaleExplorerState({
    required this.currentScale,
    required this.currentPosition,
    this.currentEntity,
    this.currentScaleEntities = const [],
  });

  ScaleExplorerState copyWith({
    BioScale? currentScale,
    int? currentPosition,
    BioEntity? currentEntity,
    List<BioEntity>? currentScaleEntities,
  }) {
    return ScaleExplorerState(
      currentScale: currentScale ?? this.currentScale,
      currentPosition: currentPosition ?? this.currentPosition,
      currentEntity: currentEntity ?? this.currentEntity,
      currentScaleEntities: currentScaleEntities ?? this.currentScaleEntities,
    );
  }
}
