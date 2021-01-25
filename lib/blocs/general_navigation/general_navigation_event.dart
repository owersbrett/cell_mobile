part of 'general_navigation_bloc.dart';

@immutable
abstract class GeneralNavigationEvent {}

class NavigateTo extends GeneralNavigationEvent {
  NavigateTo({this.destination});
  final GeneralNavigationEnum destination;
}

enum GeneralNavigationEnum {
  whole_cell,
  organelle_info
}