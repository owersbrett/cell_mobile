import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'environment.dart';
import 'firebase_options.dart';

/// Per-environment Firebase project selection.
///
/// Each env connects to its OWN Firebase project — isolation is at the project
/// boundary, not via path namespacing (see [AppEnv]). PROD uses the
/// FlutterFire-generated multi-platform options (`DefaultFirebaseOptions`); the
/// three lower envs use their project's WEB app config, since web is Explore the
/// Cell's deploy target. A non-prod MOBILE build reuses the same (web) config —
/// core Firestore/RTDB/Auth are project-scoped and work with any valid appId in
/// the project; register dedicated mobile apps if non-prod mobile ever ships.
///
/// Configs pulled 2026-08-30 via `firebase apps:sdkconfig WEB --project …`;
/// databaseURL from the RTDB default instances created the same day.
FirebaseOptions firebaseOptionsForCurrentEnv() {
  switch (AppEnv.current) {
    case AppEnvId.prod:
      return DefaultFirebaseOptions.currentPlatform;
    case AppEnvId.dev:
      return _dev;
    case AppEnvId.tst:
      return _tst;
    case AppEnvId.stg:
      return _stg;
  }
}

const FirebaseOptions _dev = FirebaseOptions(
  apiKey: 'AIzaSyCICyyC4RT18WpumzVQGJJOqY4vZkMxwVM',
  appId: '1:26311172046:web:99d14bfd63cc369127959f',
  messagingSenderId: '26311172046',
  projectId: 'hot-potato-games-dev',
  authDomain: 'hot-potato-games-dev.firebaseapp.com',
  databaseURL: 'https://hot-potato-games-dev-default-rtdb.firebaseio.com',
  storageBucket: 'hot-potato-games-dev.firebasestorage.app',
  measurementId: 'G-ZH8S0LCJQT',
);

const FirebaseOptions _tst = FirebaseOptions(
  apiKey: 'AIzaSyCy0gBxxblxwQKIEmzjALUo2zRplFCRlc4',
  appId: '1:8476364422:web:2b6edb36061d039b7f4b07',
  messagingSenderId: '8476364422',
  projectId: 'hot-potato-games-tst',
  authDomain: 'hot-potato-games-tst.firebaseapp.com',
  databaseURL: 'https://hot-potato-games-tst-default-rtdb.firebaseio.com',
  storageBucket: 'hot-potato-games-tst.firebasestorage.app',
  measurementId: 'G-0DHN87V9SR',
);

const FirebaseOptions _stg = FirebaseOptions(
  apiKey: 'AIzaSyBjdSAwVSB1I8i5lfkhQKoYkoRL9lcO11Q',
  appId: '1:635563313112:web:154e1a3f212c17ca9194ad',
  messagingSenderId: '635563313112',
  projectId: 'hot-potato-games-stg',
  authDomain: 'hot-potato-games-stg.firebaseapp.com',
  databaseURL: 'https://hot-potato-games-stg-default-rtdb.firebaseio.com',
  storageBucket: 'hot-potato-games-stg.firebasestorage.app',
  measurementId: 'G-S2BEQRBK53',
);
