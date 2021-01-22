part of 'cell_bloc.dart';

@immutable
abstract class CellEvent {}

class DragCellUp extends CellEvent {}
class DragCellDown extends CellEvent {}