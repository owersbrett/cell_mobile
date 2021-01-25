import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/models/organelle.dart';
import 'package:meta/meta.dart';
part 'general_navigation_event.dart';
part 'general_navigation_state.dart';

class GeneralNavigationBloc extends Bloc<GeneralNavigationEvent, GeneralNavigationState> {
  GeneralNavigationBloc() : super(null);


  int currentIndex;
  OrganelleInfo get organelleInfo => organelles[currentIndex];

  @override
  Stream<GeneralNavigationState> mapEventToState(
    GeneralNavigationEvent event,
  ) async* {
    if (event is NavigateTo) {
      yield* _mapNavigateToToState(event);
    } 
  }

  Stream<GeneralNavigationState> _mapNavigateToToState(NavigateTo event) async* {
    print('hello there');
    yield GeneralNavigationState(destination: event.destination);
  }

 

}
