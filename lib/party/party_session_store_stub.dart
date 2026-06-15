import 'party_controller.dart';

/// No-op session store for targets without `dart:io` (e.g. web). The dev-loop
/// save/resume feature only runs on debug desktop builds; everywhere else these
/// calls do nothing.
class PartySessionStore {
  PartySessionStore._();

  static bool get enabled => false;
  static bool get autoResume => false;
  static void save(PartyController controller) {}
  static PartyController? load() => null;
  static void clear() {}
}
