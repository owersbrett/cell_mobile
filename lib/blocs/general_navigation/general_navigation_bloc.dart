// import 'dart:async';

// import 'package:bloc/bloc.dart';
// import 'package:cell_mobile/data/organelles.dart';
// import 'package:cell_mobile/models/organelle.dart';
// import 'package:meta/meta.dart';
// part 'general_navigation_event.dart';
// part 'general_navigation_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'general_navigation.dart';

class GeneralNavigationBloc extends Bloc<GeneralNavigationEvent, GeneralNavigationState> {
  GeneralNavigationBloc() : super(GeneralNavigationState(destination: GeneralNavigationEnum.loading)) {
    on(_onEvent);
  }
  void _onEvent(GeneralNavigationEvent event, Emitter<GeneralNavigationState> emit) {
    if (event is NavigateTo) {
      emit(GeneralNavigationState(destination: event.destination));
    }
  }
}

// class GeneralNavigationBloc extends Bloc<GeneralNavigationEvent, GeneralNavigationState> {
//   GeneralNavigationBloc()
//       : currentIndex = 0,
//         super(GeneralNavigationState(destination: GeneralNavigationEnum.whole_cell)){
//           on<GeneralNavigationEvent>(_mapNavigateToToState())
//         }

//   int currentIndex;
//   OrganelleInfo get organelleInfo => organelles[currentIndex];

//   @override
//   Stream<GeneralNavigationState> mapEventToState(
//     GeneralNavigationEvent event,
//   ) async* {
//     if (event is NavigateTo) {
//       yield* _mapNavigateToToState(event);
//     }
//   }

//   Stream<GeneralNavigationState> _mapNavigateToToState(Emitter<GeneralNavigationState> emit,  event) async* {
//     print('hello there');
//     yield GeneralNavigationState(destination: event.destination);
//   }
// }
