import 'package:cell_mobile/data/organelles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cell.dart';

class CellBloc extends Bloc<CellEvent, CellState> {
  CellBloc() : super(CellState(organelleInfo: organelles[0])) {
    on(_onEvent);
  }
  void _onEvent(CellEvent event, Emitter<CellState> emit)  {
    if (event is DragCellUp)  _dragCellUp(event, emit);
    if (event is DragCellDown)  _dragCellDown(event, emit);
  }

  void _dragCellUp(DragCellUp event, Emitter<CellState> emit) async {
    var currentOrganelle = state.organelleInfo;
    if (currentOrganelle.position < organelles.length - 1) {
      currentOrganelle = organelles[(currentOrganelle.position + 1)];
    }
    emit(CellState(organelleInfo: currentOrganelle));
  }

  void _dragCellDown(DragCellDown event, Emitter<CellState> emit) async {
    var currentOrganelle = state.organelleInfo;
    if (currentOrganelle.position > 0) {
      currentOrganelle = organelles[(currentOrganelle.position - 1)];
    }
    emit(CellState(organelleInfo: currentOrganelle));
  }
}

// class CellBloc extends Bloc<CellEvent, CellState> {
//   CellBloc({required this.currentIndex}) : super(CellState(organelleInfo: organelles[0]));


//   int currentIndex;
//   OrganelleInfo get organelleInfo => organelles[currentIndex];

//   @override
//   Stream<CellState> mapEventToState(
//     CellEvent event,
//   ) async* {
//     if (event is DragCellUp) {
//       yield* _mapDragUpToState(event);
//     } else if (event is DragCellDown) {
//       yield* _mapDragDownToState(event);
//     }
//   }

//   Stream<CellState> _mapDragUpToState(DragCellUp event) async* {
//     // print('cell dragged up');
//     // print('currentIndex $currentIndex');
//     if (currentIndex < organelles.length - 1) currentIndex++;
    
//     yield CellState(organelleInfo: organelleInfo);
//   }

//   Stream<CellState> _mapDragDownToState(DragCellDown event) async* {
//     // print('cell dragged down');
//     // print('currentIndex $currentIndex');
//     if (currentIndex > 0) currentIndex--;

//     yield CellState(organelleInfo: organelleInfo);
//   }

//   // @override
//   // void onTransition(Transition<CellEvent, CellState> transition) {
//   //   print("current organelle: ${transition.currentState.organelleInfo}");
//   //   print("current organelle: ${transition.event.runtimeType}");
//   //   print("current organelle: ${transition.nextState.organelleInfo}");
//   //   super.onTransition(transition);
//   // }
// }
