/// Non-web stub: there's no embedding page to talk to, so no SSO token is
/// available and the caller falls back to anonymous auth. The real handshake
/// (web) lives in `auth_bridge_web.dart`, selected by the conditional import
/// in `firebase_bootstrap.dart`.
Future<String?> requestParentAuthToken() async => null;
