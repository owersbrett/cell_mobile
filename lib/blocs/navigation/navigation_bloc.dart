import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_events.dart';
import 'navigation_states.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc()
      : super(const NavigationState(screen: AppScreen.home)) {
    on<NavigateToScreen>((event, emit) {
      emit(NavigationState(screen: event.screen));
    });
  }
}
