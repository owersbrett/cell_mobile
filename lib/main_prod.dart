import 'environment.dart';
import 'main_common.dart';

/// Flavored entry: `flutter run -t lib/main_prod.dart`.
Future<void> main() => bootstrap(env: AppEnvId.prod);
