import 'package:cell_mobile/models/bio_entity.dart';

abstract class ScaleExplorerEvent {}

class SelectScale extends ScaleExplorerEvent {
  final BioScale scale;
  SelectScale(this.scale);
}

/// Scope the explorer to a single module's entities (Scale → Module → Entity).
/// [scale] is carried so the state knows both dimensions.
class SelectModule extends ScaleExplorerEvent {
  final BioScale scale;
  final String moduleId;
  SelectModule(this.scale, this.moduleId);
}

class NavigateLateral extends ScaleExplorerEvent {
  final int delta; // +1 or -1
  NavigateLateral(this.delta);
}

class ZoomIn extends ScaleExplorerEvent {
  final String targetEntityId;
  ZoomIn(this.targetEntityId);
}

class ZoomOut extends ScaleExplorerEvent {
  final String targetEntityId;
  ZoomOut(this.targetEntityId);
}

class JumpToEntity extends ScaleExplorerEvent {
  final String entityId;
  JumpToEntity(this.entityId);
}
