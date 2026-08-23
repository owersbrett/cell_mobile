/// Deploy heartbeat — bumped on every deploy by the `/deploy` skill and shown
/// on the home (splash) screen so a live deploy can be confirmed at a glance.
///
/// This is intentionally separate from the pubspec `version:` — it exists purely
/// to prove "the bits I just pushed are the bits now live." The skill increments
/// [kBuildNumber]; nothing else should edit it by hand.
const int kBuildNumber = 67;

/// Label rendered on the splash screen, e.g. "build 6".
const String kBuildLabel = 'build $kBuildNumber';
