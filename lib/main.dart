import 'main_common.dart';

/// Default entry point (the web deploy target). The environment comes from
/// `--dart-define=APP_ENV=<dev|tst|stg|prod>` (default prod). All launch logic
/// lives in `bootstrap()` so every entry point behaves identically.
Future<void> main() => bootstrap();
