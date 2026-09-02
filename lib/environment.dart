/// Deployment environment for Explore the Cell.
///
/// Four environments — dev · tst · stg · prod — each map to their OWN Firebase
/// project (`hot-potato-games-dev` / `-tst` / `-stg` / `hot-potato-games`).
/// Isolation is at the PROJECT boundary: every env has its own Firestore, RTDB,
/// Auth, and Hosting, so non-prod traffic is physically separate from prod and
/// can never pollute the season "Sessions" KPI or prod account data. There is
/// NO path namespacing — every env uses identical bare collection/RTDB paths;
/// the only thing that changes per env is which project the app connects to
/// (see `firebase_env.dart`, which picks the FirebaseOptions off [current]).
///
/// Resolution is COMPILE-TIME, from `--dart-define=APP_ENV=<dev|tst|stg|prod>`
/// (baked per build, so a deployed bundle can't drift). The default is `prod`
/// so an un-flagged build behaves exactly as production always has. An
/// explicitly-set UNKNOWN value is a build misconfig and is quarantined to
/// `dev` — never silently promoted to prod. A flavored entry point
/// (`main_dev.dart`, …) can also pin it via [AppEnv.override].
enum AppEnvId { dev, tst, stg, prod }

class AppEnv {
  AppEnv._();

  /// Explicit override set by a flavored entry point before bootstrap. Wins
  /// over the dart-define so `flutter run -t lib/main_stg.dart` needs no flag.
  static AppEnvId? _override;

  static const String _raw =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');

  static final AppEnvId _fromDefine = _parse(_raw);

  /// The active environment. Read this everywhere; never branch on the raw
  /// string. Safe to read before [override] as long as Firebase init waits for
  /// bootstrap (which applies any override first thing).
  static AppEnvId get current => _override ?? _fromDefine;

  /// Pin the environment (flavored mobile/desktop entry points). Must run
  /// before Firebase.initializeApp — bootstrap does this first.
  static void override(AppEnvId id) => _override = id;

  static AppEnvId _parse(String raw) {
    switch (raw) {
      case 'dev':
        return AppEnvId.dev;
      case 'tst':
        return AppEnvId.tst;
      case 'stg':
        return AppEnvId.stg;
      case 'prod':
        return AppEnvId.prod;
      default:
        // A typo'd flag (e.g. 'stage') must NOT land on prod. Quarantine to
        // dev so a misconfigured non-prod build stays out of prod data.
        return AppEnvId.dev;
    }
  }

  static String get slug {
    switch (current) {
      case AppEnvId.dev:
        return 'dev';
      case AppEnvId.tst:
        return 'tst';
      case AppEnvId.stg:
        return 'stg';
      case AppEnvId.prod:
        return 'prod';
    }
  }

  static bool get isProd => current == AppEnvId.prod;
}
