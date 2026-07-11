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
    on<SelectModule>(_onSelectModule);
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

  /// Scope the explorer to one module's entities. Used by the module picker;
  /// the explorer then pages within just that module.
  void _onSelectModule(SelectModule event, Emitter<ScaleExplorerState> emit) {
    final entities = _registry.getByModule(event.moduleId);
    emit(ScaleExplorerState(
      currentScale: event.scale,
      currentPosition: 0,
      currentEntity: entities.isNotEmpty ? entities.first : null,
      currentScaleEntities: entities,
      currentModuleId: event.moduleId,
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
    _emitAtEntity(event.targetEntityId, emit);
  }

  void _onZoomOut(ZoomOut event, Emitter<ScaleExplorerState> emit) {
    _emitAtEntity(event.targetEntityId, emit);
  }

  void _onJumpToEntity(JumpToEntity event, Emitter<ScaleExplorerState> emit) {
    _emitAtEntity(event.entityId, emit);
  }

  /// Land on [entityId]. `currentPosition` is ALWAYS the index into the
  /// displayed entity list — never the entity's `position` metadata field,
  /// which is a scale-wide ordering key and diverges from list indices
  /// (especially inside a module-scoped list). If the target lives in the
  /// currently displayed list, stay in it (preserving module scope);
  /// otherwise fall back to the target's full scale list.
  void _emitAtEntity(String entityId, Emitter<ScaleExplorerState> emit) {
    final target = _registry.getById(entityId);
    if (target == null) return;
    final inCurrent =
        state.currentScaleEntities.indexWhere((e) => e.id == target.id);
    if (inCurrent >= 0) {
      emit(state.copyWith(
        currentPosition: inCurrent,
        currentEntity: target,
      ));
      return;
    }
    final entities = _registry.getByScale(target.scale);
    final index = entities.indexWhere((e) => e.id == target.id);
    emit(ScaleExplorerState(
      currentScale: target.scale,
      currentPosition: index >= 0 ? index : 0,
      currentEntity: target,
      currentScaleEntities: entities,
    ));
  }
}
