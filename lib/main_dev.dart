import 'environment.dart';
import 'main_common.dart';

/// Flavored entry: `flutter run -t lib/main_dev.dart` (no dart-define needed).
Future<void> main() => bootstrap(env: AppEnvId.dev);
