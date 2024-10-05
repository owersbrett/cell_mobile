
abstract class GeneralNavigationEvent {}

class NavigateTo extends GeneralNavigationEvent {
  NavigateTo({required this.destination});
  final GeneralNavigationEnum destination;
}

enum GeneralNavigationEnum {
  whole_cell,
  organelle_info
}