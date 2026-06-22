/// Non-web stub: no embedding page to talk to, so this is a no-op.
/// The real implementation (web) lives in `parent_post_web.dart` and is
/// selected by the conditional import in `cell_telemetry.dart`.
void postPlayToParent({required String kind, String? gameId}) {}
