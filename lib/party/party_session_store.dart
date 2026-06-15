/// Debug-only persistence of the in-progress party game, so closing and
/// reopening the app — or a hot restart from the dev loop — lands you right
/// back where you were. Stores the tiny {seed, inputs} replay save (never a raw
/// snapshot) at a path the dev daemon can also read and write.
///
/// `dart:io` is unavailable on web, so the real implementation is selected by
/// conditional import; web (and any non-io target) gets the no-op stub.
export 'party_session_store_stub.dart'
    if (dart.library.io) 'party_session_store_io.dart';
