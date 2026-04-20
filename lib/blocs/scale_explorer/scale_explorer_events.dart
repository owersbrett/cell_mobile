import 'package:cell_mobile/models/bio_entity.dart';

abstract class ScaleExplorerEvent {}

class SelectScale extends ScaleExplorerEvent {
  final BioScale scale;
  SelectScale(this.scale);
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
