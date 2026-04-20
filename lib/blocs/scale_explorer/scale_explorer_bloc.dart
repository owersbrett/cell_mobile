import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'scale_explorer_events.dart';
import 'scale_explorer_states.dart';

class ScaleExplorerBloc extends Bloc<ScaleExplorerEvent, ScaleExplorerState> {
  final BioEntityRegistry _registry = BioEntityRegistry();

  ScaleExplorerBloc()
      : super(const ScaleExplorerState(
          currentScale: BioScale.molecular,
          currentPosition: 0,
        )) {
    on<SelectScale>(_onSelectScale);
    on<NavigateLateral>(_onNavigateLateral);
    on<ZoomIn>(_onZoomIn);
    on<ZoomOut>(_onZoomOut);
    on<JumpToEntity>(_onJumpToEntity);
  }

  void _onSelectScale(SelectScale event, Emitter<ScaleExplorerState> emit) {
    final entities = _registry.getByScale(event.scale);
    emit(ScaleExplorerState(
      currentScale: event.scale,
      currentPosition: 0,
      currentEntity: entities.isNotEmpty ? entities[0] : null,
      currentScaleEntities: entities,
    ));
  }

  void _onNavigateLateral(
      NavigateLateral event, Emitter<ScaleExplorerState> emit) {
    final entities = state.currentScaleEntities.isNotEmpty
        ? state.currentScaleEntities
        : _registry.getByScale(state.currentScale);
    final newPos = state.currentPosition + event.delta;
    if (newPos >= 0 && newPos < entities.length) {
      emit(state.copyWith(
        currentPosition: newPos,
        currentEntity: entities[newPos],
        currentScaleEntities: entities,
      ));
    }
  }

  void _onZoomIn(ZoomIn event, Emitter<ScaleExplorerState> emit) {
    final target = _registry.getById(event.targetEntityId);
    if (target != null) {
      final entities = _registry.getByScale(target.scale);
      emit(ScaleExplorerState(
        currentScale: target.scale,
        currentPosition: target.position,
        currentEntity: target,
        currentScaleEntities: entities,
      ));
    }
  }

  void _onZoomOut(ZoomOut event, Emitter<ScaleExplorerState> emit) {
    final target = _registry.getById(event.targetEntityId);
    if (target != null) {
      final entities = _registry.getByScale(target.scale);
      emit(ScaleExplorerState(
        currentScale: target.scale,
        currentPosition: target.position,
        currentEntity: target,
        currentScaleEntities: entities,
      ));
    }
  }

  void _onJumpToEntity(JumpToEntity event, Emitter<ScaleExplorerState> emit) {
    final target = _registry.getById(event.entityId);
    if (target != null) {
      final entities = _registry.getByScale(target.scale);
      emit(ScaleExplorerState(
        currentScale: target.scale,
        currentPosition: target.position,
        currentEntity: target,
        currentScaleEntities: entities,
      ));
    }
  }
}
