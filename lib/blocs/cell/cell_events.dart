import 'package:cell_mobile/models/organelle.dart';

abstract class CellEvent {}

class DragCellUp extends CellEvent {}
class DragCellDown extends CellEvent {}
class SetOrganelle extends CellEvent {
  SetOrganelle({required this.organelle});
  final OrganelleInfo organelle;
}