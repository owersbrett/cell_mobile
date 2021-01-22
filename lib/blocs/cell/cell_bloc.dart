import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'cell_event.dart';
part 'cell_state.dart';

class CellBloc extends Bloc<CellEvent, CellState> {
  CellBloc() : super(null);

  Organelle _organelleInFocus = Organelle.nucleolous;

  @override
  Stream<CellState> mapEventToState(
    CellEvent event,
  ) async* {
    if (event is DragCellUp) {
      yield* _mapDragUpToState(event);
    } else if (event is DragCellDown) {
      yield* _mapDragDownToState(event);
    }
  }

  Stream<CellState> _mapDragUpToState(DragCellUp event) async* {
    _organelleInFocus = EnumHelper.nextOrganelle(_organelleInFocus);
    yield CellState(organelleInFocus: _organelleInFocus);
  }

  Stream<CellState> _mapDragDownToState(DragCellDown event) async* {
    _organelleInFocus = EnumHelper.previousOrganelle(_organelleInFocus);
    yield CellState(organelleInFocus: _organelleInFocus);
  }
}
